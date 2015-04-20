local function unitHasCreatureClass(unit,class)
    for _,class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if class.value == class then return true end
    end
    return false
end

local function superSaiyanGodSyndrome()
    for syn_id,syndrome in ipairs(df.global.world.raws.syndromes.all) do
        if syndrome.syn_name == "Super Saiyan God" then return syndrome end
    end
    qerror("Super saiyan god syndrome not found.")
end

local function getPowerLevel(saiyan)
    local strength = saiyan.body.physical_attrs.STRENGTH.value/3550
    local endurance = saiyan.body.physical_attrs.ENDURANCE.value/1000
    local toughness = saiyan.body.physical_attrs.TOUGHNESS.value/2250
    local spatialsense = saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1500
    local kinestheticsense = saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
    local willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value/1000
    return (strength+endurance+toughness+spatialsense+kinestheticsense+willpower)
end

local function getSuperSaiyanLevel(saiyan)
    if df.creature_raw.find(saiyan.race).creature_id~="SAIYAN" then return 0 end
    local saiyanPowerLevel=getPowerLevel(saiyan)
    return (saiyanPowerLevel>200) and 3 or (saiyanPowerLevel>100) and 2 or (saiyanPowerLevel>20) and 1 or 0
end

local function getSuperSaiyanCount()
    local superSaiyanCount = 0
    for _,unit in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(unit) and getSuperSaiyanLevel(unit)>0 then
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
    return highestUnit
end

local function combinedSaiyanPowerLevel()
    local totalPowerLevel=0
    for _,unit in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(unit) then totalPowerLevel = totalPowerLevel + getPowerLevel(unit) end
    end
    return totalPowerLevel
end

local function applySuperSaiyanGodSyndrome()
    local syndromeUtil = require 'syndrome-util'
    if df.global.gamemode==0 then
        if getSuperSaiyanCount()<6 then return nil end
        local superSaiyanGod = unitWithHighestPowerLevel()
        if superSaiyanGod and getPowerLevel(superSaiyanGod) > 400 then syndromeUtil.infectWithSyndromeIfValidTarget(superSaiyanGod,superSaiyanGodSyndrome(),syndromeUtil.ResetPolicy.DoNothing) end
    end
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
        local unitName = ii==1 and unit.name or ii==2 and unit.status.current_soul.name or df.historical_figure.find(unit.hist_figure_id).name
        unitName.first_name = nameCopy.first_name
        unitName.nickname = nameCopy.nickname
        unitName.language = nameCopy.language
        unitName.unknown = nameCopy.unknown
        for i=1,7 do
            unitName.words[i-1] = nameCopy.words[i]
            unitName.parts_of_speech[i-1] = nameCopy.parts_of_speech[i]
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
    for k,tissue in ipairs(firstBody.size_info) do
        tissue = tissue + secondBody.size_info[k]
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
    trait1.value=(totalValue>100) and 100 or totalValue
end

local function fuseUnits(unit1,unit2)
    if unit1.race~=unit2.race then
        return nil
    end
    fuseTwoNames(unit1,unit2)
    combineSoul(unit1,unit2)
    combineBody(unit1,unit2)
    combineCounters(unit1,unit2)
    unit2.flags1.dead=true
    dfhack.timeout(1,'ticks',function()
    unit2.pos.x=-30000
    unit2.pos.y=-30000
    unit2.pos.z=-30000
    end)
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

local function fixStrengthBug(unit) -- http://www.bay12games.com/dwarves/mantisbt/view.php?id=8333
    local strength = unit.body.physical_attrs.STRENGTH
    strength.value=strength.value>2000000 and 2000000 or strength.value
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

kamehamehaMat=dfhack.matinfo.find("KAMEHAMEHA_DB")

eventful.onProjItemCheckMovement.dragonball=function(projectile)
    if dfhack.matinfo.decode(projectile.item)==kamehamehaMat then 
        dfhack.maps.spawnFlow(projectile.cur_pos,3,0,kamehamehaMat.index,400)
    end
