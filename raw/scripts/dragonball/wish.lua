local function getPowerLevel(saiyan)
    local focus = saiyan.status.current_soul.mental_attrs.FOCUS.value
    local endurance = saiyan.body.physical_attrs.ENDURANCE.value
    local willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value
    return focus+willpower+endurance
end

local function getGenderString(gender)
 local genderStr
 if gender==0 then
  genderStr=string.char(12)
 elseif gender==1 then
  genderStr=string.char(11)
 else
  return ""
 end
 return string.char(40)..genderStr..string.char(41)
end

local function getCreatureList()
 local crList={}
 for k,cr in ipairs(df.global.world.raws.creatures.alphabetic) do
  for kk,ca in ipairs(cr.caste) do
   local str=ca.caste_name[0]
   str=str..' '..getGenderString(ca.gender)
   table.insert(crList,{str,nil,ca})
  end
 end
 return crList
end

local function getRestrictiveMatFilter(itemType)
 local itemTypes={
   WEAPON=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_WEAPON or mat.flags.ITEMS_WEAPON_RANGED)
   end,
   AMMO=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_AMMO)
   end,
   ARMOR=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_ARMOR)
   end,
   INSTRUMENT=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_HARD)
   end,
   AMULET=function(mat,parent,typ,idx)
    return (mat.flags.ITEMS_SOFT or mat.flags.ITEMS_HARD)
   end,
   ROCK=function(mat,parent,typ,idx)
    return (mat.flags.IS_STONE)
   end,
   BOULDER=ROCK,
   BAR=function(mat,parent,typ,idx)
    return (mat.flags.IS_METAL or mat.flags.SOAP or mat.id==COAL)
   end

  }
 for k,v in ipairs({'GOBLET','FLASK','TOY','RING','CROWN','SCEPTER','FIGURINE','TOOL'}) do
  itemTypes[v]=itemTypes.INSTRUMENT
 end
 for k,v in ipairs({'SHOES','SHIELD','HELM','GLOVES'}) do
    itemTypes[v]=itemTypes.ARMOR
 end
 for k,v in ipairs({'EARRING','BRACELET'}) do
    itemTypes[v]=itemTypes.AMULET
 end
 itemTypes.BOULDER=itemTypes.ROCK
 return itemTypes[df.item_type[itemType]]
end

local function getMatFilter(itemtype)
  local itemTypes={
   SEEDS=function(mat,parent,typ,idx)
    return mat.flags.SEED_MAT
   end,
   PLANT=function(mat,parent,typ,idx)
    return mat.flags.STRUCTURAL_PLANT_MAT
   end,
   LEAVES=function(mat,parent,typ,idx)
    return mat.flags.LEAF_MAT
   end,
   MEAT=function(mat,parent,typ,idx)
    return mat.flags.MEAT
   end,
   CHEESE=function(mat,parent,typ,idx)
    return (mat.flags.CHEESE_PLANT or mat.flags.CHEESE_CREATURE)
   end,
   LIQUID_MISC=function(mat,parent,typ,idx)
    return (mat.flags.LIQUID_MISC_PLANT or mat.flags.LIQUID_MISC_CREATURE or mat.flags.LIQUID_MISC_OTHER)
   end,
   POWDER_MISC=function(mat,parent,typ,idx)
    return (mat.flags.POWDER_MISC_PLANT or mat.flags.POWDER_MISC_CREATURE)
   end,
   DRINK=function(mat,parent,typ,idx)
    return (mat.flags.ALCOHOL_PLANT or mat.flags.ALCOHOL_CREATURE)
   end,
   GLOB=function(mat,parent,typ,idx)
    return (mat.flags.STOCKPILE_GLOB)
   end,
   WOOD=function(mat,parent,typ,idx)
    return (mat.flags.WOOD)
   end,
   THREAD=function(mat,parent,typ,idx)
    return (mat.flags.THREAD_PLANT)
   end,
   LEATHER=function(mat,parent,typ,idx)
    return (mat.flags.LEATHER)
   end
  }
  return itemTypes[df.item_type[itemtype]] or getRestrictiveMatFilter(itemtype)
