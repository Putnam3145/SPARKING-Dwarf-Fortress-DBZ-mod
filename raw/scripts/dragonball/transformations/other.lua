local get_transformation=dfhack.script_environment('dragonball/transformation').get_transformation

function get_god_training(unit)
    local persist=dfhack.persistent.save('DRAGONBALL/GOD_TRAINING/'..unit.id)
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is blue training level
    --ints[2] is ultra instinct training
    return persist:save()
end

transformations={}

transformations['Kaioken']={}

transformations['Kaioken'].ki_mult=function(unit)
    return 2
end

transformations['Kaioken'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor((50000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Kaioken'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 5000/unit.body.physical_attrs.ENDURANCE
end

transformations['Kaioken'].get_name=function(unit)
    return 'Kaioken x2'
end

transformations['Kaioken'].can_add=function(unit)
    return true
end

transformations['Kaioken'].transform_string=function(unit)
    return ' used Kaioken (x2)!'
end

transformations['Kaioken x5']={}

transformations['Kaioken x5'].ki_mult=function(unit)
    return 5
end

transformations['Kaioken x5'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counters2.exhaustion=unit.counters2.exhaustion+(100000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Kaioken x5'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 10000/unit.body.physical_attrs.ENDURANCE
end

transformations['Kaioken x5'].get_name=function(unit)
    return 'Kaioken x5'
end

transformations['Kaioken x5'].can_add=function(unit)
    return true
end

transformations['Kaioken x5'].transform_string=function(unit)
    return ' used Kaioken (x5)!'
end

transformations['Kaioken x10']={}

transformations['Kaioken x10'].ki_mult=function(unit)
    return 10
end

transformations['Kaioken x10'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counters2.exhaustion=unit.counters2.exhaustion+(300000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Kaioken x10'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 30000/unit.body.physical_attrs.ENDURANCE
end

transformations['Kaioken x10'].get_name=function(unit)
    return 'Kaioken x10'
end

transformations['Kaioken x10'].can_add=function(unit)
    return true
end

transformations['Kaioken x10'].transform_string=function(unit)
    return ' used Kaioken (x10)!'
end

transformations['Kaioken x20']={}

transformations['Kaioken x20'].ki_mult=function(unit)
    return 20
end

transformations['Kaioken x20'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counters2.exhaustion=unit.counters2.exhaustion+(600000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Kaioken x20'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 60000/unit.body.physical_attrs.ENDURANCE
end

transformations['Kaioken x20'].get_name=function(unit)
    return 'Kaioken x20'
end

transformations['Kaioken x20'].can_add=function(unit)
    return true
end

transformations['Kaioken x20'].transform_string=function(unit)
    return ' used Kaioken (x20)!'
end

transformations['Ultra Instinct "Sign"']={}

transformations['Ultra Instinct "Sign"'].ki_mult=function(unit)
    return 100
end

transformations['Ultra Instinct "Sign"'].ki_type=function(unit) 
    return 'God' 
end

transformations['Ultra Instinct "Sign"'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    local god_training=get_god_training(unit)
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor((1000000/unit.body.physical_attrs.ENDURANCE)
    god_training.ints[2]=god_training.ints[2]+1
end

transformations['Ultra Instinct "Sign"'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 100000/unit.body.physical_attrs.ENDURANCE
end

transformations['Ultra Instinct "Sign"'].benefit=function(unit) --how much benefit the transformation has, for use in AI
    return 2^1000
end

transformations['Ultra Instinct "Sign"'].get_name=function(unit)
    return 'Ultra Instinct "Sign"'
end

transformations['Ultra Instinct "Sign"'].can_add=function(unit)
    return true
end

transformations['Ultra Instinct "Sign"'].on_attacked=function(attacker,defender,attack)
    attack.attack_accuracy=0 --yes, i'm serious
end

transformations['Ultra Instinct "Sign"'].transform_string=function(unit)
    return ' undergone a strange, frightening transformation!'
end

transformations['Ultra Instinct']={}

transformations['Ultra Instinct'].ki_mult=function(unit)
    return 100
end

transformations['Ultra Instinct'].ki_type=function(unit) 
    return 'God' 
end

transformations['Ultra Instinct'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counters2.exhaustion=unit.counters2.exhaustion+math.floor((1000000/unit.body.physical_attrs.ENDURANCE)
end

transformations['Ultra Instinct'].cost=function(unit)
    return 100000/unit.body.physical_attrs.ENDURANCE
end

transformations['Ultra Instinct'].benefit=function(unit)
    return 1/0 --IEEE 754 floating point standard sets this at infinity, which makes it always better than any alternative
end

transformations['Ultra Instinct'].get_name=function(unit)
    return 'Ultra Instinct'
end

transformations['Ultra Instinct'].can_add=function(unit)
    return true
end

transformations['Ultra Instinct'].on_attacked=function(attacker,defender,attack)
    attack.attack_accuracy=0 --yes, i'm serious
end

transformations['Ultra Instinct'].on_attack=function(attacker,defender,attack)
    attack.attack_accuracy=1000000 --yes, i'm really serious
end

transformations['Ultra Instinct'].transform_string=function(unit)
    return ' started using Ultra Instinct!'
end