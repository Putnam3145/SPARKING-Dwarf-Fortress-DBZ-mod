local function unitCanUseKi(unit_id)
    local unit = df.unit.find(unit_id)
    if not unit then return false end
    local creature_classes=df.creature_raw.find(unit.race).caste[unit.caste].creature_class
    for _,class in ipairs(creature_classes) do
        if class.value=='NATURAL_KI' then return true end
    end
    local active_syndromes=unit.syndromes.active
    for _,c_syndrome in ipairs(active_syndromes) do
        local syndrome_classes=df.syndrome.find(c_syndrome.type).syn_class
        for _,synclass in ipairs(syndrome_classes) do
            if synclass.value == "KI" then return true end
        end
    end
    return false
end

function adjust_ki_mult_persist(unit_id,persist_key,amount,linear)
    if not persist_key then return false end
    local persist=dfhack.persistent.save({key='DBZ_KI/'..persist_key..'/'..unit_id})
    persist:save()
    persist.ints[1]=persist.ints[1]<0 and (linear and amount+1 or amount)  or (linear and persist.ints[1]+amount or persist.ints[1]*amount)
    persist:save()
    return persist.ints[1]
end

function adjust_ki_boost_persist(unit_id,persist_key,amount)
    if not persist_key then return false end
    local persist=dfhack.persistent.save({key='DBZ_KI/'..persist_key..'/'..unit_id})
    persist:save()
    persist.ints[2]=persist.ints[2]<0 and amount or persist.ints[2]+amount
    persist:save()
    return persist.ints[2]
end

function get_ki_mult_persist(unit_id,persist_key)
    if not persist_key then return 1 end
    local persist=dfhack.persistent.get('DBZ_KI/'..persist_key..'/'..unit_id)
    if persist then return persist.ints[1] else return 1 end
end

function get_ki_boost_persist(unit_id,persist_key)
    if not persist_key then return 0 end
    local persist=dfhack.persistent.get('DBZ_KI/'..persist_key..'/'..unit_id)
    if persist then return persist.ints[2] else return 0 end
end

local function get_ki_boost(unit)
    local multiplier,boost=1,0
    local unit_id=unit.id
    for _,class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if class.value:find('KI_MULTIPLIER_') then 
            multiplier=multiplier*(tonumber(class.value:sub(15)) or get_ki_mult_persist(unit_id,class.value:sub(15)) or 1)
        elseif class.value:find('KI_BOOST_') then
            boost=boost+(tonumber(class.value:sub(10)) or get_ki_boost_persist(synclass.value:sub(10)) or 0)
        end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for __,synclass in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            if synclass.value:find('KI_MULTIPLIER_') then 
                multiplier=multiplier*(tonumber(synclass.value:sub(15)) or get_ki_mult_persist(unit_id,synclass.value:sub(15)) or 1)
            elseif synclass.value:find('KI_BOOST_') then
                boost=boost+(tonumber(synclass.value:sub(10)) or get_ki_boost_persist(synclass.value:sub(10)) or 0)
            end
        end
    end
    multiplier=multiplier*get_ki_mult_persist(unit_id,'BASE')
    boost=boost+get_ki_boost_persist(unit_id,'BASE')
    return multiplier,boost
end

function calculate_max_ki_portions(unit)
    local willpower = (unit.status.current_soul.mental_attrs.WILLPOWER.value+unit.body.physical_attrs.TOUGHNESS.value+unit.status.current_soul.mental_attrs.PATIENCE.value)/3
    local focus = (unit.status.current_soul.mental_attrs.FOCUS.value+unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value+unit.status.current_soul.mental_attrs.MEMORY.value)/5
    local endurance = (unit.body.physical_attrs.ENDURANCE.value+unit.body.physical_attrs.AGILITY.value+unit.body.physical_attrs.STRENGTH.value)/3
    local multiplier,boost=get_ki_boost(unit)
    return boost,willpower,focus,endurance,multiplier
end

local isPositiveWillpowerEmotion={
    Rage=true,
    Wrath=true,
    Anger=true,
    Ferocity=true,
    Bitterness=true,
    Hatred=true,
    Loathing=true,
    Outrage=true,
}