end

function add_site(size,civ,site_type,name)
    local x=(df.global.world.map.region_x+1)%16;
    local y=(df.global.world.map.region_y+1)%16;
    local minx,miny,maxx,maxy
    if(x<size) then
        minx=0
        maxx=2*size
    elseif(x+size>16) then
        maxx=16
        minx=16-2*size
    else
        minx=x-size
        maxx=x+size
    end
        
    if(y<size) then
        miny=0
        maxy=2*size
    elseif(y+size>16) then
        maxy=16
        miny=16-2*size
    else
        miny=y-size
        maxy=y+size
    end
    
    require("plugins.dfusion.adv_tools").addSite(nil,nil,maxx,minx,maxy,miny,civ,name,site_type)
end
function claimSite(reaction,unit,input_items,input_reagents,output_items,call_native)
    dialog.showInputPrompt("Site name", "Select a name for a new site:", nil,nil, dfhack.curry(add_site,1,unit.civ_id,0))
    call_native.value=false
end
eventful.registerReaction("LUA_HOOK_MAKE_SITE3x3",claimSite)

local dbEvents={
    onUnitGravelyInjured=dfhack.event.new()
}
    
function dbRound(num)
    return math.floor(num+0.5)
end

function checkIfUnitStillGravelyInjuredForZenkai(unit)
    if unit.body.blood_count>unit.body.blood_max*.75 then
        dfhack.persistent.save({key='ZENKAI_'..unit.id,value='false'})
    end
end

function unitHasZenkaiAlready(unit,set)
    if set then 
        dfhack.persistent.save({key='ZENKAI_'..unit.id,value='true'})
    else
        if dfhack.persistent.get('ZENKAI_'..unit.id) and dfhack.persistent.get('ZENKAI_'..unit.id).value=='true' then
            checkIfUnitStillGravelyInjuredForZenkai(unit)
            return true
        end
    end
end

function averageTo1(num)
    return (1+num)/2
end

dbEvents.onUnitGravelyInjured.zenkai=function(unit)
    if not unitHasCreatureClass(unit,'ZENKAI') or unitHasZenkaiAlready(unit) then return false end
    local zenkaiMultiplier=averageTo1(averageTo1(math.sqrt((unit.body.blood_max*.75)/unit.body.blood_count)))
    for k,v in ipairs(unit.body.physical_attrs) do
        v.value=dbRound(v.value*zenkaiMultiplier)
        v.max_value=dbRound(v.max_value*zenkaiMultiplier)
    end
    dfhack.script_environment('dragonball/ki').adjust_ki(math.floor(1000*zenkaiMultiplier))
    unitHasZenkaiAlready(unit,true)
end

dbEvents.onUnitGravelyInjured.super_saiyan=function(unit)
    if df.creature_raw.find(unit.race).creature_id=='SAIYAN' then
        dfhack.run_script('dragonball/super_saiyan_trigger','-unit',unit.id)
        applySuperSaiyanGodSyndrome()
    end
end

function chargeKi(unit_id)
    local ki=dfhack.script_environment('dragonball/ki')
    ki.adjust_ki(unit_id,math.ceil(ki.get_ki(unit_id)/20))
end

function checkEveryUnitRegularlyForEvents()
    for k,v in ipairs(df.global.world.units.active) do
        if v.body.blood_count<v.body.blood_max*.75 then 
            dbEvents.onUnitGravelyInjured(v)
        end
        checkIfUnitStillGravelyInjuredForZenkai(v)
        checkOverflows(v)
        chargeKi(v.id)
    end
end


