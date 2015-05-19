
function getMatFilter(itemtype)
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
  --print(itemTypes[df.item_type[itemtype]])
  return itemTypes[df.item_type[itemtype]] or getRestrictiveMatFilter(itemtype)
end

function getRestrictiveMatFilter(itemType)
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
    return (mat.flags.IS_METAL or mat.flags.SOAP or mat.id=='COAL')
   end
   
  }
 for k,v in ipairs({'SHOES','SHIELD','HELM','GLOVES'}) do
    itemTypes[v]=itemTypes.ARMOR
 end
 for k,v in ipairs({'EARRING','BRACELET','CHAIN'}) do
    itemTypes[v]=itemTypes.AMULET
 end
 itemTypes.BOULDER=itemTypes.ROCK
 --print(itemType)
 --print(itemTypes[df.item_type[itemType]])
 return itemTypes[df.item_type[itemType]] or itemTypes.INSTRUMENT
end
 
local script=require('gui.script')
 
function showItemPrompt(text,item_filter,hide_none)
 require('gui.materials').ItemTypeDialog{
  frame_title='Materialization',
  prompt=text,
  item_filter=item_filter,
  hide_none=hide_none,
  on_select=script.mkresume(true),
  on_cancel=script.mkresume(false),
  on_close=script.qresume(nil)
 }:show()
 
 return script.wait()
end
 
function showMaterialPrompt(title, prompt, filter, inorganic, creature, plant) --the one included with DFHack doesn't have a filter or the inorganic, creature, plant things available
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

function materialization_item_filter(itype,subtype,def) 
    return dfhack.items.getItemBaseValue(itype,subtype,0,dfhack.matinfo.find('SLATE').index)<20
end

function materialization_material_filter(mat,parent,typ,idx)
    if not getMatFilter(itemtype)(mat,parent,typ,idx) then return false end
    if dfhack.items.getItemBaseValue(itemtype,itemsubtype,typ,idx)>20 then
        return false
    end
    if typ==0 then
        local inorganic=dfhack.matinfo.decode(typ,idx).inorganic
        return not (inorganic.flags.SPECIAL)
    end
    return true
end

function materialize(unit)
    script.start(function()
    ::itemprompt:: --wait what does that mean
    itemok,itemtype,itemsubtype=showItemPrompt('Choose item to make',materialization_item_filter,true)
    if not itemok then return end
    ::matprompt::
    local matok,mattype,matindex=showMaterialPrompt('Materialization','Choose the material',materialization_material_filter,true,true,true)
    if not matok then goto itemprompt end --nooooooo
    local cost=dfhack.items.getItemBaseValue(itemtype,itemsubtype,mattype,matindex)
    repeat amountok,amount=script.showInputPrompt('Materialization','How many do you want?',COLOR_LIGHTGREEN) until (tonumber(amount) or not amountok)
    if not amountok then goto matprompt end
    if df.item_type.attrs[itemtype].is_stackable then
        local proper_item=df.item.find(dfhack.items.createItem(itemtype, itemsubtype, mattype, matindex, unit))
        proper_item:setStackSize(amount)
    else
        for i=1,amount do
            dfhack.items.createItem(itemtype, itemsubtype, mattype, matindex, unit)
        end
    end
    end)
end

utils=require('utils')

validArgs = validArgs or utils.invert({
 'unit'
})

args = utils.processArgs({...}, validArgs)

materialize(df.unit.find(args.unit))