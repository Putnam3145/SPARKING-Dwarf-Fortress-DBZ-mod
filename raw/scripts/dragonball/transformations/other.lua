local get_transformation=dfhack.script_environment('dragonball/transformation').get_transformation

transformations={}

transformations['Ultra Instinct "Sign"']={}

transformations['Ultra Instinct "Sign"']={}

transformations['Ultra Instinct "Sign"'].ki_mult=function(unit)
    return 100
end

transformations['Ultra Instinct "Sign"'].ki_type=function(unit) 
    return 'God' 
end

transformations['Ultra Instinct "Sign"'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counts2.exhaustion=unit.counters2.exhaustion+math.floor((1000000/unit.body.physical_attrs.ENDURANCE)/math.min(100,math.max(1,persist.ints[1]/100))+0.5)
end

transformations['Ultra Instinct "Sign"'].cost=function(unit) --how much cost the transformation has, in various ways, for use in AI
    return 1000000/unit.body.physical_attrs.ENDURANCE
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

transformations['Ultra Instinct "Sign"']={}

transformations['Ultra Instinct']={}

transformations['Ultra Instinct'].ki_mult=function(unit)
    return 100
end

transformations['Ultra Instinct'].ki_type=function(unit) 
    return 'God' 
end

transformations['Ultra Instinct'].on_tick=function(unit) --will be done every 10 Dwarf Fortress ticks.
    unit.counts2.exhaustion=unit.counters2.exhaustion+math.floor((1000000/unit.body.physical_attrs.ENDURANCE)/math.min(100,math.max(1,persist.ints[1]/100))+0.5)
end

transformations['Ultra Instinct'].cost=function(unit)
    return 1000000/unit.body.physical_attrs.ENDURANCE
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