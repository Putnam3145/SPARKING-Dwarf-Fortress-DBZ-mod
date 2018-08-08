-- Gives power level of selected unit. Use "-ignoreGod" to get godly ki levels and "-legacy" for pre-ki calculation.

local utils=require('utils')

validArgs = utils.invert({
 'legacy',
 'all',
 'citizens',
 'ignoreGod',
 'potential'
})

local args = utils.processArgs({...}, validArgs)

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

function getPowerLevel(saiyan,legacy,ignoreGod,potential)
    if not saiyan then return 'nothing' end
    if legacy then
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
		if powerlevel == 1/0 then
			return 'undefined'
		end
		return math.floor(powerlevel)
    else
        local powerLevel,kiLevel=potential and dfhack.script_environment('dragonball/ki').get_max_ki(saiyan.id) or dfhack.script_environment('dragonball/ki').get_ki_investment(saiyan.id)
        if not kiLevel then
            local _=nil
            _,kiLevel=dfhack.script_environment('dragonball/ki').get_ki_investment(saiyan.id)
        end
        if kiLevel>1 then 
            if ignoreGod then
                local kiLevelStr=kiLevel==1 and 'demigod' or kiLevel==2 and 'god' or kiLevel==3 and 'one infinity core' or kiLevel<11 and tostring(kiLevel-2)..' infinity cores' or "the culmination"
                return powerLevel..' ('..kiLevelStr..' ki)',powerLevel
            else
                return '(undetectable--a god?!)',1
            end
        else
            return powerLevel
        end
    end
end

if args.all then
    local unitList={}
	for k,v in ipairs(df.global.world.units.active) do
        local powerlevel,powerNum=getPowerLevel(v,args.legacy,args.ignoreGod,args.potential)
        if powerNum and powerNum>0 or powerlevel>0 then
            table.insert(unitList,{power=powerlevel,str=dfhack.TranslateName(dfhack.units.getVisibleName(v))..' has a power '..(args.potential and 'potential' or 'level') .. ' of '..powerlevel})
        end
	end
    table.sort(unitList,function(a,b) return a.power>b.power end)
    for k,v in ipairs(unitList) do
        print(v.str)
    end
elseif args.citizens then
    local unitList={}
	for k,v in ipairs(df.global.world.units.active) do
        local powerlevel,powerNum=getPowerLevel(v,args.legacy,args.ignoreGod,args.potential)
        if dfhack.units.isCitizen(v) then
            table.insert(unitList,{power=powerlevel,str=dfhack.TranslateName(dfhack.units.getVisibleName(v))..' has a power '..(args.potential and 'potential' or 'level') .. ' of '..powerlevel})
        end
	end
    table.sort(unitList,function(a,b) return a.power>b.power end)
    for k,v in ipairs(unitList) do
        print(v.str)
    end
else
    local unit=dfhack.gui.getSelectedUnit(true)
    if unit then
        dfhack.gui.showPopupAnnouncement("The scouter says " .. getPowerLevel(dfhack.gui.getSelectedUnit(true),args.legacy,args.ignoreGod,args.potential) .. "!",11)
    end
end