end

local function createItem(mat,itemType,quality,creator,description)
 local item=df.item.find(dfhack.items.createItem(itemType[1], itemType[2], mat[1], mat[2], creator))
 if pcall(function() print(item.quality) end) then
  item.quality=quality-1
 end
 if df.item_type[itemType[1]]=='SLAB' then
  item.description=description
 end
end

local function qualityTable()
 return {{'None'},
 {'-Well-crafted-'},
 {'+Finely-crafted+'},
 {'*Superior*'},
 {string.char(240)..'Exceptional'..string.char(240)},
 {string.char(15)..'Masterwork'..string.char(15)}
 }
end

local script=require('gui.script')

local function showItemPrompt(text,item_filter,hide_none)
 require('gui.materials').ItemTypeDialog{
  prompt=text,
  item_filter=item_filter,
  hide_none=hide_none,
  on_select=script.mkresume(true),
  on_cancel=script.mkresume(false),
  on_close=script.qresume(nil)
 }:show()

 return script.wait()
end

local function showMaterialPrompt(title, prompt, filter, inorganic, creature, plant) --the one included with DFHack doesn't have a filter or the inorganic, creature, plant things available
 require('gui.materials').MaterialDialog{
  frame_title = title,
  prompt = prompt,
  mat_filter = filter,
  use_inorganic = inorganic,
  use_creature = creature,
  use_plant = plant,
  on_select = script.mkresume(true),
  on_cancel = script.mkresume(false),
  on_close = script.qresume(nil)
 }:show()

 return script.wait()
end

local function usesCreature(itemtype)
 typesThatUseCreatures={REMAINS=true,FISH=true,FISH_RAW=true,VERMIN=true,PET=true,EGG=true,CORPSE=true,CORPSEPIECE=true}
 return typesThatUseCreatures[df.item_type[itemtype]]
end

local function getCreatureRaceAndCaste(caste)
 return df.global.world.raws.creatures.list_creature[caste.index],df.global.world.raws.creatures.list_caste[caste.index]
end

local function db_filter(itype,subtype,def)
    return not(df.item_type[itype]=='CORPSE' or df.item_type[itype]=='FOOD' or (def and def.id=='DRAGONBALL'))
end

local function hackWish(unit) --I HAD TO INCLUDE THE WHOLE THING SORRY
  local amountok, amount
  local matok,mattype,matindex,matFilter
  local itemok,itemtype,itemsubtype=showItemPrompt('What item do you want?',db_filter,true)
  matFilter=getMatFilter(itemtype)
  if not usesCreature(itemtype) then
   matok,mattype,matindex=showMaterialPrompt('Wish','And what material should it be made of?',matFilter)
  else
   local creatureok,useless,creatureTable=script.showListPrompt('Wish','What creature should it be?',COLOR_LIGHTGREEN,getCreatureList())
   mattype,matindex=getCreatureRaceAndCaste(creatureTable[3])
  end
  local qualityok,quality=script.showListPrompt('Wish','What quality should it be?',COLOR_LIGHTGREEN,qualityTable())
  local description
  if df.item_type[itemtype]=='SLAB' then
   local descriptionok
   descriptionok,description=script.showInputPrompt('Slab','What should the slab say?',COLOR_WHITE)
  end
  repeat amountok,amount=script.showInputPrompt('Wish','How many do you want? (numbers only!)',COLOR_LIGHTGREEN) until tonumber(amount) or not amountok
  if mattype and itemtype and amountok then
   if df.item_type.attrs[itemtype].is_stackable then
    local proper_item=df.item.find(dfhack.items.createItem(itemtype, itemsubtype, mattype, matindex, unit))
    proper_item:setStackSize(amount)
   else
    for i=1,amount do
     dfhack.items.createItem(itemtype, itemsubtype, mattype, matindex, unit)
    end
   end
   return true
  end
  return false
end

