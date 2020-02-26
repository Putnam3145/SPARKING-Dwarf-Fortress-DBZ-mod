local utils=require('utils')
local function getPowerLevel(unit_id)
    return dfhack.script_environment("dragonball/ki").get_max_ki_pre_boost(unit_id)
end

local transformation=dfhack.script_environment('dragonball/transformation')

local function get_S_cells(unit)
    local persist=dfhack.persistent.save{key='DRAGONBALL/S_CELLS/'..unit.id}
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is S-cells
    --ints[2] is experience with Super Saiyan 2
    --ints[3] is super saiyan anger event
    --ints[4] is trained by angel
    --ints[5] is legendary super saiyan (assigned at birth)
    local legendary_persist = dfhack.persistent.save{key='DRAGONBALL/LEGENDARY_SUPER_SAIYAN'}
    if legendary_persist.ints[1] < 0 then legendary_persist.ints[1] = -1000 end
    if (legendary_persist.ints[1] - df.global.cur_year) > 1000 and unit.ANGER_PROPENSITY > 90 then
        persist.ints[5] = 1
        legendary_persist.ints[1] = df.global.cur_year
    end
    legendary_persist:save()
    return persist:save()
end

function get_god_training(unit)
    local persist=dfhack.persistent.save{key='DRAGONBALL/GOD_TRAINING/'..unit.id}
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is blue training level
    --ints[2] is ultra instinct training
    return persist:save()
end

validArgs = validArgs or utils.invert({
 'unit'
})

local args = utils.processArgs({...}, validArgs)

function runSuperSaiyanChecksExtremeEmotion(unit_id)
    local unit = df.unit.find(unit_id)
    if df.creature_raw.find(unit.race).creature_id~='SAIYAN' then return false end
    local powerLevel=getPowerLevel(unit_id)
    local S_cells=get_S_cells(unit)
    local god_training=get_god_training(unit)
    if god_training.ints[2]>200 then --each 1 is 10 ticks, 2000 ticks (20 seconds) seems fine, since it's a very exhausting transformation
        if not transformation.get_transformation(unit_id,'Ultra Instinct') then
            transformation.add_transformation(unit_id,'Ultra Instinct')
            transformation.transform(unit_id,'Ultra Instinct',true)
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has done it! Perfected Ultra Instinct!',11)
        end
    end
    if god_training.ints[1]>3000 then
        if not transformation.get_transformation(unit_id,'Ultra Instinct "Sign"') then
            transformation.add_transformation(unit_id,'Ultra Instinct "Sign"')
            transformation.transform(unit_id,'Ultra Instinct "Sign"',true)
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' underwent a sudden transformation! Could this be Ultra Instinct?!',11)
        end
    end
    if god_training.ints[1]>1000 and S_cells.ints[1]>40000 then
        if not transformation.get_transformation(unit_id,"Beyond Super Saiyan Blue") then
            transformation.add_transformation(unit_id,"Beyond Super Saiyan Blue")
            transformation.transform(unit_id,"Beyond Super Saiyan Blue",true)
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has broken through to a new level of Super Saiyan Blue!',11)
        end
    end
    if S_cells.ints[5] == 0 then
        if powerLevel>3000000 then
            if not transformation.get_transformation(unit_id,"Super Saiyan") then
                transformation.add_transformation(unit_id,"Super Saiyan")
                transformation.transform(unit_id,"Super Saiyan",true)
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan in a bout of extreme emotion!',11)
            end
        end
        if powerLevel>56250000 then
            if not transformation.get_transformation(unit_id,"Super Saiyan 2") then
                local can_transform=transformation.add_transformation(unit_id,"Super Saiyan 2")
                if can_transform then
                    transformation.transform(unit_id,"Super Saiyan 2",true)
                    dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan 2 in a bout of extreme emotion!',11)
                end
            end
        end
        if S_cells.ints[2]>100000 and S_cells.ints[3]~=1  then
            S_cells.ints[3]=1
            S_cells:save()
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has undergone a startling transformation! This is Super Saiyan 2, but?!',11)
            transformation.transform(unit_id,"Super Saiyan 2",true)
        end
    else
        if powerLevel>100000 then
            if not transformation.get_transformation(unit_id,"Wrath State") then
                unit.counters.soldier_mood = 1
                unit.counters.soldier_mood_countdown = 1000
                transformation.add_transformation(unit_id,"Wrath State")
                transformation.transform(unit_id,"Wrath State",true)
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has undergone a strange transformation! The power of an Oozaru, but?!',11)
            end
        end
        if powerLevel>1000000 then
            if not transformation.get_transformation(unit_id,"Super Saiyan") then
                transformation.add_transformation(unit_id,"Super Saiyan")
                transformation.transform(unit_id,"Super Saiyan",true)
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into a Super Saiyan in a bout of extreme emotion!',11)
            end
        end
        if powerLevel>3000000 and transformation.get_transformation(unit_id,"Super Saiyan") then
            if not transformation.get_transformation(unit_id,"Legendary Super Saiyan") then
                transformation.add_transformation(unit_id,"Legendary Super Saiyan")
                transformation.transform(unit_id,"Legendary Super Saiyan",true)
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has transformed into the Legendary Super Saiyan in a bout of extreme emotion!',11)
            end
        end
    end
