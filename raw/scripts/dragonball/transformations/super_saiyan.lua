--Transformations are lists within the "transformations" list.

--Not all transformation properties have to be defined, but I will do so for "Super Saiyan" as an example.    

local ki=dfhack.script_environment('dragonball/ki')

local get_transformation=dfhack.script_environment('dragonball/transformation').get_transformation

transformations={}

function get_S_cells(unit)
    local persist=dfhack.persistent.save{key='DRAGONBALL/S_CELLS/'..unit.id}
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is S-cells
    --ints[2] is experience with Super Saiyan 2
    --ints[3] is super saiyan anger event
    --ints[4] is trained by angel
    --ints[5] is legendary super saiyan (assigned at birth)
    return persist:save()
end

function get_god_training(unit)
    local persist=dfhack.persistent.save{key='DRAGONBALL/GOD_TRAINING/'..unit.id}
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is blue training level
    return persist:save()
end

transformations['Super Saiyan']={}

transformations['Super Saiyan'].potential_boost=function(unit)
    return 364265+get_S_cells(unit).ints[1]*0.7 --364265 is x50 at 3,000,000 battle power, 0.7 "looks nice" (thanks past me)
end

transformations['Super Saiyan'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    local persist=get_S_cells(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor((100000/unit.body.physical_attrs.ENDURANCE.value)/math.min(100,math.max(1,persist.ints[1]/10000))+0.5)
    persist.ints[1]=persist.ints[1]+100+unit.counters2.exhaustion
    persist:save()
end

transformations['Super Saiyan'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 0.1*math.floor((100000/unit.body.physical_attrs.ENDURANCE.value)/math.min(100,math.max(1,get_S_cells(unit).ints[1]/10000))+0.5)
end

transformations['Super Saiyan'].get_name=function(unit)
    local persist=get_S_cells(unit)
    return persist.ints[1]<1000000 and 'Super Saiyan' or 'Super Saiyan Full Power'
end

--units will use the transformation with the least cost unless they're up against bad odds; base form is assumed to have 0 cost, 0 benefit

transformations['Super Saiyan'].can_add=function(unit)
    return true
end

transformations['Super Saiyan'].transform_string=function(unit)
    return ' transformed into a Super Saiyan!'
end

transformations['Super Saiyan'].overlaps={'Oozaru'}

transformations['Super Saiyan'].spar=function(unit)
    return 1
end

--transformations['Super Saiyan'].on_attacked=function(attacker,defender,attack) end

--transformations['Super Saiyan'].on_attack=function(attacker,defender,attack) end

-- transformations['Super Saiyan'].overlaps={} --transformations that can overlap with this one, will replace otherwise

transformations['Legendary Super Saiyan']={}

transformations['Legendary Super Saiyan'].potential_boost=function(unit)
    return 420000+get_S_cells(unit).ints[1]*2
end

transformations['Legendary Super Saiyan'].on_tick=function(unit)
    local persist=get_S_cells(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+20
    persist.ints[1]=persist.ints[1]+100+unit.counters2.exhaustion
    persist:save()
end

transformations['Legendary Super Saiyan'].cost=function(unit)
    return 2
end

transformations['Legendary Super Saiyan'].benefit=function(unit)
    return 2
end

transformations['Legendary Super Saiyan'].on_attacked=function(attacker,defender,attack)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+attack.attack_velocity
    persist:save()
end

transformations['Legendary Super Saiyan'].get_name=function(unit)
    return 'Legendary Super Saiyan'
end

transformations['Legendary Super Saiyan'].can_add=function(unit)
    return get_S_cells(unit).ints[5] == 1
end

transformations['Legendary Super Saiyan'].transform_string=function(unit)
    return ' transformed into the Legendary Super Saiyan!'
end

transformations['Legendary Super Saiyan'].spar=function(unit)
    return 3
end

transformations['Legendary Super Saiyan 2']={}

transformations['Legendary Super Saiyan 2'].potential_boost=function(unit)
    return transformations['Legendary Super Saiyan'].potential_boost(unit)*1.4142
end

transformations['Legendary Super Saiyan 2'].on_tick=function(unit)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+200+math.floor(unit.counters2.exhaustion/5)
end

transformations['Legendary Super Saiyan 2'].cost=function(unit)
    return 0
end

transformations['Legendary Super Saiyan 2'].benefit=function(unit)
    return 3
end

transformations['Legendary Super Saiyan 2'].on_attacked=function(attacker,defender,attack)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+attack.attack_velocity
    persist:save()
end

transformations['Legendary Super Saiyan 2'].get_name=function(unit)
    return 'True Legendary Super Saiyan'
end

transformations['Legendary Super Saiyan 2'].can_add=function(unit)
    local S_cells=get_S_cells(unit)
    return S_cells.ints[5] == 1 and (S_cells.ints[1]>1000000 or (df.global.gamemode==df.game_mode.ADVENTURE and unit==df.global.world.units.active[0]))
end

transformations['Legendary Super Saiyan 2'].transform_string=function(unit)
    return ' transformed into the true Legendary Super Saiyan!'
end

transformations['Legendary Super Saiyan 2'].spar=function(unit)
    return 4
end


transformations['Super Saiyan 2']={}

transformations['Super Saiyan 2'].potential_boost=function(unit)
    return (transformations['Super Saiyan'].potential_boost(unit)*1.4142)+get_S_cells(unit).ints[2]*15
end

transformations['Super Saiyan 2'].on_tick=function(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(250000/unit.body.physical_attrs.ENDURANCE.value)
    local persist=get_S_cells(unit)
    persist.ints[1]=persist.ints[1]+200+math.floor(unit.counters2.exhaustion/5)
    persist.ints[2]=persist.ints[2]+100+math.floor(unit.counters2.exhaustion/10) --literally just super saiyan 2 progress for strengthened and anger forms
    persist:save()
end

transformations['Super Saiyan 2'].cost=function(unit)
    return 25000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Super Saiyan 2'].can_add=function(unit)
    local S_cells=get_S_cells(unit).ints[1]
    return S_cells>1000000 or (df.global.gamemode==df.game_mode.ADVENTURE and unit==df.global.world.units.active[0])
end

transformations['Super Saiyan 2'].ki_type=function(unit) 
    local S_cells=get_S_cells(unit)
    return S_cells.ints[3]==1 and 1
end

transformations['Super Saiyan 2'].benefit=function(unit)
    local S_cells=get_S_cells(unit)
    return (S_cells.ints[3]==1) and 1000
end

transformations['Super Saiyan 2'].get_name=function(unit)
    local S_cells=get_S_cells(unit)
    if S_cells.ints[2]>100000 then
        if S_cells.ints[3]==1 then
            return 'Super Saiyan Anger'
        else
            return 'Strengthened Super Saiyan 2'
        end
    else
        return 'Super Saiyan 2'
    end
end

transformations['Super Saiyan 2'].transform_string=function(unit)
    return ' transformed into a '..transformations['Super Saiyan 2'].get_name(unit)
end

transformations['Super Saiyan 2'].spar=function(unit)
    return 2
end

transformations['Super Saiyan 3']={}

transformations['Super Saiyan 3'].potential_boost=function(unit)
    return transformations['Super Saiyan 2'].potential_boost(unit)*2 --square root of 4, don't worry
end

transformations['Super Saiyan 3'].on_tick=function(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(1500000/unit.body.physical_attrs.ENDURANCE.value)
end

transformations['Super Saiyan 3'].cost=function(unit)
    return 150000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Super Saiyan 3'].can_add=function(unit)
    local S_cells=get_S_cells(unit).ints[1]
    return S_cells>2000000 or (df.global.gamemode==df.game_mode.ADVENTURE and unit==df.global.world.units.active[0])
end

transformations['Super Saiyan 3'].transform_string=function(unit)
    return ' transformed into a Super Saiyan 3!'
end

transformations['Super Saiyan 4']={}

transformations['Super Saiyan 4'].ki_mult=function(unit)
    return 10
end

transformations['Super Saiyan 4'].potential_boost=function(unit)
    return transformations['Super Saiyan 2'].potential_boost(unit)*2
end

transformations['Super Saiyan 4'].on_tick=function(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(50000/unit.body.physical_attrs.ENDURANCE.value)
end

transformations['Super Saiyan 4'].cost=function(unit)
    return 5000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Super Saiyan 4'].can_add=function(unit)
    return true
end

transformations['Super Saiyan 4'].transform_string=function(unit)
    return ' transformed into a Super Saiyan 4!'
end

transformations['Super Saiyan God']={}

transformations['Super Saiyan God'].ki_type=function(unit) 
    return 1
end

transformations['Super Saiyan God'].on_tick=function(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(50000/unit.body.physical_attrs.ENDURANCE.value)
end

transformations['Super Saiyan God'].cost=function(unit)
    return 5000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Super Saiyan God'].benefit=function(unit)
    return 1000
end

transformations['Super Saiyan God'].transform_string=function(unit)
    return ' transformed into a Super Saiyan God!'
end

transformations['Super Saiyan Blue']={}

transformations['Super Saiyan Blue'].potential_boost=function(unit)
    return transformations['Super Saiyan'].potential_boost(unit)
end

transformations['Super Saiyan Blue'].ki_type=function(unit) 
    return 1
end

transformations['Super Saiyan Blue'].on_tick=function(unit)
    local god_training=get_god_training(unit)
    local S_cells=get_S_cells(unit)
    god_training.ints[1]=god_training.ints[1]+1+math.floor(unit.counters2.exhaustion/1000)
    god_training:save()
    S_cells.ints[1]=S_cells.ints[1]+1+math.floor(unit.counters2.exhaustion/500)
    S_cells:save()
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(2000000/unit.body.physical_attrs.ENDURANCE.value)
end

transformations['Super Saiyan Blue'].cost=function(unit)
    return 200000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Super Saiyan Blue'].benefit=function(unit)
    return 1000
end

transformations['Super Saiyan Blue'].can_add=function(unit)
    return get_transformation(unit.id,'Super Saiyan God') and (get_S_cells(unit).ints[1]>1000000 or get_S_cells(unit).ints[4]==1)
end



transformations['Super Saiyan Blue'].overlaps={
    'Kaioken',
    'Kaioken x5',
    'Kaioken x10',
    'Kaioken x20'
}

transformations['Super Saiyan Blue'].transform_string=function(unit)
    return ' transformed into a Super Saiyan God Super Saiyan!'
end

transformations['Super Saiyan Blue'].spar=function(unit)
    return 4
end

transformations['Super Saiyan God Super Saiyan 4']={}

transformations['Super Saiyan God Super Saiyan 4'].ki_mult=function(unit)
    return 10
end

transformations['Super Saiyan God Super Saiyan 4'].ki_type=function(unit) 
    return 1
end

transformations['Super Saiyan God Super Saiyan 4'].potential_boost=function(unit)
    return transformations['Super Saiyan 2'].potential_boost(unit)*2
end

transformations['Super Saiyan God Super Saiyan 4'].on_tick=function(unit)
    local god_training=get_god_training(unit)
    local S_cells=get_S_cells(unit)
    god_training.ints[1]=god_training.ints[1]+1+math.floor(unit.counters2.exhaustion/1000)
    god_training:save()
    S_cells.ints[1]=S_cells.ints[1]+100+math.floor(unit.counters2.exhaustion/5)
    S_cells:save()
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(2000000/unit.body.physical_attrs.ENDURANCE.value)
end

transformations['Super Saiyan God Super Saiyan 4'].cost=function(unit)
    return 100000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Super Saiyan God Super Saiyan 4'].benefit=function(unit)
    return 1000
end

transformations['Super Saiyan God Super Saiyan 4'].can_add=function(unit)
    return get_transformation(unit.id,'Super Saiyan God') and get_transformation(unit.id,'Super Saiyan 4')
end

transformations['Super Saiyan God Super Saiyan 4'].overlaps={
    'Kaioken',
    'Kaioken x5',
    'Kaioken x10',
    'Kaioken x20'
}

transformations['Super Saiyan God Super Saiyan 4'].transform_string=function(unit)
    return ' transformed into a Super Saiyan God Super Saiyan 4!'
end

transformations['Beyond Super Saiyan Blue']={}

transformations['Beyond Super Saiyan Blue'].ki_mult=function(unit)
    return 20
end

transformations['Beyond Super Saiyan Blue'].ki_type=function(unit) 
    return 1
end

transformations['Beyond Super Saiyan Blue'].potential_boost=function(unit)
    return transformations['Super Saiyan 2'].potential_boost(unit)*1.4142
end

transformations['Beyond Super Saiyan Blue'].on_tick=function(unit)
    local S_cells=get_S_cells(unit)
    local god_training=get_god_training(unit)
    god_training.ints[1]=god_training.ints[1]+1+math.floor(unit.counters2.exhaustion/1000)
    god_training:save()
    S_cells.ints[1]=S_cells.ints[1]+200+math.floor(unit.counters2.exhaustion/2.5)
    S_cells.ints[2]=S_cells.ints[2]+200+math.floor(unit.counters2.exhaustion/5)
    S_cells:save()
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor(2000000/unit.body.physical_attrs.ENDURANCE.value)
end

transformations['Beyond Super Saiyan Blue'].cost=function(unit)
    return 200000/unit.body.physical_attrs.ENDURANCE.value
end

transformations['Beyond Super Saiyan Blue'].benefit=function(unit)
    return 1000
end

transformations['Beyond Super Saiyan Blue'].can_add=function(unit)
    return get_transformation(unit.id,'Super Saiyan Blue') --complicated addition procedure elsewhere
end

transformations['Beyond Super Saiyan Blue'].spar=function(unit)
    return 5
end

transformations['Beyond Super Saiyan Blue'].transform_string=function(unit)
    return ' transformed into Super Saiyan God Super Saiyan, and beyond that!'
end