local function heal_and_revive_unit(unit) --literally just full-heal copied into a function
    if unit then
        if unit.flags1.dead then
            --print("Resurrecting...")
            unit.flags2.slaughter = false
            unit.flags3.scuttle = false
        end
        unit.flags1.dead = false
        unit.flags2.killed = false
        unit.flags3.ghostly = false
        for _,corpse in ipairs(df.global.world.items.other.CORPSE) do
            if corpse.unit_id==unit.id then
                corpse.flags.garbage_collect=true
                corpse.flags.forbid=true
                corpse.flags.hidden=true
            end
        end
            --unit.unk_100 = 3
        --print("Erasing wounds...")
        while #unit.body.wounds > 0 do
            unit.body.wounds:erase(#unit.body.wounds-1)
        end
        unit.body.wound_next_id=1

        --print("Refilling blood...")
        unit.body.blood_count=unit.body.blood_max

        --print("Resetting grasp/stand status...")
        unit.status2.limbs_stand_count=unit.status2.limbs_stand_max
        unit.status2.limbs_grasp_count=unit.status2.limbs_grasp_max

        --print("Resetting status flags...")
        unit.flags2.has_breaks=false
        unit.flags2.gutted=false
        unit.flags2.circulatory_spray=false
        unit.flags2.vision_good=true
        unit.flags2.vision_damaged=false
        unit.flags2.vision_missing=false
        unit.flags2.breathing_good=true
        unit.flags2.breathing_problem=false

        unit.flags2.calculated_nerves=false
        unit.flags2.calculated_bodyparts=false
        unit.flags2.calculated_insulation=false
        unit.flags3.compute_health=true

        --print("Resetting counters...")
        unit.counters.winded=0
        unit.counters.stunned=0
        unit.counters.unconscious=0
        unit.counters.webbed=0
        unit.counters.pain=0
        unit.counters.nausea=0
        unit.counters.dizziness=0

        unit.counters2.paralysis=0
        unit.counters2.fever=0
        unit.counters2.exhaustion=0
        unit.counters2.hunger_timer=0
        unit.counters2.thirst_timer=0
        unit.counters2.sleepiness_timer=0
        unit.counters2.vomit_timeout=0

        --print("Resetting body part status...")
        local v=unit.body.components
        for i=0,#v.nonsolid_remaining - 1,1 do
            v.nonsolid_remaining[i] = 100    -- percent remaining of fluid layers (Urist Da Vinci)
        end

        v=unit.body.components
        for i=0,#v.layer_wound_area - 1,1 do
            v.layer_status[i].whole = 0        -- severed, leaking layers (Urist Da Vinci)
            v.layer_wound_area[i] = 0        -- wound contact areas (Urist Da Vinci)
            v.layer_cut_fraction[i] = 0        -- 100*surface percentage of cuts/fractures on the body part layer (Urist Da Vinci)
            v.layer_dent_fraction[i] = 0        -- 100*surface percentage of dents on the body part layer (Urist Da Vinci)
            v.layer_effect_fraction[i] = 0        -- 100*surface percentage of "effects" on the body part layer (Urist Da Vinci)
        end

        v=unit.body.components.body_part_status
        for i=0,#v-1,1 do
            v[i].on_fire = false
            v[i].missing = false
            v[i].organ_loss = false
            v[i].organ_damage = false
            v[i].muscle_loss = false
            v[i].muscle_damage = false
            v[i].bone_loss = false
            v[i].bone_damage = false
            v[i].skin_damage = false
            v[i].motor_nerve_severed = false
            v[i].sensory_nerve_severed = false
        end

        if unit.job.current_job and unit.job.current_job.job_type == df.job_type.Rest then
            --print("Wake from rest -> clean self...")
            unit.job.current_job = df.job_type.CleanSelf
        end
    end
end

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
        if (df.global.gamemode==1 and u.race==df.global.world.units.active[0].race) or (df.global.gamemode==0 and dfhack.units.isDwarf(u) and dfhack.units.isCitizen(u)) then table.insert(tbl,{name,nil,u}) end
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
    strength.value=math.min(strength.value,1000000)
end

local function checkOverflows(unit)
    for _,attribute in ipairs(unit.body.physical_attrs) do
        attribute.value=fixOverflow(attribute.value)
    end
    for _,soul in ipairs(unit.status.souls) do --soul[0] is a pointer to the current soul
        for _,attribute in ipairs(soul.mental_attrs) do
            attribute.value=fixOverflow(attribute.value)
        end
    end
    unit.body.blood_max=fixOverflow(unit.body.blood_max)
    unit.body.blood_count=fixOverflow(unit.body.blood_count)
    fixStrengthBug(unit)
end

local function fixAllOverflows()
    for _,unit in ipairs(df.global.world.units.active) do
        checkOverflows(unit)
    end
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

local function checkIfUnitStillGravelyInjuredForZenkai(unit)
    if unit.body.blood_count>unit.body.blood_max*.75 then
        dfhack.persistent.save({key='ZENKAI_'..unit.id,value='false'})
    end
end

local function unitHasZenkaiAlready(unit,set)
    if set then 
        dfhack.persistent.save({key='ZENKAI_'..unit.id,value='true'})
    else
        if dfhack.persistent.get('ZENKAI_'..unit.id) and dfhack.persistent.get('ZENKAI_'..unit.id).value=='true' then
            checkIfUnitStillGravelyInjuredForZenkai(unit)
            return true
        end
    end
end

local function averageTo1(num,howMany)
    howMany=tonumber(howMany) or 1
    return (howMany+num)/(howMany+1)
end

dbEvents.onUnitGravelyInjured.zenkai=function(unit)
    if not unitHasCreatureClass(unit,'ZENKAI') or unitHasZenkaiAlready(unit) then return false end
    local zenkaiBoost=math.min(10,5500-unit.body.blood_count)
    local endurance=unit.body.physical_attrs.ENDURANCE
    endurance.value=math.min(dbRound(endurance.value+zenkaiBoost),endurance.max_value)
    unitHasZenkaiAlready(unit,true)
end

dbEvents.onUnitGravelyInjured.super_saiyan=function(unit)
    if df.creature_raw.find(unit.race).creature_id=='SAIYAN' then
        dfhack.run_script('dragonball/super_saiyan_trigger','-unit',unit.id)
    end
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

local function unitInDeadlyCombat(unit_id)
    local unit=df.unit.find(unit_id)
    if df.global.gamemode==df.game_mode.ADVENTURE and unit == df.global.world.units.active[0] then return true end
    if not unit.status.current_soul then return false end
    for k,v in ipairs(unit.status.current_soul.personality.emotions) do
        if (v.thought==df.unit_thought_type.Conflict or v.thought==df.unit_thought_type.JoinConflict) and math.abs(df.global.cur_year_tick-v.year_tick)<50 then return true end
    end
    return false
end

local function unitInCombat(unit)
    for k,v in pairs(unit.reports.last_year_tick) do
        if math.abs(v-df.global.cur_year_tick)%403100<100 then
            return true
        end
    end
    return false
end

has_whis_event_called_this_round=false

function regularUnitChecks(unit)
    if not unit or not df.unit.find(unit.id) then return false end
    if unit.body.blood_count<unit.body.blood_max*.75 then 
        dbEvents.onUnitGravelyInjured(unit)
    end
    checkIfUnitStillGravelyInjuredForZenkai(unit)
    checkOverflows(unit)
    local super_saiyan_trigger=dfhack.script_environment('dragonball/super_saiyan_trigger')
    super_saiyan_trigger.runSuperSaiyanChecks(unit.id)
    if unitUndergoingSSJEmotion(unit) then
        super_saiyan_trigger.runSuperSaiyanChecksExtremeEmotion(unit.id)
    end
    renameUnitIfApplicable(unit)
    transformation.transformation_ticks(unit.id)
    if not unitInCombat(unit) or unit.counters.unconscious>0 then
        transformation.revert_to_base(unit.id)
    end
    if dfhack.units.isDwarf(unit) and dfhack.units.isCitizen(unit) and getPowerLevel(unit)>49000000 and not has_whis_event_called_this_round then
        dfhack.run_script('dragonball/whis_event')
        has_whis_event_called_this_round=true
    end
end

local function checkEveryUnitRegularlyForEvents()
    has_whis_event_called_this_round=false
    for k,v in ipairs(df.global.world.units.active) do
        dfhack.timeout((k%9)+1,'ticks',function() regularUnitChecks(v) end)
    end
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
    local ki=dfhack.script_environment('dragonball/ki')
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

local ki=dfhack.script_environment('dragonball/ki')

dfhack.script_environment('modtools/putnam_events').onUnitAction.ki_actions=function(unit_id,action)
    if not unit_id or not action then print('Something weird happened! ',unit_id,action) return false end
    local kiInvestment,kiType=ki.get_ki_investment(unit_id)
    if kiInvestment>0 then
        if action.type==df.unit_action_type.Attack then
            local attack=action.data.attack
            local sparring=attack.flags[11] or attack.flags[14] --flags[11] is "is it a tap", flags[14] is "is it sparring [for reports]"
            local unit=df.unit.find(unit_id)
            local enemy=df.unit.find(attack.target_unit_id)
            local enemyKiInvestment,enemyKiType=ki.get_ki_investment(attack.target_unit_id)
            transformation.transform_ai(unit_id,kiInvestment,kiType,enemyKiInvestment,enemyKiType,sparring)
            transformation.transform_ai(enemy.id,enemyKiInvestment,enemyKiType,kiInvestment,kiType,sparring)
            transformation.transformations_on_attack(unit,enemy,attack)
            transformation.transformations_on_attacked(unit,enemy,attack)
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
            if not sparring then
                attack.attack_velocity=math.min(math.floor(attack.attack_velocity*math.sqrt(kiRatio)+.5),2000000000)
                attack.attack_accuracy=math.min(math.floor(attack.attack_accuracy*math.sqrt(kiRatio)+.5),2000000000)
                local caste_id=df.creature_raw.find(enemy.race).caste[enemy.caste].caste_id
                if caste_id=='GLACIUS' and kiInvestment<35000000 then
                    unit.status2.body_part_temperature[attack.attack_body_part_id].whole=9510 --approximately absolute zero
                    attack.attack_velocity=0
                elseif caste_id=='CRYSTALLOS' and kiType<4 then
                    unit.status2.body_part_temperature[attack.attack_body_part_id].whole=9001 --over 9000, but also about -281 kelvins
                end
            end
        end
    else
        if action.type==df.unit_action_type.Attack then
            local attack=action.data.attack
            local enemyKiInvestment=ki.get_ki_investment(attack.target_unit_id)
            local unit=df.unit.find(unit_id)
            local enemy=df.unit.find(attack.target_unit_id)
            transformation.transform_ai(unit_id,kiInvestment,kiType,enemyKiInvestment,enemyKiType)
            transformation.transform_ai(enemy.id,enemyKiInvestment,enemyKiType,kiInvestment,kiType)
            transformation.transformations_on_attack(unit,enemy,attack)
            transformation.transformations_on_attacked(unit,enemy,attack)
            attack.attack_velocity=math.max(attack.attack_velocity-enemyKiInvestment,0)
            local caste_id=df.creature_raw.find(enemy.race).caste[enemy.caste].caste_id
            if caste_id=='GLACIUS' then
                unit.status2.body_part_temperature[attack.attack_body_part_id].whole=9510
                attack.attack_velocity=0
            elseif caste_id=='CRYSTALLOS' then
                unit.status2.body_part_temperature[attack.attack_body_part_id].whole=9001
            end
        end
    end
end

local syndrome_function={}

syndrome_function['void banisher']=function(unit_id)
    local ki=dfhack.script_environment('dragonball/ki')
    local unit=df.unit.find(unit_id)
    forceSuperSaiyan(unit)
    if ki.get_ki_investment(unit_id)<500000000 then
        unit.animal.vanish_countdown=2
    end
end

syndrome_function['void summoner']=function(unit_id)
    local ki=dfhack.script_environment('dragonball/ki')
    local unit=df.unit.find(unit_id)
    forceSuperSaiyan(unit)
    unit.body.blood_count=math.max(0,math.min(unit.body.blood_count,unit.body.blood_count*(ki.get_ki_investment(unit_id)/24000000000)))
end

syndrome_function['namek regenerate']=function(unit_id)
    dfhack.run_script('full-heal','-unit',unit_id)
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
                local trait=(personality.values[vv[1]]-50)*vv[2]
                damageTotal=damageTotal+math.abs(trait-value.strength)
            end
        end
    end
    unit.body.blood_count=math.floor(unit.body.blood_count/damageTotal) --until I can better inflict wounds through DFHack...
end

eventful.onUnitDeath.immortal_db=function(unit_id)
    if dfhack.persistent.get('DRAGONBALL_IMMORTAL/'..unit_id) then
        heal_and_revive_unit(df.unit.find(unit_id))
    end
end

local special_unit_death_classes={}

special_unit_death_classes['HADES']=function(unit_id)
    local rng=dfhack.random.new()
    if rng:random(5)~=0 then heal_and_revive_unit(df.unit.find(unit_id)) end
end

special_unit_death_classes['KRONOS']=function(unit_id)
    local rng=dfhack.random.new()
    if rng:random(4)~=0 then heal_and_revive_unit(df.unit.find(unit_id)) end
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
    defender.counters2.exhaustion=defender.counters2.exhaustion+100
    attacker.counters2.exhaustion=math.max(attacker.counters2.exhaustion-100,0)
end

special_unit_attack_castes['RAPTOR']=function(attackerId,defenderId,woundId)
    local defender=df.unit.find(defenderId)
    local attacker=df.unit.find(attackerId)
    defender.counters2.exhaustion=defender.counters2.exhaustion+200
    attacker.counters2.exhaustion=math.max(attacker.counters2.exhaustion-200,0)
end

eventful.onUnitAttack.special_unit_attack_db=function(attackerId,defenderId,woundId)
    local attacker=df.unit.find(attackerId)
    local caste_name=df.creature_raw.find(attacker.race).caste[attacker.caste].caste_id
    local caste_func=special_unit_attack_castes[caste_name]
    if caste_func then caste_func(attackerId,defenderId,woundId) end
end

function onStateChange(op)
    if op==SC_MAP_LOADED or op==SC_WORLD_LOADED then
        local putnamEvents=dfhack.script_environment('modtools/putnam_events')
        putnamEvents.enableEvent(putnamEvents.eventTypes.ON_ACTION)
		dfhack.run_command('script',SAVE_PATH..'/raw/sparking_onload.txt')
        require('repeat-util').scheduleEvery('DBZ Event Check',10,'ticks',checkEveryUnitRegularlyForEvents)
        eventful.enableEvent(eventful.eventType.UNIT_ATTACK,5)
        eventful.enableEvent(eventful.eventType.UNIT_DEATH,5)
        if dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'}).ints[2]==1 then require('repeat-util').scheduleEvery('shadow dragons',100,'ticks',dfhack.script_environment('dragonball/shadow_dragon').shadow_dragon_loop) end
    end
end
