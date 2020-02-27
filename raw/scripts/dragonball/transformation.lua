--@ module = true

--[[
    transformation persist info:
    1. ints[1]: currently transformed
    2. ints[2]: last tick that ticks was ran
    the rest can be used for whatever, but start from 7
]]

transformations={}

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

function get_all_transformations(unit_id)
    return dfhack.persistent.get_all('DRAGONBALL/TRANSFORMATIONS/'..unit_id,true)
end

function get_active_transformations(unit_id)
    local persists=get_all_transformations(unit_id)
    if not persists then return {} end
    local active_transformations={}
    for k,v in ipairs(persists) do
        if v.ints[1]==1 then 
            table.insert(active_transformations,v)
        end
    end
    return active_transformations
end

function get_inactive_transformations(unit_id)
    local persists=get_all_transformations(unit_id)
    if not persists then return {} end
    local inactive_transformations={}
    for k,v in ipairs(persists) do
        if v.ints[1]==0 then 
            table.insert(inactive_transformations,v)
        end
    end
    return inactive_transformations
end

function transformation_tick(unit_id)
    local unit=df.unit.find(unit_id)
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local transformation_table=transformations[active_transformation.value]
        local _=transformation_table.on_tick and transformation_table.on_tick(unit,(df.global.cur_year_tick - active_transformations.ints[2])%403200)
    end
end

function transformations_on_attack(attacker,defender,attack)
    for k,active_transformation in pairs(get_active_transformations(attacker.id)) do
        local transformation_table=transformations[active_transformation.value]
        local _=transformation_table.on_attack and transformation_table.on_attack(attacker,defender,attack)
    end
    return true
end

function transformations_on_attacked(attacker,defender,attack)
    for k,active_transformation in pairs(get_active_transformations(defender.id)) do
        local transformation_table=transformations[active_transformation.value]
        local _=transformation_table.on_attacked and transformation_table.on_attacked(attacker,defender,attack)
    end
    return true
end

function transformation_ticks(unit_id,t)
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local transformation_table=transformations[active_transformation.value]
        local _=transformation_table.on_tick and transformation_table.on_tick(df.unit.find(unit_id),t)
    end
end

function get_ki_type(unit_id)
    local unit=df.unit.find(unit_id)
    local max_ki_type=0
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local ki_type=active_transformation.ki_type and active_transformation.ki_type(unit)
        if ki_type and ki_type>max_ki_type then max_ki_type=ki_type end
    end
    return max_ki_type
end

function get_transformation_boosts(unit_id)
    local boost,mult,potential_boost=0,1,0
    local unit=df.unit.find(unit_id)
    for k,active_transformation in pairs(get_active_transformations(unit_id)) do
        local transformation_table=transformations[active_transformation.value]
        boost=boost+(transformation_table.ki_boost and transformation_table.ki_boost(unit) or 0)
        potential_boost=potential_boost+(transformation_table.potential_boost and transformation_table.potential_boost(unit) or 0)
        mult=mult*(transformation_table.ki_mult and transformation_table.ki_mult(unit) or 1)
    end
    return boost,mult,potential_boost
end

function add_transformation(unit_id,transformation)
    if (not transformations[transformation].can_add or transformations[transformation].can_add(df.unit.find(unit_id))) and not dfhack.persistent.get('DRAGONBALL/TRANSFORMATIONS/'..unit_id..'/'..transformation) then
        local persist=dfhack.persistent.save{key='DRAGONBALL/TRANSFORMATIONS/'..unit_id..'/'..transformation}
        persist.value=transformation
        persist.ints[1]=0 -- 1: transformed; 0: not
        --every other int can be used, of course
        persist:save()
        return persist
    end
    return false
end

function check_overlaps(unit_id,transformation,force_untransform)
    local unit_transformations=get_active_transformations(unit_id)
    for k,active_transformation in pairs(unit_transformations) do
        if active_transformation~=persist then
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
                if force_untransform then
                    transform(unit_id,active_transformation.value,false)
                end
                return false
            end
        end
    end
    return true
end

