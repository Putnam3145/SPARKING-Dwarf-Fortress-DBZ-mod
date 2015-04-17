local function unitCanUseKi(unit)
    for _,class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if class.value == 'NATURAL_KI' then return true end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for _,synclass in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            if synclass.value == "KI" then return true end
        end
    end
    return false
end


function calculate_max_ki(unit)
    local strength = unit.body.physical_attrs.STRENGTH.value/1000
    local endurance = unit.body.physical_attrs.ENDURANCE.value/1000
    local toughness = unit.body.physical_attrs.TOUGHNESS.value/1000
    local spatialsense = unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1000
    local kinestheticsense = unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
    local willpower = unit.status.current_soul.mental_attrs.WILLPOWER.value/1000
    local focus = unit.status.current_soul.mental_attrs.FOCUS.value/1000
    return math.floor(((strength+endurance+agility+toughness+spatialsense+kinestheticsense+willpower+focus)*(1000/7))+.5) -- Because hard work should matter as much as natural ability, eh?
end

function init_ki(unit)
    if not unitCanUseKi() then
        return false
    end
    local unitKi=dfhack.persistent.save({key='DBZ_KI_'..unit.id})
    if unitKi.ints[2]>0 then
        return unitKi.ints[2]
    end
    local maxKi=calculate_max_ki(unit)
    unitKi.ints[2]=maxKi
    unitKi.ints[1]=maxKi
    unitKi:save()
    return unitKi.ints[2]
end

function get_unit_ki_persist(unit)
    if not init_ki(unit) then
        local notActuallyAKiTable={ints={0,0}}
        notActuallyAKiTable.save=function(self)
            return false
        end
        return notActuallyAKiTable
    end
    return dfhack.persistent.save({key='DBZ_KI_'..unit.id})
end

function get_ki(unit)
    if not init_ki(unit) then
        return 0
    end
    return dfhack.persistent.get({key='DBZ_KI'..unit.id}).ints[1]
end

function adjust_max_ki(unit,amount)
    local unitKi=get_unit_ki_persist(unit)
    unitKi.ints[2]=unitKi.ints[2]+amount
    unitKi:save()
    return unitKi.ints[2]
end

function adjust_ki(unit,amount,force)
    local unitKi=get_unit_ki_persist(unit)
    if unitKi.ints[1]+amount<0 then
        if not force then
            return false
        else
            local castFromHitpoints=unitKi.ints[1]+amount
            unit.body.blood_count=unit.body.blood_count-castFromHitpoints
            unit.counters2.exhaustion=unit.counters2.exhaustion+castFromHitpoints
            unit.counters.pain=unit.counters.pain+castFromHitpoints
            unitKi.ints[1]=0
            unitKi:save()
            return 0
        end
    else
        unitKi.ints[1]=math.min(unitKi.ints[1]+amount,unitKi.ints[2])
        unitKi:save()
        return unitKi.ints[1]
    end
end