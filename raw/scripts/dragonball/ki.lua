local function unitCanUseKi(unit_id)
    local unit = df.unit.find(unit_id)
    return unit and df.creature_raw.find(unit.race).caste[unit.caste].flags.CAN_LEARN
end

local transformation=dfhack.script_environment('dragonball/transformation')

ki_attrs={
    willpower={
        coefficient=1/3,
        phys={'TOUGHNESS'},
        ment={'WILLPOWER','PATIENCE'}
    },
    focus={
        coefficient=1/5,
        phys={},
        ment={'FOCUS','SPATIAL_SENSE','KINESTHETIC_SENSE','ANALYTICAL_ABILITY','MEMORY'}
    },
    health={
        coefficient=1/3,
        phys={'ENDURANCE','AGILITY','STRENGTH'},
        ment={}
    }
}

local function get_species_boosts(unit)
    local multiplier,boost,potential_boost=1,0,0
    for _,class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if class.value:find('KI_MULTIPLIER_') then
            multiplier=multiplier*(tonumber(class.value:sub(15)) or 1)
        elseif class.value:find('KI_BOOST_') then
            boost=boost+(tonumber(class.value:sub(10)) or 0)
        elseif class.value:find('KI_POTENTIAL_BOOST_') then
            potential_boost=potential_boost+((tonumber(class.value:sub(20)) or 0))
        end
    end
    return boost,multiplier,potential_boost
end

function calculate_max_ki_portions(unit)
    local willpower = (unit.status.current_soul.mental_attrs.WILLPOWER.value+unit.body.physical_attrs.TOUGHNESS.value+unit.status.current_soul.mental_attrs.PATIENCE.value)/3
    local focus = (unit.status.current_soul.mental_attrs.FOCUS.value+unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value+unit.status.current_soul.mental_attrs.MEMORY.value)/5
    local endurance = (unit.body.physical_attrs.ENDURANCE.value+unit.body.physical_attrs.AGILITY.value+unit.body.physical_attrs.STRENGTH.value)/3
    local boost,multiplier,potential_boost=transformation.get_transformation_boosts(unit.id)
    local spec_boost,spec_multiplier,spec_potential=get_species_boosts(unit)
    return boost+spec_boost,willpower,focus,endurance,multiplier*spec_multiplier,potential_boost+spec_potential
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
        return tonumber(getSubClassValue(unit,'KI_TYPE')) or transformation.get_ki_type(unit.id) or 0
    end
end

function ki_func(num,unit)
    --[[
        linear makes it grow faster before 12187, makes the minimum much lower than the 2250 it originally was. This also mimicks the growth shown before the namek arc.
        below and equal to 51882, it grows exponentially, mimicking the growth shown during the namek arc.
        above 51882, it's quadratic, which is rather slow but not slow enough to be unsatisfying.
    ]]
    if unit and df.global.gamemode==df.game_mode.ADVENTURE and unit==df.global.world.units.active[0] then
        if num<6093 then
            return num*2
        elseif num>46904 then
            return (2^(num/2500))*2250
        else
            return ((num^2)/2.2)-23478
        end
    else
        if num<12187 then
            return num
        elseif num>51882 then
            return (num^2)/900
        else
            return (2^(num/5000))*2250
        end
    end
end

function get_max_ki_pre_boost(unit_id)
    if not unitCanUseKi(unit_id) then return 0 end
    local unit=df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier=calculate_max_ki_portions(unit)
    return math.floor(ki_func(yuki+shoki+genki,unit)+0.5)
end

function get_true_base_ki(unit_id)
    if not unitCanUseKi(unit_id) then return 0 end
    local unit=df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier=calculate_max_ki_portions(unit)
    return math.floor(yuki+shoki+genki+0.5)
end

local function get_health_value(unit)
    return (unit.body.blood_count/unit.body.blood_max)*(((-1/6000)*unit.counters2.exhaustion)+1)
end

function get_ki_investment(unit_id)
    if not unitCanUseKi(unit_id) then return 0,0 end
    local unit = df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier,potential_boost=calculate_max_ki_portions(unit)
    local genkiPerc=math.min(1,(get_health_value(unit)*(dfhack.units.getEffectiveSkill(unit,df.job_skill.MELEE_COMBAT)+1)/5)/2)
    local yukiPerc=math.min(1,(getYukiPerc(unit)*(dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)+1)/5)/2)
    local shokiPerc=math.min(1,(getShokiPerc(unit)*(dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)+1)/5)/2)
    local boostPerc
    do
        local totalKi=yuki+shoki+genki
        local genkiFraction,yukiFraction,shokiFraction=genki/totalKi,yuki/totalKi,shoki/totalKi
        boostPerc=(genkiPerc*genkiFraction)+(yukiPerc*yukiFraction)+(shokiPerc*shokiFraction)
    end
    local totalKi=boost*boostPerc+ki_func(genki*genkiPerc+yuki*yukiPerc+shoki*shokiPerc+potential_boost*boostPerc,unit)
    return math.floor(totalKi*multiplier+.5),getKiType(unit,math.floor(totalKi*multiplier+.5))
end

function get_max_ki(unit_id)
    if not unitCanUseKi(unit_id) then return 0 end
    local unit=df.unit.find(unit_id)
    local boost,yuki,shoki,genki,multiplier,potential_boost=calculate_max_ki_portions(unit)
    return math.floor(((ki_func(yuki+shoki+genki+potential_boost,unit)+boost)*multiplier)+0.5)
end
