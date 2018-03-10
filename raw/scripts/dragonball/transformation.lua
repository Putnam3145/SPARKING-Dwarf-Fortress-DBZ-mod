--@ module = true

local transformations={}

function load_transformation_file(file_name)
    local new_transformation_file=dfhack.script_environment(file_name)
    for k,v in pairs(file_name.transformations) do
        v.identifier=k
        transformations[k]=v
    end
end

function get_transformation(unit_id,transformation,force)
    if force then
        return add_transformation(unit_id,transformation)
    else
        return dfhack.persistent.get('DRAGONBALL/TRANSFORMATIONS/'..unit_id..'/'..transformation)
    end
end

function get_active_transformations(unit_id)
    local persists=dfhack.persistent.get_all('DRAGONBALL/TRANSFORMATIONS/'..unit_id,true)
    local active_transformations={}
    for k,v in ipairs(persists) do
        if v.ints[1]==1 then 
            table.insert(active_transformations,v)
        end
    end
    return active_transformations
end

function get_all_transformations(unit_id)
    return dfhack.persistent.get_all('DRAGONBALL/TRANSFORMATIONS/'..unit_id,true)
end

function transformation_tick(unit_id)
    local unit=df.unit.find(unit_id)
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local transformation_table=transformations[active_transformation.value]
        local _=transformation_table.on_tick and transformation_table.on_tick(unit)
    end
end

function get_transformation_boosts(unit_id)
    local boost,mult=0,1
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local transformation_table=transformations[active_transformation.value]
        boost=boost+transformation_table.ki_boost and transformation_table.ki_boost() or 0
        mult=mult*transformation_table.ki_mult and transformation_table.ki_mult() or 1
    end
    return boost,mult
end

function add_transformation(unit_id,transformation)
    if transformations[transformation].can_add(unit_id) then
        local persist=dfhack.persistent.save('DRAGONBALL/TRANSFORMATIONS/'..unit_id..'/'..transformation)
        persist.value=transformation
        persist.ints[1]=0 -- 1: transformed; 0: not
        --every other int can be used, of course
        persist:save()
        return persist
    end
end

function transform(unit_id,transformation,transforming)
    local persist=get_transformation(transformation)
    if transforming then
        persist.ints[1]=1
        local _=transformations[transformation].on_transform and transformations[transformation].on_transform(df.unit.find(unit))
    else
        persist.ints[1]=0
        local _=transformations[transformation].on_untransform and transformations[transformation].on_untransform(df.unit.find(unit))
    end
    persist:save()
    return persist
end

function transform_ai(unit_id,kiInvestment,kiType,enemyKiInvestment,enemyKiType)
    local ratio=enemyKiInvestment/kiInvestment
    local activeTransformations=get_active_transformations(unit_id)
    if ratio<1 then return false end --can stay in base if enemy is weaker than us
    local unitTransformation=get_all_transformations(unit_id)
    local transformationInformation={}
    local unit=df.unit.find(unit_id)
    for k,transformation in pairs(unit_transformations) do
        local properTransformation=transformations[transformation.value]
        table.insert(transformationInformation,properTransformation)
    end
    table.sort(transformationInformation,function(a,b) return a.cost(unit)<b.cost(unit) end)
    for k,transformation in ipairs(transformationInformation) do
        if transformation.benefit(unit)>=ratio or k==#transformationInformation then --either as soon as transformation is sufficient OR most powerful if desperate
            transform(unit,transformation,true)
            return true
        end
    end
end

load_transformation_file('dragonball/transformations/super_saiyan')
load_transformation_file('dragonball/transformations/other')