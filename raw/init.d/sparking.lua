local ki=dfhack.script_environment('dragonball/ki')

local function unitHasCreatureClass(unit,class)
    for _,c_class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if c_class.value == class then return true end
    end
    return false
end

local function getSubClassValue(unit,class)
    for _,c_class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        local class_value=c_class.value
        if class_value:find('/') then
            if class_value:sub(0,class_value:find('/')-1) == class then return class_value:sub(1+class_value:find('/.*')) end
        end
    end
    return false
end

local function getSubClassValues(unit,class)
    local values={}
    for _,c_class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        local class_value=c_class.value
        if class_value:find('/') then
            if class_value:sub(0,class_value:find('/')-1) == class then table.insert(values,class_value:sub(1+class_value:find('/.*'))) end
        end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for __,s_class in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            local class_value=s_class.value
            if class_value:find('/') then
                if class_value:sub(0,class_value:find('/')-1) == class then table.insert(values,class_value:sub(1+class_value:find('/.*'))) end
            end
        end
    end
    return #values>0 and values or false
end

local function getPowerLevel(saiyan)
    return dfhack.script_environment('dragonball/ki').get_max_ki_pre_boost(saiyan.id)
end

local transformation=dfhack.script_environment('dragonball/transformation')

local function getSuperSaiyanCount()
    local superSaiyanCount = 0
    for _,unit in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(unit) and transformation.get_transformation(unit.id,'Super Saiyan') then
            superSaiyanCount = superSaiyanCount + 1
        end
    end
    return superSaiyanCount
end

local function unitWithHighestPowerLevel()
    local highestUnit = nil
    local highestPowerLevel = 0
    for _,unit in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(unit) and dfhack.units.isDwarf(unit) then
            local unitPowerLevel=getPowerLevel(unit)
            if unitPowerLevel>highestPowerLevel then
                highestUnit = unit
                highestPowerLevel = unitPowerLevel
            end
        end
    end
    return highestUnit,highestPowerLevel
end

local function combinedSaiyanPowerLevel()
    local totalPowerLevel=0
    for _,unit in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(unit) then totalPowerLevel = totalPowerLevel + getPowerLevel(unit) end
    end
    return totalPowerLevel
end

local function stopMegabeastAttacks()
    local removedMegaBeastAttack = false
    for eventid,event in ipairs(df.global.timed_events) do
        if event.type == df.timed_event_type.Megabeast then
            table.remove(df.global.timed_events,eventid)
            removedMegaBeastAttack = true
        end
    end
    return removedMegaBeastAttack
end

local function causeMegaBeastAttack()
    df.global.timed_events:insert('#', { new = df.timed_event, type = df.timed_event_type.Megabeast, season = df.global.cur_season, season_ticks = df.global.cur_season_tick } )
end

local function checkForMegabeastAttack()
    if combinedSaiyanPowerLevel() > 4000000 and stopMegabeastAttacks() then causeMegaBeastAttack() end
end

local function getInorganic(item)
    return dfhack.matinfo.decode(item).inorganic
end

local function tailClipSyndrome()
    return df.global.world.raws.inorganics[dfhack.matinfo.find("DB_DFHACK_SYNDROME_HOLDER").index].material.syndrome[0].id
end

local function giveName(unit,nameCopy)
    for ii=1,3 do
        local unitName = ii==1 and unit.name or ii==2 and unit.status.current_soul.name or unit.hist_figure_id>-1 and df.historical_figure.find(unit.hist_figure_id).name or {words={},parts_of_speech={}}
        unitName.first_name = nameCopy.first_name or "dummy"
        unitName.nickname = nameCopy.nickname or ""
        unitName.language = nameCopy.language or -1
        unitName.unknown = nameCopy.unknown or 0
        unitName.has_name=true
        for i=1,7 do
            unitName.words[i-1] = nameCopy.words and nameCopy.words[i] or -1
            unitName.parts_of_speech[i-1] = nameCopy.parts_of_speech and nameCopy.parts_of_speech[i] or -1
        end
    end
end

