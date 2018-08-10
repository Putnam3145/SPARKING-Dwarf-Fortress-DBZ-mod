--@ module = true

local transformations={}

function load_transformation_file(file_name)
    local new_transformation_file=dfhack.script_environment(file_name)
    for k,v in pairs(new_transformation_file.transformations) do
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
    if not persists then return {} end
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

function transformations_on_attack(attacker,defender,attack)
    for k,active_transformation in pairs(get_active_transformations(attacker.id)) do
        local _=active_transformation.on_attack and active_transformation.on_attack(attacker,defender,attack)
    end
    return true
end

function transformations_on_attacked(attacker,defender,attack)
    for k,active_transformation in pairs(get_active_transformations(defender.id)) do
        local _=active_transformation.on_attacked and active_transformation.on_attacked(attacker,defender,attack)
    end
    return true
end

function transformation_ticks(unit_id)
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local _=active_transformation.on_tick and active_transformation.on_tick(df.unit.find(unit))
    end
end

function get_transformation_boosts(unit_id)
    local boost,mult=0,1
    local unit=df.unit.find(unit_id)
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local transformation_table=transformations[active_transformation.value]
        boost=boost+(transformation_table.ki_boost and transformation_table.ki_boost(unit) or 0)
        mult=mult*(transformation_table.ki_mult and transformation_table.ki_mult(unit) or 1)
    end
    return boost,mult
end

function add_transformation(unit_id,transformation)
    if transformations[transformation].can_add(df.unit.find(unit_id)) and not dfhack.persistent.get('DRAGONBALL/TRANSFORMATIONS/'..unit_id..'/'..transformation) then
        local persist=dfhack.persistent.save{key='DRAGONBALL/TRANSFORMATIONS/'..unit_id..'/'..transformation}
        persist.value=transformation
        persist.ints[1]=0 -- 1: transformed; 0: not
        --every other int can be used, of course
        persist:save()
        return persist
    end
    return false
end

function transform(unit_id,transformation,transforming)
    local persist=get_transformation(unit_id,transformation)
    if not persist then return false end
    local unit=df.unit.find(unit_id)
    local isAdventurer=df.global.gamemode == df.game_mode.ADVENTURE and unit == df.global.world.units.active[0]
    if transforming then
        local unit_transformations=get_active_transformations(unit_id)
        for k,active_transformation in pairs(unit_transformations) do
            local can_overlap=false
            local transformation_info=transformations[active_transformation.value]
            if transformation_info.overlaps then
                for k,overlap in pairs(transformation_info.overlaps) do
                    if overlap==transformation then
                        can_overlap=true
                    end
                end
            end
            if not can_overlap then
                transform(unit_id,active_transformation,false)
            end
        end
        if (not transformations[transformation].can_transform) or transformations[transformation].can_transform(unit) then
            persist.ints[1]=1
            local _=transformations[transformation].on_transform and transformations[transformation].on_transform(unit)
            dfhack.gui.showAutoAnnouncement(df.announcement_type.INTERACTION_ACTOR,
            unit.pos,
            (isAdventurer and "You have" or (dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." has"))..transformations[transformation].transform_string(unit),
            COLOR_CYAN,
            true,
            unit)
        end
    else
        persist.ints[1]=0
        local _=transformations[transformation].on_untransform and transformations[transformation].on_untransform(unit)
        dfhack.gui.showAutoAnnouncement(df.announcement_type.INTERACTION_ACTOR,
        unit.pos,
        (isAdventurer and "You have " or (dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." has ")).."stopped using "..transformations[transformation].get_name(unit)..'.',
        COLOR_CYAN,
        true,
        unit)
    end
    persist:save()
    return persist
end

function revert_to_base(unit_id)
    for k,transformation in pairs(get_active_transformations(unit_id)) do
        transform(unit_id,transformation.value,false)
    end
end

function transform_ai(unit_id,kiInvestment,kiType,enemyKiInvestment,enemyKiType,sparring)
    local activeTransformations=get_active_transformations(unit_id)
    if kiInvestment>enemyKiInvestment then return false end --can stay in base if enemy is weaker than us
    local unitTransformation=get_all_transformations(unit_id)
    if not unitTransformation then return false end
    local transformationInformation={}
    local unit=df.unit.find(unit_id)
    for k,transformation in pairs(unitTransformation) do --how the hell?
        local properTransformation=transformations[transformation.value]
        table.insert(transformationInformation,properTransformation)
    end
    if sparring then
        local bestSpar,bestSparNumber={identifier='bepis'},-10000000
        for k,transformation in ipairs(transformationInformation) do
            local curSparNumber=transformation.spar and transformation.spar(unit)
            if curSparNumber and curSparNumber>bestSparNumber then
                bestSpar=transformation
                bestSparNumber=curSparNumber
            end
        end
        transform(unit_id,bestSpar.identifier,true)
    else
        table.sort(transformationInformation,function(a,b) return a.cost(unit)<b.cost(unit) end)
        local mostPowerful={identifier='bepis'}
        local mostPowerfulNumber=-1000000
        for k,transformation in ipairs(transformationInformation) do
            if (not transformations[transformation.identifier].can_transform) or transformations[transformation.identifier].can_transform(unit) then
                local transformInvestment=(kiInvestment+(transformation.ki_boost and transformation.ki_boost(unit) or 0)*(transformation.ki_mult and transformation.ki_mult(unit) or 1))
                local benefitMult=transformation.benefit and transformation.benefit(unit)
                local totalPower=benefitMult*transformInvestment
                if totalPower>mostPowerfulNumber then 
                    mostPowerful=transformation
                    mostPowerfulNumber=totalPower
                end
                if (transformInvestment*benefitMult)>=enemyKiInvestment then --either as soon as transformation is sufficient
                    transform(unit_id,transformation.identifier,true)
                    return true
                end
            end
        end
        transform(unit_id,mostPowerful.identifier,true)
        return true
    end
end

load_transformation_file('dragonball/transformations/super_saiyan')
load_transformation_file('dragonball/transformations/other')