--Transformations are lists within the "transformations" list.

--Not all transformation properties have to be defined, but I will do so for "Super Saiyan" as an example.    

local transformation_funcs=dfhack.script_environment('dragonball/transformation')

transformations={}

function get_S_cells(unit)
    local persist=dfhack.persistent.save('DRAGONBALL/S_CELLS/'..unit.id)
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is S-cells
    --ints[2] is experience with Super Saiyan 2
    --ints[3] is super saiyan anger event
    --ints[4] is trained by angel
    return persist:save()
end

transformations['Super Saiyan']={}

transformations['Super Saiyan'].ki_mult=function(unit)
    return 50
end

transformations['Super Saiyan'].ki_boost=function(unit)
    return math.min(10000000,2^(get_S_cells(unit).ints[1]/500))
end

transformations['Super Saiyan'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    local persist=get_S_cells(unit)
    unit.counts2.exhaustion=unit.counters2.exhaustion+math.floor((100000/unit.body.physical_attrs.ENDURANCE)/math.min(100,math.max(1,persist.ints[1]/100))+0.5)
    persist.ints[1]=persist.ints[1]+1+math.floor(unit.counters2.exhaustion/1000)
    persist:save()
end

transformations['Super Saiyan'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 10000/unit.body.physical_attrs.ENDURANCE
end

transformations['Super Saiyan'].benefit=function(unit) --how much benefit the transformation has, for use in AI
    return 50
end

transformations['Super Saiyan'].get_name=function(unit)
    local persist=get_S_cells(unit)
    return persist.ints[1]<10000 and 'Super Saiyan' or 'Super Saiyan Full Power'
end

--units will use the transformation with the least cost unless they're up against bad odds; base form is assumed to have 1 cost, 1 benefit

transformations['Super Saiyan'].can_add=function(unit)
    return true
end

-- transformations['Super Saiyan'].overlaps={} --transformations that can overlap with this one, will replace otherwise

transformations['Berserker Super Saiyan']={}

transformations['Berserker Super Saiyan'].ki_mult=function(unit)
    return 50
end

transformations['Berserker Super Saiyan'].ki_boost=function(unit)
    return transformation_funcs.get_transformation(unit.id,'Berserker Super Saiyan').ints[2]*20
end

transformations['Berserker Super Saiyan'].on_tick=function(unit)
    local persist=transformation_funcs.get_transformation(unit.id,'Berserker Super Saiyan')
    unit.counts2.exhaustion=unit.counters2.exhaustion-10
    persist.ints[2]=persist.ints[2]+1
    persist:save()
end

transformations['Berserker Super Saiyan'].on_transform=function(unit)
    local persist=transformation_funcs.get_transformation(unit.id,'Berserker Super Saiyan')
    persist.ints[2]=0
    persist:save()
end

transformations['Berserker Super Saiyan'].cost=function(unit)
    return 1
end

transformations['Berserker Super Saiyan'].benefit=function(unit)
    return 50
end

transformations['Berserker Super Saiyan'].on_attacked=function(attacker,defender,attack)
    local persist=transformation_funcs.get_transformation(unit.id,'Berserker Super Saiyan')
    persist.ints[2]=persist.ints[2]+attack.attack_velocity
    persist.ints[2]:save()
end

transformations['Berserker Super Saiyan'].get_name=function(unit)
    return 'Berserker Super Saiyan'
end

--units will use the transformation with the least cost unless they're up against bad odds; base form is assumed to have 1 cost, 1 benefit

transformations['Berserker Super Saiyan'].can_add=function(unit)
    return true
end

transformations['Super Saiyan 2']={}

transformations['Super Saiyan 2'].ki_mult=function(unit)
    return transformations['Super Saiyan'].ki_mult(unit)*math.min(8,2+0.004*get_S_cells(unit).ints[2])
end

transformations['Super Saiyan 2'].ki_boost=transformations['Super Saiyan'].ki_boost

transformations['Super Saiyan 2'].on_tick=function(unit)
    unit.counts2.exhaustion=unit.counters2.exhaustion+(250000/unit.body.physical_attrs.ENDURANCE)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+2+math.floor(unit.counters2.exhaustion/500)
    persist.ints[2]=persist.ints[2]+1+math.floor(unit.counters2.exhaustion/1000) --literally just super saiyan 2 progress for strengthened and anger forms
    persist:save()
end

transformations['Super Saiyan 2'].cost=function(unit)
    return transformations['Super Saiyan'].cost*2.5
end

transformations['Super Saiyan 2'].benefit=transformations['Super Saiyan 2'].ki_mult

transformations['Super Saiyan 2'].can_add=function(unit)
    local S_cells=get_S_cells(unit).ints[1]
    return S_cells>10000
end

transformations['Super Saiyan 2'].ki_type=function(unit) 
    local S_cells=get_S_cells(unit)
    return (S_cells.ints[2]>10000 and S_cells.ints[3]==1) and 'God'
end

transformations['Super Saiyan 2'].get_name=function(unit)
    local S_cells=get_S_cells(unit)
    if S_cells.ints[2]>10000 then
        if S_cells.ints[3]==1 then
            return 'Strengthened Super Saiyan 2'
        else
            return 'Super Saiyan Anger'
        end
    else
        return 'Super Saiyan 2'
    end
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

transformations['Super Saiyan God'].ki_type=function(unit) 
    return 'God' 
end

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

transformations['Super Saiyan Blue'].ki_type=function(unit) 
    return 'God' 
end

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
    return (get_transformation(unit.id,'Super Saiyan God') and get_S_cells(unit).ints[1]>10000) or get_S_cells(unit).ints[4]==1
end

transformations['Super Saiyan Blue'].overlaps={
    'Kaioken'
}