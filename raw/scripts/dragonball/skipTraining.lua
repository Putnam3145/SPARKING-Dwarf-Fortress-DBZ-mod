local unit=dfhack.gui.getSelectedUnit()

local ki=dfhack.script_environment('dragonball/ki')

while ki.get_max_ki(unit.id)<3000000 do
    unit.status.current_soul.mental_attrs.WILLPOWER.value=unit.status.current_soul.mental_attrs.WILLPOWER.value+2
    unit.body.physical_attrs.TOUGHNESS.value=unit.body.physical_attrs.TOUGHNESS.value+2
    unit.status.current_soul.mental_attrs.PATIENCE.value=unit.status.current_soul.mental_attrs.PATIENCE.value+2
    unit.status.current_soul.mental_attrs.FOCUS.value=unit.status.current_soul.mental_attrs.FOCUS.value+2
    unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value=unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+2
    unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value=unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+2
    unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value=unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value+2
    unit.status.current_soul.mental_attrs.MEMORY.value=unit.status.current_soul.mental_attrs.MEMORY.value+2
    unit.body.physical_attrs.ENDURANCE.value=unit.body.physical_attrs.ENDURANCE.value+2
    unit.body.physical_attrs.AGILITY.value=unit.body.physical_attrs.AGILITY.value+2
    unit.body.physical_attrs.STRENGTH.value=unit.body.physical_attrs.STRENGTH.value+2
end