local utils=require('utils')
local function getPowerLevel(saiyan)
    local strength = saiyan.body.physical_attrs.STRENGTH.value/3550
    local endurance = saiyan.body.physical_attrs.ENDURANCE.value/1000
    local toughness = saiyan.body.physical_attrs.TOUGHNESS.value/2250
    local spatialsense = saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1500
    local kinestheticsense = saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
    local willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value/1000
    return (strength+endurance+toughness+spatialsense+kinestheticsense+willpower)
end
local function unitHasSyndrome(u,s_name)
    for k,syn in ipairs(u.syndromes.active) do
        if df.global.world.raws.syndromes.all[syn.type].syn_name==s_name then return true end
    end
    return false
end

validArgs = validArgs or utils.invert({
 'unit'
})

local args = utils.processArgs({...}, validArgs)

local unit = df.unit.find(args.unit)

local powerLevel=getPowerLevel(unit)

if powerLevel>100 then
    dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 3','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
end
if powerLevel>50 then
    if not unitHasSyndrome(unit,'can super saiyan 2') then
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 2','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
        dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan 2 in a bout of extreme emotion!',11)
    end
    dfhack.run_script('modtools/add-syndrome','-syndrome','Super Saiyan 2','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
end
if powerLevel>20 then
    if not unitHasSyndrome(unit,'can super saiyan') then
        dfhack.run_script('modtools/add-syndrome','-syndrome','Super Saiyan','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
        dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan in a bout of extreme emotion!',11)
    end
    dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan','-resetPolicy','DoNothing','-target',args.unit,'-skipImmunities')
end