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

local function calculate_max_ki_portions(unit)
    if not unit.status.current_soul then return 0,0,0 end
    local willpower = unit.status.current_soul.mental_attrs.WILLPOWER.value
    local focus = unit.status.current_soul.mental_attrs.FOCUS.value
    local endurance = unit.body.physical_attrs.ENDURANCE.value
    local multiplier,boost=get_ki_boost(unit)
    return boost*multiplier,willpower*multiplier,focus*multiplier,endurance*multiplier
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
    local yukiPerc=1
    for k,v in ipairs(unit.status.current_soul.personality.emotions) do
        local emotion_type=df.emotion_type[v.type]
        if isPositiveWillpowerEmotion[emotion_type] then
            yukiPerc=yukiPerc*(v.strength/(10*tonumber(df.emotion_type.attrs[v.type].divider)))
        else
            yukiPerc=yukiPerc/(v.strength/(10*tonumber(df.emotion_type.attrs[v.type].divider)))
        end
    end
    return math.min(1,math.max(0,yukiPerc))
end

local function averageTo1(number)
    return (1+number)/2
end

function adjustKiType(unit_id,amount)
    local ki_level_persist=dfhack.persistent.get('KI_LEVEL/'..unit.id)
    ki_level_persist.ints[1]=ki_level_persist.ints[1]+amount
    ki_level_persist:save()
    return ki_level_persist.ints[1]
end

function getKiType(unit,totalKi)
    local m=math --local variables are much faster than global variables and there's a lot of math here
    local kiType=m.min(4,m.max(0,m.floor(m.log(totalKi/375000)/m.log(40))))
    if kiType==4 then
        kiType=m.floor(totalKi/24000000000)+2
    end
    return kiType
end

function get_ki_investment(unit_id)
    if not unitCanUseKi(unit_id) then return 0,0 end
    local unit = df.unit.find(unit_id)
    local boost,yuki,shoki,genki=calculate_max_ki_portions(unit)
    local genkiPerc=math.min(1,(unit.body.blood_count/unit.body.blood_max)*averageTo1(dfhack.units.getEffectiveSkill(unit,df.job_skill.MELEE_COMBAT)/5))
    local yukiPerc=math.min(1,getYukiPerc(unit)*averageTo1(dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)/5))
    local shokiPerc=math.min(1,30/math.sqrt(math.max(unit.status.current_soul.personality.stress_level,1))*averageTo1(dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)/5))
    local boostPerc
    do
        local totalKi=yuki+shoki+genki
        local genkiFraction,yukiFraction,shokiFraction=genki/totalKi,yuki/totalKi,shoki/totalKi
        boostPerc=(genkiPerc*genkiFraction)+(yukiPerc*yukiFraction)+(shokiPerc*shokiFraction)
    end
    local totalKi=math.floor(boost*boostPerc+genki*genkiPerc+yuki*yukiPerc+shoki*shokiPerc+.5)
    return totalKi,getKiType(unit,totalKi)
end

function get_max_ki(unit_id)
    if not unitCanUseKi(unit_id) then return 0 end
    local unit=df.unit.find(unit_id)
    if not unit.status.current_soul then return 0 end
    local willpower = unit.status.current_soul.mental_attrs.WILLPOWER.value
    local focus = unit.status.current_soul.mental_attrs.FOCUS.value
    local endurance = unit.body.physical_attrs.ENDURANCE.value
    local multiplier,boost=get_ki_boost(unit)
    return (willpower+focus+endurance+boost)*multiplier
end