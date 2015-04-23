
local args={...}

local unit = df.unit.find(args[1])

if df.creature_raw.find(unit.race).creature_id~="CELL" then dfhack.error("Creature absorbing isn't Cell! Report this error with the stack trace!",nil,true) end

unit.body.physical_attrs.STRENGTH.value=round(unit.body.physical_attrs.STRENGTH.value*+100)
unit.body.physical_attrs.AGILITY.value=round(unit.body.physical_attrs.AGILITY.value+100)
unit.body.physical_attrs.ENDURANCE.value=round(unit.body.physical_attrs.ENDURANCE.value+100)
unit.body.physical_attrs.TOUGHNESS.value=round(unit.body.physical_attrs.TOUGHNESS.value+100)
unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value=round(unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+100)
unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value=round(unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+100)
unit.status.current_soul.mental_attrs.WILLPOWER.value=round(unit.status.current_soul.mental_attrs.WILLPOWER.value+100)
unit.status.current_soul.mental_attrs.FOCUS.value=round(unit.status.current_soul.mental_attrs.FOCUS.value+100)