function calculate_max_ki(unit)
    local strength,endurance,toughness,spatialsense,kinestheticsense,willpower,agility
	if unit.curse.attr_change then
		strength = ((unit.body.physical_attrs.STRENGTH.value+unit.curse.attr_change.phys_att_add.STRENGTH))*(unit.curse.attr_change.phys_att_perc.STRENGTH/100)
		endurance = ((unit.body.physical_attrs.ENDURANCE.value+unit.curse.attr_change.phys_att_add.ENDURANCE))*(unit.curse.attr_change.phys_att_perc.ENDURANCE/100)
		toughness = ((unit.body.physical_attrs.TOUGHNESS.value+unit.curse.attr_change.phys_att_add.TOUGHNESS))*(unit.curse.attr_change.phys_att_perc.TOUGHNESS/100)
		spatialsense = ((unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+unit.curse.attr_change.ment_att_add.SPATIAL_SENSE))*(unit.curse.attr_change.ment_att_perc.SPATIAL_SENSE/100)
		kinestheticsense = ((unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+unit.curse.attr_change.ment_att_add.KINESTHETIC_SENSE))*(unit.curse.attr_change.ment_att_perc.KINESTHETIC_SENSE/100)
		willpower = ((unit.status.current_soul.mental_attrs.WILLPOWER.value+unit.curse.attr_change.ment_att_add.WILLPOWER))*(unit.curse.attr_change.ment_att_perc.WILLPOWER/100)
        agility = (unit.body.physical_attrs.AGILITY.value+unit.curse.attr_change.phys_att_add.AGILITY)*(unit.curse.attr_change.phys_att_perc.AGILITY/100)
	else
		strength = unit.body.physical_attrs.STRENGTH.value
		endurance = unit.body.physical_attrs.ENDURANCE.value
		toughness = unit.body.physical_attrs.TOUGHNESS.value
        agility = unit.body.physical_attrs.AGILITY.value
		spatialsense = unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value
		kinestheticsense = unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value
		willpower = unit.status.current_soul.mental_attrs.WILLPOWER.value
	end
	local bodysize = unit.body.blood_count
	return math.floor(bodysize+strength+endurance+agility+toughness+spatialsense+kinestheticsense+willpower) -- Because hard work should matter as much as natural ability, eh?
end

function init_ki(unit)
    local unitKi=dfhack.persistent.save({key='DBZ_KI_'..unit.id})
    local maxKi=calculate_max_ki(unit)
    unitKi.ints[2]=maxKi
    unitKi.ints[1]=maxKi
    unitKi:save()
end

function get_ki(unit)
    return dfhack.persistent.get({key='DBZ_KI'..unit.id}).ints[1]
end

function adjust_max_ki(unit,amount)
    local unitKi=dfhack.persistent.save({key='DBZ_KI_'..unit.id})
    unitKi.ints[2]=unitKi.ints[2]+amount
    unitKi:save()
    return unitKi.ints[2]
end

function adjust_ki(unit,amount,force)
    local unitKi=dfhack.persistent.save({key='DBZ_KI_'..unit.id})
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