local function unitCanUseKi(unit_id)
    local unit = df.unit.find(unit_id)
    if not unit then return false end
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


function calculate_max_ki(unit_id)
    local unit = df.unit.find(unit_id)
    local strength = unit.body.physical_attrs.STRENGTH.value/1000
    local agility = unit.body.physical_attrs.AGILITY.value/1000
    local endurance = unit.body.physical_attrs.ENDURANCE.value/1000
    local toughness = unit.body.physical_attrs.TOUGHNESS.value/1000
    local spatialsense = unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1000
    local kinestheticsense = unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
    local willpower = unit.status.current_soul.mental_attrs.WILLPOWER.value/1000
    local focus = unit.status.current_soul.mental_attrs.FOCUS.value/1000
    return math.floor(((strength+endurance+agility+toughness+spatialsense+kinestheticsense+willpower+focus)*(1000/7))+.5) -- Because hard work should matter as much as natural ability, eh?
end

function init_ki(unit_id)
    if not unitCanUseKi(unit_id) then
        return false
    end
    local unitKi=dfhack.persistent.save({key='DBZ_KI/'..unit_id})
    if unitKi.ints[2]>0 then
        return unitKi.ints[2]
    end
    local maxKi=calculate_max_ki(unit_id)
    unitKi.ints[2]=maxKi
    unitKi.ints[1]=maxKi
    unitKi.ints[3]=100
    unitKi:save()
    return unitKi.ints[2]
end

function get_unit_ki_persist_entry(unit_id)
    if not init_ki(unit_id) then
        local notActuallyAKiTable={ints={0,0,1}}
        notActuallyAKiTable.save=function(self)
            return false
        end
        return notActuallyAKiTable
    end
    return dfhack.persistent.save({key='DBZ_KI/'..unit_id})
end

function get_ki_investment(unit_id)
    local unitKi = get_unit_ki_persist_entry(unit_id)
    return math.min(math.ceil(unitKi.ints[2]/unitKi.ints[3]),unitKi.ints[1])
end

function set_ki_investment(unit_id,fraction)
    local unitKi = get_unit_ki_persist_entry(unit_id)
    unitKi.ints[3]=fraction
    unitKi:save()
    return unitKi.ints[3]
end

function get_ki(unit_id)
    if not init_ki(unit_id) then
        return 0
    end
    return get_unit_ki_persist_entry(unit_id).ints[1]
end

function get_max_ki(unit_id)
    if not init_ki(unit_id) then
        return 0
    end
    return get_unit_ki_persist_entry(unit_id).ints[2]
end

function adjust_max_ki(unit_id,amount,set)
    local unitKi=get_unit_ki_persist_entry(unit_id)
    if set then
        unitKi.ints[2]=amount
    else
        unitKi.ints[2]=unitKi.ints[2]+amount
    end
    unitKi:save()
    return unitKi.ints[2]
end

function adjust_ki(unit_id,amount,force)
    local unitKi=get_unit_ki_persist_entry(unit_id)
    local unit=df.unit.find(unit_id)
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