dfhack.script_environment('dragonball/unit_action_check').onUnitAction.ki_actions=function(unit_id,action)
    if not unit_id or not action then print('Something weird happened! ',unit_id,action) return false end
    local ki=dfhack.script_environment('dragonball/ki')
    local kiInvestment=ki.get_ki_investment(unit_id)
    if kiInvestment>0 then
        if action.type==df.unit_action_type.Move then
            local amountOfKiLost=(action.data.move.timer-1)*10
            if amountOfKiLost>kiInvestment then
                local timerInit=action.data.move.timer --won't use the actual timer_init value since that may not be equal to current timer on check
                action.data.move.timer=action.data.move.timer-math.floor(kiInvestment/10)
                ki.adjust_ki(unit_id,(timerInit-action.data.move.timer)*-10)
            else
                ki.adjust_ki(unit_id,(action.data.move.timer-1)*-10)
                kiInvestment=kiInvestment+((action.data.move.timer-1)*-10)
                action.data.move.timer=1
                local curFatigue=action.data.move.fatigue
                action.data.move.fatigue=math.max(action.data.move.fatigue-(math.floor(kiInvestment/5)),0)
                ki.adjust_ki(unit_id,(action.data.move.fatigue-curFatigue)*5)
            end
            local ki_mat=dfhack.matinfo.find('KI')
            dfhack.maps.spawnFlow(df.unit.find(unit_id).pos,df.flow_type.MaterialGas,ki_mat.type,ki_mat.index,kiInvestment)
        elseif action.type==df.unit_action_type.Attack then
            local curKiInvestment=kiInvestment
            local attack=action.data.attack
            local prepare,recover=attack.timer1,attack.timer2
            attack.timer1=math.max(prepare-(math.floor(curKiInvestment/50)),1)
            local prepareCost=(attack.timer1-prepare)*-50
            curKiInvestment=curKiInvestment-prepareCost
            attack.timer2=math.max(recover-(math.floor(curKiInvestment/50)),0)
            local recoverCost=(attack.timer2-recover)*-50
            curKiInvestment=curKiInvestment-recoverCost
            local enemyKiInvestment=math.floor(ki.get_ki_investment(attack.target_unit_id)/2)
            attack.unk_30=attack.unk_30+(curKiInvestment-enemyKiInvestment) --unk_30 is the velocity of the attack, and yes, this will get ridiculous when you're a god
            local ki_mat=dfhack.matinfo.find('KI')
            dfhack.maps.spawnFlow(df.unit.find(unit_id).pos,df.flow_type.MaterialGas,ki_mat.type,ki_mat.index,kiInvestment+enemyKiInvestment)
            ki.adjust_ki(attack.target_unit_id,-enemyKiInvestment)
            ki.adjust_ki(unit_id,-kiInvestment)
        end
    end
end

function getSyndromeKiBoost(syndrome)
    local kiBoost,investmentFraction,kiBoostTime=false,100,5000
    for k,v in ipairs(syndrome.syn_class) do
        if v.value:find('KI_BOOST_') then
            kiBoost=tonumber(v.value:sub(10))
        elseif v.value:find('KI_INVEST_FRACTION_') then
            investmentFraction=tonumber(v.value:sub(20))
        elseif v.value:find('KI_TIME_') then
            kiBoostTime=tonumber(v.value:sub(9))
        end
    end
    return kiBoost,investmentFraction,kiBoostTime
end

eventful.onSyndrome.ki_boost=function(unit_id,syndrome_id)
    local syndrome=df.syndrome.find(syndrome_id)
    local kiBoost,investmentFraction,kiBoostTime=getSyndromeKiBoost(syndrome)
    if kiBoost then
        dfhack.run_script('dragonball/ki_boost','-unit',unit_id,'-boost',kiBoost,'-fraction',investmentFraction,'-time',kiBoostTime)
    end
end

eventful.enableEvent(eventful.eventType.SYNDROME,5)

function onStateChange(op)
    if op==SC_MAP_LOADED then
        dfhack.script_environment('dragonball/unit_action_check').enableEvent()
        require('repeat-util').scheduleEvery('DBZ Event Check',100,'ticks',checkEveryUnitRegularlyForEvents)
    end
end

dfhack.run_command('script',SAVE_PATH..'/raw/sparking_onload.txt')