local function immortalityWish(adventure)
    if not adventure then
        local citizen_list={}
        for k,v in ipairs(df.global.world.units.active) do
            if dfhack.units.isCitizen(v) and dfhack.units.isAlive(v) and not dfhack.persistent.get('DRAGONBALL_IMMORTAL/'..v.id) then
                table.insert(citizen_list,{dfhack.TranslateName(dfhack.units.getVisibleName(v)),nil,v.id})
            end
        end
        table.sort(citizen_list,function(a,b) return getPowerLevel(df.unit.find(a[3]))>getPowerLevel(df.unit.find(b[3])) end)
        local citizen_okay,_,citizen_table=script.showListPrompt('Wish','Which citizen do you wish to make immortal?',COLOR_LIGHTGREEN,citizen_list)
        if citizen_okay then
            dfhack.persistent.save({key='DRAGONBALL_IMMORTAL/'..citizen_table[3]})
            return true
        end
        return false
    else
        dfhack.persistent.save({key='DRAGONBALL_IMMORTAL/'..df.global.world.units.active[0].id})
        return true
    end
end


local function ressurectionWish(pos)
    local deathWasUnnatural={}
    deathWasNatural[df.death_type.OLD_AGE]=true
    deathWasNatural[df.death_type.HUNGER]=true
    deathWasNatural[df.death_type.THIRST]=true
    local dead_people_list={}
    for k,v in ipairs(df.global.world.units.all) do
        if dfhack.units.isDead(v) and not deathWasNatural[v.counters.death_cause] then
            table.insert(dead_people_list,{dfhack.TranslateName(dfhack.units.getVisibleName(v))..', '..df.creature_raw.find(v.id).caste[v.caste].caste_name[0],nil,v.id})
        end
    end
    table.sort(dead_people_list,function(a,b) return (a and b) and getPowerLevel(df.unit.find(a[3]))>getPowerLevel(df.unit.find(b[3])) or false end)
    local dead_okay,_,dead_table=script.showListPrompt('Wish','Who do you wish to revive?',COLOR_LIGHTGREEN,dead_people_list)
    if dead_okay then
        dfhack.run_script('full-heal','-r','-unit',dead_table[3])
        local unit=df.unit.find(dead_table[3])
        if unit.pos.x==-30000 then
            dfhack.run_script('teleport','-unit',dead_table[3],'-x',pos.x-1,'-y',pos.y,'-z',pos.z)
        end
        return true
    end
    return false
end

function makeAWish(unit,adventure)
    if not unit then error('Something weird happened! No unit found!') end
    local last_wish_found=dfhack.persistent.save({key='DRAGONBALL_LAST_WISH_TIME'})
    if last_wish_found.ints[1]==df.global.cur_year or (last_wish_found.ints[1]==df.global.cur_year-1 and last_wish_found.ints[2]<df.global.cur_year_tick) then
        dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},unit.pos,'The dragon balls still need to recharge!',COLOR_LIGHTGREEN)
        return false
    end
    local script=require('gui.script')
    script.start(function()
    for i=1,3 do
        local okay=true
        repeat
            okay,selection=script.showListPrompt('Wish','Choose your wish.',COLOR_GREEN,{'Items','Immortality','Ressurection'})
            if selection==1 then
                okay=hackWish(unit)
            elseif selection==2 then
                okay=immortalityWish(adventure)
            else
                okay=ressurectionWish(unit.pos)
            end
        until okay
    end
    local wishes=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    wishes.ints[1]=wishes.ints[1]+1
    wishes:save()
    last_wish_found.ints[1]=df.global.cur_year
    last_wish_found.ints[2]=df.global.cur_year_tick
    if wishes.ints[1]>9 and wishes.ints[2]<1 then
        dfhack.script_environment('dragonball/shadow_dragon').init_shadow_dragons()
        wishes.ints[2]=1
        wishes:save()
    end
end)
end

utils = require('utils')

validArgs = validArgs or utils.invert({
 'unit',
 'adventure'
})

local args = utils.processArgs({...}, validArgs)

makeAWish(args.unit and df.unit.find(args.unit) or args.adventure and df.global.world.units.active[0],args.adventure)