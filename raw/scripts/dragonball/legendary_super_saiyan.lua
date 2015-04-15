local utils=require('utils')

local function round(n)
    return math.floor(n+.5)
end

validArgs = validArgs or utils.invert({
 'unit'
})

local args = utils.processArgs({...}, validArgs)

local unit = df.unit.find(args.unit)

unit.body.physical_attrs.STRENGTH.value=round(unit.body.physical_attrs.STRENGTH.value*1.01)
unit.body.physical_attrs.AGILITY.value=round(unit.body.physical_attrs.AGILITY.value*1.01)
unit.body.physical_attrs.ENDURANCE.value=round(unit.body.physical_attrs.ENDURANCE.value*1.01)
unit.body.physical_attrs.TOUGHNESS.value=round(unit.body.physical_attrs.TOUGHNESS.value*1.01)
unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value=round(unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value*1.01)
unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value=round(unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value*1.01)
unit.status.current_soul.mental_attrs.WILLPOWER.value=round(unit.status.current_soul.mental_attrs.WILLPOWER.value*1.01)