function transform(unit_id,transformation,transforming)
    local persist=get_transformation(unit_id,transformation)
    if not persist then return false end
    local unit=df.unit.find(unit_id)
    local isAdventurer=df.global.gamemode == df.game_mode.ADVENTURE and unit == df.global.world.units.active[0]
    if transforming then
        check_overlaps(unit_id,transformation,true)
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
        (isAdventurer and "You have " or (dfhack.TranslateName(dfhack.units.getVisibleName(unit)).." has ")).."stopped using "..(transformations[transformation].get_name and transformations[transformation].get_name(unit) or transformation)..'.',
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
    local unitTransformation=get_inactive_transformations(unit_id)
    if not unitTransformation then return false end
    local activeTransformations=get_active_transformations(unit_id)
    local transformationInformation={}
    local activeTransformationInformation={}
    local unit=df.unit.find(unit_id)
    for k,transformation in pairs(unitTransformation) do
        local properTransformation=transformations[transformation.value]
        table.insert(transformationInformation,properTransformation)
    end
    for k,transformation in pairs(activeTransformations) do
        local properTransformation=transformations[transformation.value]
        table.insert(activeTransformationInformation,properTransformation)
    end
    if sparring then
        local bestActiveSparNumber=-10000000
        local bestSpar,bestSparNumber={identifier='bepis'},-10000000
        for k,transformation in ipairs(transformationInformation) do
            local curSparNumber=transformation.spar and transformation.spar(unit)
            if curSparNumber and curSparNumber>bestSparNumber then
                bestSpar=transformation
                bestSparNumber=curSparNumber
            end
        end
        for k,transformation in ipairs(activeTransformationInformation) do
            local curSparNumber=transformation.spar and transformation.spar(unit)
            if curSparNumber and curSparNumber>bestActiveSparNumber then
                bestActiveSparNumber=curSparNumber
            end
        end
        if bestSparNumber>bestActiveSparNumber then
            transform(unit_id,bestSpar.identifier,true)
        end
    else
        for k,transformation in ipairs(transformationInformation) do
            if transformations[transformation.identifier].forced and
               check_overlaps(unit_id,transformation.identifier,false) and
               transformations[transformation.identifier].can_transform(unit) then
                transform(unit_id,transformation.identifier,true)
            end
        end
        if kiInvestment>enemyKiInvestment or (df.global.gamemode==df.game_mode.ADVENTURE and unit_id==df.global.world.units.active[0].id) then return false end
        --can stay in base if enemy is weaker than us; adventurers are exempt
        table.sort(transformationInformation,function(a,b) return a.cost(unit)<b.cost(unit) end)
        local mostPowerful={identifier='bepis'}
        local mostPowerfulNumber=-1000000
        local ki=dfhack.script_environment('dragonball/ki')
        local baseKi=ki.get_max_ki_pre_boost(unit_id)
        local trueBase=ki.get_true_base_ki(unit_id)
        local totalOverlaps={}
        for k,transformation in ipairs(activeTransformations) do
            if transformation.overlaps then
                for kk,v in ipairs(transformation.overlaps) do
                    table.insert(totalOverlaps,v)
                end
            end
        end
        for k,transformation in ipairs(transformationInformation) do
            if (not transformations[transformation.identifier].can_transform) or transformations[transformation.identifier].can_transform(unit) then
                local canOverlap=false
                for kk,overlap in ipairs(totalOverlaps) do
                    if overlap==transformation.identifier then
                        canOverlap=true
                        break
                    end
                end
                local transformInvestment=canOverlap and kiInvestment or baseKi
                local actualPotentialBoost=0
                if transformation.potential_boost then
                    actualPotentialBoost=ki.ki_func(trueBase+transformation.potential_boost(unit))-ki.ki_func(trueBase)
                end
                transformInvestment=transformInvestment+actualPotentialBoost
                transformInvestment=transformInvestment+(transformation.ki_boost and transformation.ki_boost(unit) or 0)
                transformInvestment=transformInvestment*(transformation.ki_mult and transformation.ki_mult(unit) or 1)
                local benefitMult=transformation.benefit and transformation.benefit(unit) or 1
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