local function getYukiPerc(unit)
    local m=math
    local stressLevel=unit.status.current_soul.personality.stress_level
    for k,v in ipairs(unit.status.current_soul.personality.emotions) do
        local emotion_type=df.emotion_type[v.type]
        if isPositiveWillpowerEmotion[emotion_type] then
            local multiplicand=tonumber(df.emotion_type.attrs[v.type].divider)
            if multiplicand~=0 then multiplicand=1/m.abs(multiplicand) end
            local stress_addition=v.strength*-multiplicand
            stressLevel=stressLevel-stress_addition
        end
    end
    return stressLevel>0 and m.min(1,8/(m.log(stressLevel)/m.log(2))) or 1
end

local function getShokiPerc(unit)
    local distractednessTotal=unit.status.current_soul.personality.current_focus
    return distractednessTotal>0 and math.min(1,8/(math.log(distractednessTotal)/math.log(2))) or 1 --i think the same equation ought to work for both...
end

local function averageTo1(number)
    return (1+number)/2
end

local function getSubClassValue(unit,class)
    for _,c_class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        local class_value=c_class.value
        if class_value:find('/') then
            if class_value:sub(0,class_value:find('/')-1) == class then return class_value:sub(1+class_value:find('/.*')) end
        end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for __,s_class in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            local class_value=s_class.value
            if class_value:find('/') then
                if class_value:sub(0,class_value:find('/')-1) == class then return class_value:sub(1+class_value:find('/.*')) end
            end
        end
    end
    return false
end

function getWorldKiMode()
    local world_ki_persist=dfhack.persistent.save({key='DBZ_WORLD_KI_MODE'})
    if world_ki_persist.value=='' then world_ki_persist.value='super' world_ki_persist:save() end
    return world_ki_persist.value
end

function setWorldKiMode(mode)
    return dfhack.persistent.save({key='DBZ_WORLD_KI_MODE',value=mode}).value
end

function getKiType(unit,totalKi)
    if getWorldKiMode()=='bttl' then
        local m=math --local variables are much faster than global variables and there's a lot of math here
        local kiType=m.min(4,m.max(0,m.log(totalKi/10875000)/m.log(40)))
        if kiType==4 then
            kiType=m.floor(totalKi/6960000000000)+2
            if kiType>10 then
                return 12
            end
        end
        if kiType<1.6 then return 0 else return math.floor(kiType) end
    else
        return tonumber(getSubClassValue(unit,'KI_TYPE')) or 0
    end
end

function ki_func(num)
    return (2^(num/5000))*2250
end

function get_max_ki_pre_boost(unit_id)
    if not unitCanUseKi(unit_id) then return 0 end
    local unit=df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier=calculate_max_ki_portions(unit)
    return math.floor(ki_func(yuki+shoki+genki)+0.5)
end

function get_ki_investment(unit_id)
    if not unitCanUseKi(unit_id) then return 0,0 end
    local unit = df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier=calculate_max_ki_portions(unit)
    local genkiPerc=math.min(1,((unit.body.blood_count/unit.body.blood_max)*dfhack.units.getEffectiveSkill(unit,df.job_skill.MELEE_COMBAT)/5)/2)
    local yukiPerc=math.min(1,(getYukiPerc(unit)*dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)/5)/2)
    local shokiPerc=math.min(1,(getShokiPerc(unit)*dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)/5)/2)
    local boostPerc
    do
        local totalKi=yuki+shoki+genki
        local genkiFraction,yukiFraction,shokiFraction=genki/totalKi,yuki/totalKi,shoki/totalKi
        boostPerc=(genkiPerc*genkiFraction)+(yukiPerc*yukiFraction)+(shokiPerc*shokiFraction)
    end
    local totalKi=boost*boostPerc+ki_func(genki*genkiPerc+yuki*yukiPerc+shoki*shokiPerc)
    return math.floor(totalKi*multiplier+.5),getKiType(unit,math.floor(totalKi*multiplier+.5))
end

function get_max_ki(unit_id)
    if not unitCanUseKi(unit_id) then return 0 end
    local unit=df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier=calculate_max_ki_portions(unit)
    return math.floor((((ki_func(yuki+shoki+genki)*2250)+boost)*multiplier)+0.5)
end
