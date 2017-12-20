--Transformations are lists within the "transformations" list.

--Not all transformation properties have to be defined, but I will do so for "Super Saiyan" as an example.    

local transformation_funcs=dfhack.script_environment('dragonball/transformation')

transformations={}

function get_S_cells(unit)
    return dfhack.persistent.save('DRAGONBALL/S_CELLS/'..unit.id)
end

transformations['Super Saiyan']={}

transformations['Super Saiyan'].ki_mult=function(unit)
    return math.min(50+0.01*get_S_cells(unit).ints[1],100)
end

transformations['Super Saiyan'].ki_boost=function(unit)
    return 0
end

transformations['Super Saiyan'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counts2.exhaustion=unit.counters2.exhaustion+(100000/unit.body.physical_attrs.ENDURANCE)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+1+math.floor(unit.counters2.exhaustion/1000)
    persist:save()
end

transformations['Super Saiyan'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 10000/unit.body.physical_attrs.ENDURANCE
end

transformations['Super Saiyan'].benefit=function(unit) --how much benefit the transformation has, for use in AI
    return transformations['Super Saiyan'].ki_mult(unit)
end

--units will use the transformation with the least cost unless they're up against bad odds; base form is assumed to have 1 cost, 1 benefit

transformations['Super Saiyan'].can_add=function(unit)
    return true
end

-- transformations['Super Saiyan'].overlaps={} --transformations that can overlap with this one, will replace otherwise, expects

transformations['Super Saiyan 2']={}

transformations['Super Saiyan 2'].ki_mult=function(unit)
    return transformations['Super Saiyan'].ki_mult(unit)*2
end

transformations['Super Saiyan 2'].on_tick=function(unit)
    unit.counts2.exhaustion=unit.counters2.exhaustion+(250000/unit.body.physical_attrs.ENDURANCE)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+2+math.floor(unit.counters2.exhaustion/500)
    persist:save()
end

transformations['Super Saiyan 2'].cost=function(unit)
    return transformations['Super Saiyan'].cost*2.5
end

transformations['Super Saiyan 2'].benefit=function(unit)
    return transformations['Super Saiyan'].benefit*2
end

transformations['Super Saiyan 2'].can_add=function(unit)
    local S_cells=get_S_cells(unit).ints[1]
    return S_cells>10000
end

transformations['Super Saiyan 3']={}

transformations['Super Saiyan 3'].ki_mult=function(unit)
    return transformations['Super Saiyan'].ki_mult(unit)*8
end

transformations['Super Saiyan 3'].on_tick=function(unit)
    unit.counts2.exhaustion=unit.counters2.exhaustion+(1500000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Super Saiyan 3'].cost=function(unit)
    return transformations['Super Saiyan'].cost*15
end

transformations['Super Saiyan 3'].benefit=function(unit)
    return transformations['Super Saiyan'].benefit*8
end

transformations['Super Saiyan 3'].can_add=function(unit)
    local S_cells=get_S_cells(unit).ints[1]
    return S_cells>20000
end

transformations['Super Saiyan God']={}

transformations['Super Saiyan God'].ki_type='God'

transformations['Super Saiyan God'].on_tick=function(unit)
    unit.counts2.exhaustion=unit.counters2.exhaustion+(50000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Super Saiyan God'].cost=function(unit)
    return 5000/unit.body.physical_attrs.ENDURANCE
end

transformations['Super Saiyan God'].benefit=function(unit)
    return 1000
end

transformations['Super Saiyan Blue']={}

transformations['Super Saiyan Blue'].ki_mult=function(unit)
    return transformations['Super Saiyan'].ki_mult(unit)
end

transformations['Super Saiyan Blue'].ki_type='God'

transformations['Super Saiyan Blue'].on_tick=function(unit)
    unit.counts2.exhaustion=unit.counters2.exhaustion+(500000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Super Saiyan Blue'].cost=function(unit)
    return transformations['Super Saiyan'].cost*5
end

transformations['Super Saiyan Blue'].benefit=function(unit)
    return transformations['Super Saiyan'].benefit*1000
end

transformations['Super Saiyan Blue'].can_add=function(unit)
    return (get_transformation(unit.id,'Super Saiyan God') and get_S_cells(unit).ints[1]>10000) or get_S_cells(unit).ints[3]==1
end

transformations['Super Saiyan Blue'].overlaps={
    'Kaioken'
}