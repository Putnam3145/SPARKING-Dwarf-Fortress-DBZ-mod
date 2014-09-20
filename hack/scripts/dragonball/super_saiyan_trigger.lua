local utils=require('utils')
local function getPowerLevel(saiyan)
	local strength = saiyan.body.physical_attrs.STRENGTH.value/3550
	local endurance = saiyan.body.physical_attrs.ENDURANCE.value/1000
	local toughness = saiyan.body.physical_attrs.TOUGHNESS.value/2250
	local spatialsense = saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1500
	local kinestheticsense = saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
	local willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value/1000
	return (strength+endurance+toughness+spatialsense+kinestheticsense+willpower)
end

validArgs = validArgs or utils.invert({
 'unit'
})

local args = utils.processArgs({...}, validArgs)

local powerLevel=getPowerLevel(df.unit.find(args.unit))

if powerLevel>100 then
	dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 3','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
elseif powerLevel>50 then
	dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 2','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
elseif powerLevel>20 then
	dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
end