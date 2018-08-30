local unit

local ki=dfhack.script_environment('dragonball/ki')

local transformation=dfhack.script_environment('dragonball/transformation')

for k,v in ipairs(df.global.world.units.active) do
    if df.creature_raw.find(v.race).creature_id=='SAIYAN' then unit=v end
end

while ki.get_max_ki(unit.id)<1000000000 do
    unit.status.current_soul.mental_attrs.WILLPOWER.value=unit.status.current_soul.mental_attrs.WILLPOWER.value+10
    unit.body.physical_attrs.TOUGHNESS.value=unit.body.physical_attrs.TOUGHNESS.value+10
    unit.status.current_soul.mental_attrs.PATIENCE.value=unit.status.current_soul.mental_attrs.PATIENCE.value+10
    unit.status.current_soul.mental_attrs.FOCUS.value=unit.status.current_soul.mental_attrs.FOCUS.value+10
    unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value=unit.status.current_soul.mental_attrs.SPATIAL_SENSE.value+10
    unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value=unit.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+10
    unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value=unit.status.current_soul.mental_attrs.ANALYTICAL_ABILITY.value+10
    unit.status.current_soul.mental_attrs.MEMORY.value=unit.status.current_soul.mental_attrs.MEMORY.value+10
    unit.body.physical_attrs.ENDURANCE.value=unit.body.physical_attrs.ENDURANCE.value+10
    unit.body.physical_attrs.AGILITY.value=unit.body.physical_attrs.AGILITY.value+10
    unit.body.physical_attrs.STRENGTH.value=unit.body.physical_attrs.STRENGTH.value+10
end

transformation.transformations={}

transformation.load_transformation_file('dragonball/transformations/super_saiyan')
transformation.load_transformation_file('dragonball/transformations/other')

for k,transformation_table in pairs(transformation.transformations) do
    local name=transformation_table.identifier
    print('testing '..name)
    transformation.add_transformation(unit.id,name)
    for k,v in pairs(transformation_table) do
        if type(v)=='function' then
            print('testing function '..name..'.'..k)
            v(unit,unit,{attack_velocity=100,attack_accuracy=100})
        else
            print(k..' was not function, not tested, value is '..tostring(v))
        end
    end
    print('test succeded, no issues')
end