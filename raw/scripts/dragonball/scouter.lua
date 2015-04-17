-- Gives power level of selected unit. Type "accurate" for a more linear, but more boring number.

local utils=require('utils')

validArgs = utils.invert({
 'accurate',
 'all',
 'citizens'
})

local args = utils.processArgs({...}, validArgs)

local function unitIsGod(unit)
    local unitraws = df.creature_raw.find(unit.race)
    local casteraws = unitraws.caste[unit.caste]
    local unitclasses = casteraws.creature_class
    for _,class in ipairs(unitclasses) do
        if class.value == "GOD" then return true end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for _,synclass in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            if synclass.value == "GOD" then return true end
        end
    end
    return false
end

--power levels should account for disabilities and such
local function isWinded(unit)
    return unit.counters.winded > 0
end
local function isStunned(unit)
    return unit.counters.stunned > 0
end
local function isUnconscious(unit)
    return unit.counters.unconscious > 0
end
local function isParalyzed(unit)
    return unit.counters2.paralysis > 0
end
local function getExhaustion(unit)
    local exhaustion = 1
    if unit.counters2.exhaustion~=0 then
        exhaustion = 1000/unit.counters2.exhaustion
        return exhaustion
    end
    return 1
end

--blood_max appears to be the creature's body size divided by 10; the power level calculation relies on body size divided by 1000, so divided by 100 it is. blood_count refers to current blood amount, and it, when full, is equal to blood_max.

local function getPowerLevel(saiyan,accurate)
	if accurate then
        local strength = saiyan.body.physical_attrs.STRENGTH.value/1000
        local agility = saiyan.body.physical_attrs.AGILITY.value/1000
        local endurance = saiyan.body.physical_attrs.ENDURANCE.value/1000
        local toughness = saiyan.body.physical_attrs.TOUGHNESS.value/1000
        local spatialsense = saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1000
        local kinestheticsense = saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
        local willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value/1000
        return (strength+agility+endurance+toughness+spatialsense+kinestheticsense+willpower)/13.85
	else
		local strength,endurance,toughness,spatialsense,kinestheticsense,willpower
		if saiyan.curse.attr_change then
			strength = ((saiyan.body.physical_attrs.STRENGTH.value+saiyan.curse.attr_change.phys_att_add.STRENGTH)/3550)*(saiyan.curse.attr_change.phys_att_perc.STRENGTH/100)
			endurance = ((saiyan.body.physical_attrs.ENDURANCE.value+saiyan.curse.attr_change.phys_att_add.ENDURANCE)/1000)*(saiyan.curse.attr_change.phys_att_perc.ENDURANCE/100)
			toughness = ((saiyan.body.physical_attrs.TOUGHNESS.value+saiyan.curse.attr_change.phys_att_add.TOUGHNESS)/2250)*(saiyan.curse.attr_change.phys_att_perc.TOUGHNESS/100)
			spatialsense = ((saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value+saiyan.curse.attr_change.ment_att_add.SPATIAL_SENSE)/1500)*(saiyan.curse.attr_change.ment_att_perc.SPATIAL_SENSE/100)
			kinestheticsense = ((saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+saiyan.curse.attr_change.ment_att_add.KINESTHETIC_SENSE)/1000)*(saiyan.curse.attr_change.ment_att_perc.KINESTHETIC_SENSE/100)
			willpower = ((saiyan.status.current_soul.mental_attrs.WILLPOWER.value+saiyan.curse.attr_change.ment_att_add.WILLPOWER)/1000)*(saiyan.curse.attr_change.ment_att_perc.WILLPOWER/100)
		else
			strength = saiyan.body.physical_attrs.STRENGTH.value/3550
			endurance = saiyan.body.physical_attrs.ENDURANCE.value/1000
			toughness = saiyan.body.physical_attrs.TOUGHNESS.value/2250
			spatialsense = saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1500
			kinestheticsense = saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
			willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value/1000
		end
		local exhaustion = getExhaustion(saiyan)
		local bodysize = (saiyan.body.blood_count/100)^2
		powerlevel = bodysize*((strength*endurance*toughness*spatialsense*kinestheticsense*willpower)^(1/6))*exhaustion
		if isWinded(saiyan) then powerlevel=powerlevel/1.2 end
		if isStunned(saiyan) then powerlevel=powerlevel/1.5 end
		if isParalyzed(saiyan) then powerlevel=powerlevel/5 end
		if isUnconscious(saiyan) then powerlevel=powerlevel/10 end
		if powerlevel == 1/0 or unitIsGod(saiyan) then
			dfhack.gui.showPopupAnnouncement("The scouter broke at this incredible power. Either the power belongs to a god... or it's immeasurable.",1)
			qerror("Scouter broke! Oh well, there are more.",11)
		end
		return math.floor(powerlevel)
	end
end

if args.all then
	for k,v in ipairs(df.global.world.units.active) do
		print(dfhack.TranslateName(dfhack.units.getVisibleName(v))..' has a power level of '..getPowerLevel(v,args.accurate))
	end
elseif args.citizens then
	for k,v in ipairs(df.global.world.units.active) do
		if dfhack.units.isCitizen(v) then
			print(dfhack.TranslateName(dfhack.units.getVisibleName(v))..' has a power level of '..getPowerLevel(v,args.accurate))
		end
	end
else
	dfhack.gui.showPopupAnnouncement("The scouter says " .. getPowerLevel(dfhack.gui.getSelectedUnit(silent),args.accurate) .. "!",11)
end