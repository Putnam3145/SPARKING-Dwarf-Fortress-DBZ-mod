local function unitCanUseKi(unit_id)
    local unit = df.unit.find(unit_id)
    return unit and creature_classes=df.creature_raw.find(unit.race).caste[unit.caste].flags.CAN_LEARN
end

local transformation=dfhack.script_environment('dragonball/transformation')

function calculate_max_ki_portions(unit)
    local willpower = (unit.status.current_soul.mental_attrs.WILLPOWER.value+unit.body.physical_attrs.TOUGHNESS.value+unit.status.current_soul.mental_attrs.PATIENCE.value)/3
    local focus = (unit.status.current_soul.mental_attrs.FOCUS.value+unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value+unit.status.current_soul.mental_attrs.MEMORY.value)/5
    local endurance = (unit.body.physical_attrs.ENDURANCE.value+unit.body.physical_attrs.AGILITY.value+unit.body.physical_attrs.STRENGTH.value)/3
    local boost,multiplier=transformation.get_transformation_boosts(unit.id)
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
    if num>51882 then --this is the second intersection point of the two functions
        return (num^2)/900
    else
        return (2^(num/5000))*2250
    end
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
    return math.floor((((ki_func(yuki+shoki+genki))+boost)*multiplier)+0.5)
end
