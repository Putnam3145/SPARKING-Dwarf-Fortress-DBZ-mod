local utils=require('utils')
local function getPowerLevel(saiyan)
    return saiyan.body.physical_attrs.ENDURANCE.value+saiyan.status.current_soul.mental_attrs.FOCUS.value+saiyan.status.current_soul.mental_attrs.WILLPOWER.value
end

local function unitHasSyndrome(u,s_name)
    for k,syn in ipairs(u.syndromes.active) do
        if df.syndrome.find(syn.type).syn_name==s_name then return true end
    end
    return false
end

local function unitHasSyndromeClass(u,s_class)
    for k,syn in ipairs(u.syndromes.active) do
        for _,syn_class in ipairs(df.syndrome.find(syn.type).syn_class) do
            if syn_class.value==s_class then return true end
        end
    end
    return false
end

validArgs = validArgs or utils.invert({
 'unit'
})

local args = utils.processArgs({...}, validArgs)

function runSuperSaiyanChecksExtremeEmotion(unit_id)
    local unit = df.unit.find(unit_id)
    local powerLevel=getPowerLevel(unit)

    if powerLevel>75000 then
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 3','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>25000 then
        if not unitHasSyndrome(unit,'can super saiyan 2') then
            dfhack.run_script('modtools/add-syndrome','-syndrome','Super Saiyan 2','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan 2 in a bout of extreme emotion!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 2','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>12500 and unit.status.current_soul.personality.traits.ANGER_PROPENSITY>90 and unit.status.current_soul.personality.traits.HATE_PROPENSITY>60 then
        if not unitHasSyndrome(unit,'can legendary super saiyan') then
            dfhack.run_script('modtools/add-syndrome','-syndrome','Legendary Super Saiyan','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into the Legendary Super Saiyan in a bout of extreme emotion!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can legendary super saiyan','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>10000 then
        if not unitHasSyndrome(unit,'can super saiyan') then
            dfhack.run_script('modtools/add-syndrome','-syndrome','Super Saiyan','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan in a bout of extreme emotion!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
end

function runSuperSaiyanChecks(unit_id)
    local unit=df.unit.find(unit_id)
    local powerLevel=getPowerLevel(unit)
    if unitHasSyndromeClass(unit,'SUPER_SAIYAN_GOD') and unitHasSyndromeClass(unit,'HAS_GONE_SUPER_SAIYAN_4') then
        if not unitHasSyndrome(unit,'can super saiyan god super saiyan 4') then
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a super saiyan god super saiyan 4!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan god super saiyan 4','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>75000 then
        if not unitHasSyndrome(unit,'can super saiyan 3') then
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a super saiyan 3!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 3','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>37500 then
        if not unitHasSyndrome(unit,'can super saiyan 2') then
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a super saiyan 2!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan 2','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>25000 and unit.status.current_soul.personality.traits.ANGER_PROPENSITY>90 and unit.status.current_soul.personality.traits.HATE_PROPENSITY>60 then
        if not unitHasSyndrome(unit,'can legendary super saiyan') then
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into the legendary super saiyan!',11)            
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can legendary super saiyan','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
    if powerLevel>15000 then
        if not unitHasSyndrome(unit,'can super saiyan') then
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a super saiyan!',11)
        end
        dfhack.run_script('modtools/add-syndrome','-syndrome','can super saiyan','-resetPolicy','DoNothing','-target',unit_id,'-skipImmunities')
    end
end
if args.unit then
    runSuperSaiyanChecksExtremeEmotion(args.unit)
end