local function fuseTwoNames(unit1,unit2)
    local name1=unit1.name
    local name2=unit2.name
    local newName = {}
    newName.first_name = string.sub(name1.first_name,1,math.floor(#name1.first_name/2)) .. string.sub(name2.first_name,-math.ceil(#name2.first_name/2)) --cuts each name in two and combines the first half of the first name and the second half of the second
    newName.nickname = ""
    newName.language = name1.language
    newName.unknown = name1.unknown
    newName.words = {}
    newName.parts_of_speech = {}
    for i = 1, 7 do
        if i%2==1 then
            newName.words[i] = name2.words[i-1]
            newName.parts_of_speech[i] = name1.parts_of_speech[i-1]
        else
            newName.words[i] = name1.words[i-1]
            newName.parts_of_speech[i] = name2.parts_of_speech[i-1]
        end
    end
    dfhack.gui.showPopupAnnouncement(name1.first_name .. " has fused with " .. name2.first_name .. " to become " .. newName.first_name .. "!",COLOR_BLUE,true)
    giveName(unit1,newName)
end

local function insertSkill(unit,skill)
    unit.status.current_soul.skills:insert('#', 
        {
        new = df.unit_skill,
        id = skill.id,
        rating = skill.rating,
        experience = skill.experience,
        unused_counter = skill.unused_counter,
        rusty = skill.rusty,
        rust_counter = skill.rust_counter,
        demotion_counter = skill.demotion_counter, 
        unk_1c = skill.unk_1c
        }
    )
end

local function combineSoul(unit1,unit2)
    local firstUnitSoul = unit1.status.current_soul
    local secondUnitSoul= unit2.status.current_soul
    for k,attribute in ipairs(firstUnitSoul.mental_attrs) do
        attribute.value = attribute.value + secondUnitSoul.mental_attrs[k].value
        attribute.max_value = attribute.max_value + secondUnitSoul.mental_attrs[k].max_value
        if attribute.value < 0 or attribute.value > 2^31-1 then attribute.value = 2^30 end
        if attribute.max_value < 0 or attribute.max_value > 2^31-1 then attribute.max_value = 2^31-1 end
    end
    for _,skill2 in ipairs(secondUnitSoul.skills) do
        local skillFound = false
            for _,skill1 in ipairs(firstUnitSoul.skills) do
                if skill2.id == skill1.id then 
                    skillFound = true
                    skill1.rating = skill1.rating + skill2.rating
                end
            end
        if not skillFound then 
            insertSkill(unit1,skill2)
        end
    end
    --preferences are too much trouble for their worth
    for k,trait1 in ipairs(firstUnitSoul.traits) do
        local trait2 = secondUnitSoul.traits[k]
        trait1 = math.floor((trait1+trait2)/2)
    end
    --unk5 and unk6 are... unknown to me, so...
end

local function combineBody(unit1,unit2)
    local firstBody = unit1.body
    local firstAppearance = unit1.appearance
    local secondBody = unit2.body
    local secondAppearance = unit2.appearance
    firstBody.blood_max = firstBody.blood_max + secondBody.blood_max
    firstBody.blood_count = firstBody.blood_max
    for k,attribute in ipairs(firstBody.physical_attrs) do
        attribute.value = attribute.value + secondBody.physical_attrs[k].value
        attribute.max_value = attribute.max_value * secondBody.physical_attrs[k].max_value
        if attribute.value < 0 or attribute.value > 2^31-1 then attribute.value = 2^30 end
        if attribute.max_value < 0 or attribute.max_value > 2^31-1 then attribute.max_value = 2^31-1 end
    end
    for k,modifier in ipairs(firstAppearance.body_modifiers) do
        if #secondAppearance.body_modifiers>k+1 then modifier = math.floor((modifier+secondAppearance.body_modifiers[k])/2) end
    end
    for k,modifier in ipairs(firstAppearance.bp_modifiers) do
        if #secondAppearance.bp_modifiers>k+1 then modifier = math.floor((modifier+secondAppearance.bp_modifiers[k])/2) end
    end
    for k,length1 in ipairs(firstAppearance.tissue_length) do
        local length2 = #secondAppearance.tissue_length>k+1 and secondAppearance.tissue_length[k] or nil
        if length2 then length1 = math.floor((length1+length2)/2) end
    end
end

local function combineCounters(unit1,unit2)
    local trait1 = dfhack.units.getMiscTrait(unit1,15,true)
    local trait2 = dfhack.units.getMiscTrait(unit2,15,true)
    local totalValue = trait1.value+trait2.value
    trait1.value=math.min(totalValue,100)
end

local function fuseUnits(unit1,unit2)
    if unit1.race~=unit2.race then
        return nil
    end
    fuseTwoNames(unit1,unit2)
    combineSoul(unit1,unit2)
    combineBody(unit1,unit2)
    combineCounters(unit1,unit2)
    unit2.animal.vanish_countdown=2
end

eventful=require 'plugins.eventful'
dialog=require 'gui.dialogs'
script=require 'gui.script'

local function fusion(reaction,unit,input_items,input_reagents,output_items,call_native)
    local tbl={}
    for k,u in ipairs(df.global.world.units.active) do
        local name=dfhack.TranslateName(dfhack.units.getVisibleName(u))
        if name=="" then name="?" end
        if (df.global.gamemode==df.game_mode.ADVENTURE and u.race==df.global.world.units.active[0].race) or (df.global.gamemode==0 and dfhack.units.isDwarf(u) and dfhack.units.isCitizen(u)) then table.insert(tbl,{name,nil,u}) end
    end
    table.sort(tbl,function(a,b) return getPowerLevel(a[3])>getPowerLevel(b[3]) end)
    script.start(function()
        local unitsToFuse={}
        repeat
            for i=1,2 do
                local ok, name, C = script.showListPrompt("Unit Selection","Choose " ..(i==1 and "first" or "second").. " Saiyan to fuse (sorted by power level)",COLOR_WHITE,tbl)
                if ok then table.insert(unitsToFuse,C[3]) end
            end
            if unitsToFuse[1]==unitsToFuse[2] then unitsToFuse[1]=nil unitsToFuse[2]=nil unitsToFuse={} end
        until unitsToFuse[1] and unitsToFuse[2] and unitsToFuse[1]~=unitsToFuse[2]
        fuseUnits(unitsToFuse[1],unitsToFuse[2])
        syndromeUtil.infectWithSyndrome(unitsToFuse[1],tailClipSyndrome(),syndromeUtil.ResetPolicy.DoNothing)
    end)
    call_native.value=false
end

eventful.registerReaction("LUA_HOOK_FUSION_DB",fusion)

local function fixOverflow(a)
    return (a<0) and 2^30-1 or a
end

local function fixStrengthBug(unit)
    local strength = unit.body.physical_attrs.STRENGTH
    strength.max_value=math.min(strength.max_value,100000)
end

local projectileFunctionsImpact,projectileFunctionsMove={},{}

projectileFunctionsMove['KAMEHAMEHA_DB']=function(projectile)
    dfhack.maps.spawnFlow(projectile.cur_pos,3,0,dfhack.matinfo.find("KAMEHAMEHA_DB").index,400)
end

projectileFunctionsMove['SUN_BEAM_DB']=function(projectile)
    dfhack.maps.spawnFlow(projectile.cur_pos,3,0,dfhack.matinfo.find("SUN_BEAM_DB").index,200)
end

eventful.onProjItemCheckMovement.dragonball=function(projectile)
    local mat=dfhack.matinfo.decode(projectile.item)
    local matId=mat and (mat.inorganic and mat.inorganic.id or mat.material.id) or ''
    local projFunc=projectileFunctionsMove[matId]
    if projFunc then projFunc(projectile) end
end

--[[eventful.onProjItemCheckImpact.dragonball=function(projectile,somebool) --not implemented yet, since nothing requires it yet
    local mat=dfhack.matinfo.decode(projectile.item)
    local matId=mat and (mat.inorganic and mat.inorganic.id or mat.material.id) or ''
    local projFunc=projectileFunctionsImpact[matId]
    if projFunc then projFunc(projectile,somebool) end
]]

local dbEvents={
    onUnitGravelyInjured=dfhack.event.new()
}
    
local function dbRound(num)
    return math.floor(num+0.5)
end

local function averageTo1(num,howMany)
    howMany=tonumber(howMany) or 1
    return (howMany+num)/(howMany+1)
end

local function unitUndergoingSSJEmotion(unit)
    if df.creature_raw.find(unit.race).creature_id~='SAIYAN' then return false end
    local emotions=unit.status.current_soul.personality.emotions
    for k,v in ipairs(emotions) do
        local divider=tonumber(df.emotion_type.attrs[v.type].divider)
        if (divider==2 or divider==1) and v.strength/divider>=25 then
            return true
        end
    end
    return false
end

local function renameUnitIfApplicable(unit)
    local newName={first_name=getSubClassValue(unit,'SPECIAL_NAME')}
    if newName.first_name then
        giveName(unit,newName)
    end
end

local function unitInDeadlyCombat(unit)
    return math.abs(unit.reports.last_year_tick.Combat-df.global.cur_year_tick)%403100<100
end

local function unitInCombat(unit)
    for k,v in pairs(unit.reports.last_year_tick) do
        if math.abs(v-df.global.cur_year_tick)%403100<100 then
            return true
        end
    end
    return false
end

local function doZenkai(unit)
    local zenkai_persist=dfhack.persistent.save{key="DRAGONBALL/ZENKAI/"..unit.id}
    if zenkai_persist.ints[1]<=0 then
        return false
    end
    local totalBoost=zenkai_persist.ints[1]/3
    for ki_type,ki_table in pairs(ki.ki_attrs) do
        local boostActual=ki_table.coefficient*totalBoost
        for _,attribute_name in pairs(ki_table.phys) do
            local attribute=unit.body.physical_attrs[attribute_name]
            attribute.value=math.min(attribute.max_value,dbRound(attribute.value+boostActual))
        end
        for _,attribute_name in pairs(ki_table.ment) do
            local attribute=unit.status.current_soul.mental_attrs[attribute_name]
            attribute.value=math.min(attribute.max_value,dbRound(attribute.value+boostActual))
        end
    end
    zenkai_persist.ints[1]=0
    zenkai_persist:save()
    return true
end

local function setupNaturalTransformations(unit)
    local transformations=getSubClassValues(unit,'NATURAL_TRANSFORMATION')
    if transformations then
        for k,v in pairs(transformations) do
            transformation.add_transformation(unit.id,v)
        end
    end
end

local function isAdventurer(unit)
    return (df.global.gamemode==df.game_mode.ADVENTURE and unit==df.global.world.units.active[0])
end

local function slowEveryoneElseDown(unit_id,action,kiAmount)
    local action_actions={
        Move=function(data,delay)
            data.move.timer=math.min(dbRound(data.move.timer*delay),200) 
        end,
        Attack=function(data,delay)
            if data.attack.timer1>0 then
                data.attack.timer1=math.min(dbRound(data.attack.timer1*delay),200)
            else
                data.attack.timer2=math.min(dbRound(data.attack.timer2*delay),200)
            end
        end,
        HoldTerrain=function(data,delay)
            data.holdterrain.timer=math.min(dbRound(data.holdterrain.timer*delay),200)
        end,
        Climb=function(data,delay)
            data.climb.timer=math.min(dbRound(data.climb.timer*delay),200)
        end,
        --talking, of course, is a free action
        Unsteady=function(data,delay)
            data.unsteady.timer=math.min(dbRound(data.unsteady.timer*delay),200)
        end,
        Recover=function(data,delay)
            data.recover.timer=math.min(dbRound(data.recover.timer*delay),200)
        end,
        StandUp=function(data,delay)
            data.standup.timer=math.min(dbRound(data.standup.timer*delay),200)
        end,
        LieDown=function(data,delay)
            data.liedown.timer=math.min(dbRound(data.liedown.timer*delay),200)        
        end,
        Job2=function(data,delay)
            data.job2.timer=math.min(dbRound(data.job2.timer*delay),200)
        end,
        PushObject=function(data,delay)
            data.pushobject.timer=math.min(dbRound(data.pushobject.timer*delay),200)
        end,
        SuckBlood=function(data,delay)
            data.suckblood.timer=math.min(dbRound(data.suckblood.timer*delay),200)        
        end
    }
    local unit_action_type=df.unit_action_type
    local thisAmount=ki.get_ki_investment(unit_id)
    local thisDelay=kiAmount/thisAmount
    local action_func=action_actions[unit_action_type[action.type]]
    if action_func then action_func(action.data,thisDelay) end
end

local function unitHasSyndrome(u,s_name)
    for k,syn in ipairs(u.syndromes.active) do
        if df.syndrome.find(syn.type).syn_name==s_name then return true end
    end
    return false
end

dfhack.script_environment('modtools/putnam_events').onUnitAction.ki_actions=function(unit_id,action)
    if not unit_id or not action then print('Something weird happened! ',unit_id,action) return false end
    if action.type == df.unit_action_type.Attack then
        local unit = df.unit.find(unit)
        local enemy=df.unit.find(attack.target_unit_id)
        local attack=action.data.attack
        local enemyKiInvestment,enemyKiType=ki.get_ki_investment(attack.target_unit_id)
        local kiInvestment,kiType=ki.get_ki_investment(unit_id)
        local sparring = action.data.attack.flags.spar_report
        transformation.transform_ai(unit_id,kiInvestment,enemyKiInvestment, sparring)
        transformation.transform_ai(enemy.id,enemyKiInvestment,kiInvestment, sparring)
        transformation.transformations_on_attack(unit,enemy,attack)
        transformation.transformations_on_attacked(unit,enemy,attack)
        if kiInvestment>0 then
            enemyKiInvestment=math.max(enemyKiInvestment,1)
            local kiRatio=kiInvestment/enemyKiInvestment
            local worldKiMode=ki.getWorldKiMode()
            if worldKiMode=='bttl' then
                kiInvestment=enemyKiType<kiType-1 and kiInvestment or kiInvestment/enemyKiInvestment
            else
                if kiType==0 and enemyKiType==1 then
                    if kiRatio<100 then
                        attack.attack_accuracy=0
                    else
                        kiRatio=kiRatio/1000 --you need to be WAY stronger to hit them and even stronger to do any damage
                    end
                end
            end
            if attack.flags.lightly_tap or (isAdventurer(unit) and dfhack.persistent.save{key='ADV_HOLDING_BACK'}.ints[1]==1) then 
                kiRatio=math.min(kiRatio,1) 
            end
            attack.attack_velocity=math.min(math.floor(attack.attack_velocity*math.sqrt(kiRatio)+.5),2000000000)
            attack.attack_accuracy=math.min(math.floor(attack.attack_accuracy*math.sqrt(kiRatio)+.5),2000000000)
        else
            attack.attack_velocity=math.max(attack.attack_velocity-enemyKiInvestment,0)
        end
        local caste_id=df.creature_raw.find(enemy.race).caste[enemy.caste].caste_id
        if caste_id=='GLACIUS' and kiInvestment<35000000 then
            unit.status2.body_part_temperature[attack.attack_body_part_id].whole=9510 --approximately absolute zero
            attack.attack_velocity=0
        elseif caste_id=='CRYSTALLOS' and kiType<4 then
            unit.status2.body_part_temperature[attack.attack_body_part_id].whole=9001 --over 9000, but also about -281 kelvins
        end
    end
end

local syndrome_function={}

syndrome_function['void banisher']=function(unit_id)
    local ki=dfhack.script_environment('dragonball/ki')
    local unit=df.unit.find(unit_id)
    transformation.transform_ai(unit_id,ki.get_ki_investment(unit_id),500000000,1)
    if ki.get_ki_investment(unit_id)<500000000 then
        unit.animal.vanish_countdown=2
    end
end

syndrome_function['void summoner']=function(unit_id)
    local ki=dfhack.script_environment('dragonball/ki')
    local unit=df.unit.find(unit_id)
    transformation.transform_ai(unit_id,ki.get_ki_investment(unit_id),24000000000,1)
    unit.body.blood_count=math.max(0,math.min(unit.body.blood_count,unit.body.blood_count*(ki.get_ki_investment(unit_id)/24000000000)))
end

syndrome_function['cell absorbed']=function(unit_id)
    dfhack.run_script('dragonball/cell_absorb',unit_id)
end

syndrome_function['kronos time stopped']=function(unit_id)
    local action_actions={
        Move=function(data)
            data.move.timer=1200
        end,
        Attack=function(data)
            if data.attack.timer1>0 then
                data.attack.timer1=1200
            else
                data.attack.timer2=1200
            end
        end,
        HoldTerrain=function(data)
            data.holdterrain.timer=1200
        end,
        Climb=function(data)
            data.climb.timer=1200
        end,
        --talking, of course, is a free action
        Unsteady=function(data)
            data.unsteady.timer=1200
        end,
        Recover=function(data)
            data.recover.timer=1200
        end,
        StandUp=function(data)
            data.standup.timer=1200
        end,
        LieDown=function(data)
            data.liedown.timer=1200
        end,
        Job2=function(data)
            data.job2.timer=1200
        end,
        PushObject=function(data)
            data.pushobject.timer=1200
        end,
        SuckBlood=function(data)
            data.suckblood.timer=1200        
        end
    }
    for k,v in ipairs(df.global.world.units.active) do
        if v.id~=unit_id then
            for _,action in ipairs(v.actions) do
                local func=action_actions[df.action_type[action.type]]
                if func then func(action.data) end
            end
        end
    end
end

syndrome_function['hypocrisy shot']=function(unit_id)
    local conflicts={
        ROMANCE={{'LOVE_PROPENSITY',1}},
        MERRIMENT={{'CHEER_PROPENSITY',1}},
        SELF_CONTROL={{'IMMODERATION',-1}},
        TRANQUILITY={{'VIOLENT',-1},{'EXCITEMENT_SEEKING',-1}},
        MARTIAL_PROWESS={{'VIOLENT',1}},
        PERSEVERENCE={{'PERSEVERENCE',1}},
        HARMONY={{'DISCORD',-1},{'FRIENDLINESS',1}},
        FRIENDSHIP={{'FRIENDLINESS',1}},
        DECORUM={{'POLITENESS',1}},
        POWER={{'CRUELTY',1}},
        STOICISM={{'PRIVACY',1}},
        ALTRUISM={{'SACRIFICE',1}},
        LAW={{'DUTIFULNESS',1}},
        LOYALTY={{'DUTIFULNESS',1}},
        INDEPENDENCE={{'DUTIFULNESS',-1}},
        ARTWORK={{'ART_INCLINED',-1},{'NATURE',-1}}
    }
    local unit=df.unit.find(unit_id)
    local damageTotal=0
    local personality=unit.status.current_soul.personality
    for key,value --[[HA!]] in pairs(personality.values) do
        local conflict=conflicts[df.value_type[value.type]]
        if conflict then
            for _,vv in conflict do
                local trait=(personality.traits[vv[1]]-50)*vv[2]
                damageTotal=damageTotal+math.abs(trait-value.strength)
            end
        end
    end
    unit.body.blood_count=math.floor(unit.body.blood_count/damageTotal) --until I can better inflict wounds through DFHack...
end

eventful.onSyndrome.dragonball=function(unit_id,syndrome_id)
    local syndrome=df.syndrome.find(syndrome_id)
    local func=syndrome_function[syndrome.syn_name]
    if func then func(unit_id) end
end

eventful.onUnitDeath.immortal_db=function(unit_id)
    if dfhack.persistent.get('DRAGONBALL_IMMORTAL/'..unit_id) then
        dfhack.run_script('full-heal','-unit',unit_id,'-r')
    end
end

local special_unit_death_classes={}

special_unit_death_classes['HADES']=function(unit_id)
    local rng=dfhack.random.new()
    if rng:random(5)~=0 then dfhack.run_script('full-heal','-unit',unit_id,'-r')
    end
end

special_unit_death_classes['KRONOS']=function(unit_id)
    local rng=dfhack.random.new()
    if rng:random(4)~=0 then dfhack.run_script('full-heal','-unit',unit_id,'-r')
    end
end

eventful.onUnitDeath.special_unit_death_db=function(unit_id)
    local unit=df.unit.find(unit_id)
    local caste=df.creature_raw.find(unit.race).caste[unit.caste]
    for _,c_class in ipairs(caste.creature_class) do
        local func=special_unit_death_classes[c_class.value]
        if func then func(unit_id) end
    end
end

special_unit_attack_castes={}

special_unit_attack_castes['GERO']=function(attackerId,defenderId,woundId)
    local defender=df.unit.find(defenderId)
    local attacker=df.unit.find(attackerId)
    defender.counters2.exhaustion=defender.counters2.exhaustion+1000
    attacker.counters2.exhaustion=math.max(attacker.counters2.exhaustion-1000,0)
end

special_unit_attack_castes['RAPTOR']=function(attackerId,defenderId,woundId)
    local defender=df.unit.find(defenderId)
    local attacker=df.unit.find(attackerId)
    defender.counters2.exhaustion=defender.counters2.exhaustion+2000
    attacker.counters2.exhaustion=math.max(attacker.counters2.exhaustion-2000,0)
end

eventful.onUnitAttack.special_unit_attack_db=function(attackerId,defenderId,woundId)
    local attacker=df.unit.find(attackerId)
    local caste_name=df.creature_raw.find(attacker.race).caste[attacker.caste].caste_id
    local caste_func=special_unit_attack_castes[caste_name]
    if caste_func then caste_func(attackerId,defenderId,woundId) end
end

local function getWound(unit,woundId)
    for k,wound in ipairs(unit.body.wounds) do
        if wound.id==woundId then return wound end
    end
end

eventful.onUnitAttack.zenkai=function(attackerId,defenderId,woundId)
    local attacker=df.unit.find(attackerId)
    local defender=df.unit.find(defenderId)
    local wound=getWound(defender,woundId)
    if not wound then return false end
    local zenkaiBoost=0
    for k,v in ipairs(wound.parts) do
        local curBoost=v.contact_area*math.max(1,v.cur_penetration_perc)
        curBoost=curBoost*(v.flags1.artery and 4 or 1)
        curBoost=curBoost*(v.flags1.major_artery and 20 or 1)
        zenkaiBoost=zenkaiBoost+curBoost
    end
    zenkaiBoost=zenkaiBoost*(wound.flags.mortal_wound and 10 or 1)
    zenkaiBoost=zenkaiBoost*(wound.flags.severed_part and 10 or 1)
    local zenkai_persist=dfhack.persistent.save{key="DRAGONBALL/ZENKAI/"..defenderId}
    zenkai_persist.ints[1]=math.max(0,zenkai_persist.ints[1])+zenkaiBoost
    zenkai_persist:save()
end

local super_saiyan_trigger=dfhack.script_environment('dragonball/super_saiyan_trigger')

has_whis_event_called_this_round=false

function regularUnitChecks(unit)
    if not unit or not df.unit.find(unit.id) then return false end
    transformation.transformation_tick(unit.id)
    if not unitInCombat(unit) or unit.counters.unconscious>0 then
        transformation.revert_to_base(unit.id)
    end
end

function lowerPriorityChecks(unit)
    if not unit or not df.unit.find(unit.id) then return false end
    super_saiyan_trigger.runSuperSaiyanChecks(unit.id)
    if unitUndergoingSSJEmotion(unit) then
        super_saiyan_trigger.runSuperSaiyanChecksExtremeEmotion(unit.id)
    end
    if unitHasCreatureClass(unit,'ZENKAI') and not unitInDeadlyCombat(unit) then
        doZenkai(unit)
    end
    renameUnitIfApplicable(unit)
    setupNaturalTransformations(unit)
    --12 years of training, approx.
    if ((dfhack.units.isDwarf(unit) and dfhack.units.isCitizen(unit)) or isAdventurer(unit)) and getPowerLevel(unit)>900000000 and not has_whis_event_called_this_round then
        dfhack.run_script('dragonball/whis_event')
        has_whis_event_called_this_round=true
    end
    if dfhack.persistent.get('DRAGONBALL_IMMORTAL/'..unit.id) then
        dfhack.run_script('full-heal','-unit',unit.id,'-r')
    end    
end

function onStateChange(op)
    if op==SC_MAP_LOADED or op==SC_WORLD_LOADED then
        local putnamEvents=dfhack.script_environment('modtools/putnam_events')
        putnamEvents.enableEvent(putnamEvents.eventTypes.ON_ACTION)
        dfhack.run_command('script',SAVE_PATH..'/raw/sparking_onload.txt')
        local putnamScheduler = dfhack.script_environment('modtools/putnam_scheduler')
        putnamScheduler.add_to_schedule(df.global.world.units.all,regularUnitChecks,100)
        putnamScheduler.add_to_schedule(df.global.world.units.all,lowerPriorityChecks,1)
        putnamScheduler.start_scheduler()
        eventful.enableEvent(eventful.eventType.UNIT_ATTACK,2)
        eventful.enableEvent(eventful.eventType.UNIT_DEATH,2)
        eventful.enableEvent(eventful.eventType.SYNDROME,2)
        for k,v in ipairs(df.global.world.units.all) do
            fixStrengthBug(v)
        end
        if dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'}).ints[2]==1 then require('repeat-util').scheduleEvery('shadow dragons',100,'ticks',dfhack.script_environment('dragonball/shadow_dragon').shadow_dragon_loop) end
    end
end
