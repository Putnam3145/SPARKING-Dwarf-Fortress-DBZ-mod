local utils=require('utils')

local function round(n)
    return math.floor(n+.5)
end

validArgs = validArgs or utils.invert({
 'unit'
})

local args = utils.processArgs({...}, validArgs)

local unit = df.unit.find(args.unit)

unit.body.physical_attrs.STRENGTH.value=math.min(round(unit.body.physical_attrs.STRENGTH.value*1.01),200000)
unit.body.physical_attrs.AGILITY.value=math.min(round(unit.body.physical_attrs.AGILITY.value*1.01),2000000000)
unit.body.physical_attrs.ENDURANCE.value=math.min(round(unit.body.physical_attrs.ENDURANCE.value*1.01),2000000000)
unit.body.physical_attrs.TOUGHNESS.value=math.min(round(unit.body.physical_attrs.TOUGHNESS.value*1.01).2000000000)
unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value=math.min(round(unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value*1.01),2000000000)
unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value=math.min(round(unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value*1.01),2000000000)
unit.status.current_soul.mental_attrs.WILLPOWER.value=math.min(round(unit.status.current_soul.mental_attrs.WILLPOWER.value*1.01),2000000000)
unit.status.current_soul.mental_attrs.FOCUS.value=math.min(round(unit.status.current_soul.mental_attrs.FOCUS.value*1.01),2000000000)