end

function runSuperSaiyanChecks(unit_id)
    local unit=df.unit.find(unit_id)
    if not unit or df.creature_raw.find(unit.race).creature_id~='SAIYAN' then return false end
    local powerLevel=getPowerLevel(unit_id)
    local S_cells=get_S_cells(unit)
    if transformation.get_transformation(unit_id,"Super Saiyan God") then
        local god_training=get_god_training(unit)
        if god_training.ints[1]>300000 and S_cells.ints[1]>40000 then
            if not transformation.get_transformation(unit_id,"Beyond Super Saiyan Blue") then
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has learned a way to go beyond Super Saiyan Blue!',11)
            end
            transformation.add_transformation(unit_id,"Beyond Super Saiyan Blue")
        end
        if not transformation.get_transformation(unit_id,"Super Saiyan Blue") then
            local can_transform=transformation.add_transformation(unit_id,"Super Saiyan Blue")
            if can_transform then
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has learned to combine Super Saiyan and Super Saiyan God into Super Saiyan Blue!',11)
            end
        end
        if not transformation.get_transformation(unit_id,"Super Saiyan God Super Saiyan 4") then
            local can_transform=transformation.add_transformation(unit_id,"Super Saiyan God Super Saiyan 4")
            if can_transform then
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has learned to combine Super Saiyan 4 and Super Saiyan God into Super Saiyan God Super Saiyan 4!',11)
            end
        end
    end
    if S_cells.ints[4]==1 and powerLevel>625000000 then
        if not transformation.get_transformation(unit_id,"Super Saiyan God") then
            dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has learned to use Super Saiyan God with the help of Whis!',11)
            transformation.add_transformation(unit_id,"Super Saiyan God")
        end
    end
    --don't worry, super saiyan 4 is still implemented, just elsewhere
    if powerLevel>625000000 then --~10 years of training
        if not transformation.get_transformation(unit_id,"Super Saiyan 3") then
            local can_transform=transformation.add_transformation(unit_id,"Super Saiyan 3")
            if can_transform then
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a super saiyan 3!',11)
            end
        end
    end
    if powerLevel>76562500 then --calculated at ~3.5 years of training
        if transformation.get_transformation(unit_id,"Legendary Super Saiyan") then
            if not transformation.get_transformation(unit_id,"Legendary Super Saiyan 2") then
                local can_transform=transformation.add_transformation(unit_id,"Legendary Super Saiyan 2")
                if can_transform then
                    dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to use the true form of Legendary Super Saiyan!',11)
                end
            end
        else
            if not transformation.get_transformation(unit_id,"Super Saiyan 2") then
                local can_transform=transformation.add_transformation(unit_id,"Super Saiyan 2")
                if can_transform then
                    dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=false,RECENTER=false,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=false},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a super saiyan 2!',11)
                end
            end
        end
    end
    if df.global.gamemode==df.game_mode.ADVENTURE and unit==df.global.world.units.active[0] then
        if powerLevel>3000000 or (dfhack.units.getNominalSkill(unit,df.job_skill.MELEE_COMBAT)>=15 and dfhack.units.getNominalSkill(unit,df.job_skill.DISCIPLINE)>=15) then
            if not transformation.get_transformation(unit_id,"Super Saiyan") then
                transformation.add_transformation(unit_id,"Super Saiyan")
                transformation.transform(unit_id,"Super Saiyan",true)
                dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{PAUSE=true,RECENTER=true,D_DISPLAY=true,A_DISPLAY=true,DO_MEGA=true},unit.pos,dfhack.TranslateName(dfhack.units.getVisibleName(unit))..' has figured out how to transform into a Super Saiyan',11)
            end
        end
    end
    transformation.add_transformation(unit_id,'Oozaru')
end

if args.unit then
    runSuperSaiyanChecksExtremeEmotion(tonumber(args.unit))
end