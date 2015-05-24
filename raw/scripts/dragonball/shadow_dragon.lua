local function someReasonableLocation()
    for k,v in ipairs(df.global.world.buildings.other.WORKSHOP_CUSTOM) do
        if df.building_def.find(v.custom_type).code=='SHENRON_SUMMONING_WORKSHOP' then
            return {v.x2,v.y2,v.z}
        end
    end
    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(v) then
            return {unit.pos.x,unit.pos.y,unit.pos.z}
        end
    end
end

function init_shadow_dragons()
    local alphaMessage=[["Thanks for summoning the dragon so often. I'm Alpha Shenron, and we are the Shadow Dragons. If you take too long to defeat us, the Eternal will come and destroy the universe. No pressure."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,PAUSE=true,RECENTER=false},copyall(df.global.cursor),alphaMessage,COLOR_LIGHTCYAN)
    local gaia_shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=1,age=25,name='Gaia Shenron',civ_id=-1})
    gaia_shenron.flags1.invades=true
    gaia_shenron.flags1.marauder=true
    gaia_shenron.flags2.visitor_uninvited=true
    gaia_shenron.flags3.no_meandering=true
    local gaiaMessage=[["Hello. I am Gaia Shenron. Worry not; you will all die, whether by my hand or the Eternal's."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},gaia_shenron.pos,gaiaMessage,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[2]=1
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[3]=1
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[4]=gaia_shenron.id
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[5]=df.global.cur_year_tick>394800 and df.global.cur_year+1 or df.global.cur_year
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[6]=df.global.cur_year_tick>394800 and 8400-(403200-df.global.cur_year_tick) or df.global.cur_year_tick+8400
    shadow_dragon_persist:save()
    require('repeat-util').scheduleEvery('shadow dragons',100,'ticks',shadow_dragon_loop)
end

local function summonEternal()
    dfhack.gui.showPopupAnnouncement('Sorry! The Eternal is not implemented yet! So instead, I leave you with this lameass thing.',COLOR_LIGHTCYAN)
    df.global.ui.game_state=1
    df.global.ui.game_over=true
end

local shadow_dragon_action={}

shadow_dragon_action[2]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=2,age=25,name='Hades Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    local message=[["You may have defeated Gaia Shenron, but you will get no further. You will meet your end at the hands of Hades Shenron!"]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},shenron.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=shenron.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[3]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=3,age=25,name='Hephaestus Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    local message=[["Your group actually managed to kill Hades... remarkable. He may have been immortal, but I am invincible!"]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},shenron.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=shenron.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[4]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=4,age=25,name='Helios Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    local message=[["Greetings. My name is Helios Shenron. I'm going to kill you, so make it interesting for me."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},shenron.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=shenron.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[5]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=5,age=25,name='Glacius Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    local message=[["Delightful. Crushing your happiness once more will bring great joy to me. The name's Glacius Shenron; who do I get to kill first?"]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},shenron.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=shenron.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[6]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=6,age=25,name='Kronos Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    local message=[["I suppose I should introduce myself. My name is Kronos Shenron."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},shenron.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=shenron.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[7]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=0,age=25,name='Alpha Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    local message=[["What does it take?! Does the afterlife just hate you and refuse you entry, or what?! ...Hh. I apologize. Genuinely. I let myself get carried away. I don't resent you at all. I mean, I'll still kill you since you insist on fighting, but please rest assured I feel nothing but respect for any of you. You see, my philosophy is simple. I believe that we were all created for a purpose. There are, of course, the creators and destroyers of worlds, or of universes. Simple enough. Then myself and the other Shadow Dragons—we are the Eternal's creatures, and our purpose is to enact its supreme will. As, you'll notice, I am doing so now. You, on the other hand..."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},shenron.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=shenron.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[8]=function()
    shadow_dragon_persist.ints[2]=2
    shadow_dragon_persist:save()
    require('repeat-util').cancel('shadow dragons')
end

function shadow_dragon_loop()
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    local cur_shadow_dragon=df.unit.find(shadow_dragon_persist.ints[4])
    if cur_shadow_dragon.flags1.dead then
        shadow_dragon_persist.ints[3]=shadow_dragon_persist.ints[3]+1
        shadow_dragon_persist:save()
        shadow_dragon_action[shadow_dragon_persist.ints[3]]()
    end
    if df.global.cur_year>=shadow_dragon_persist.ints[5] and df.global.cur_year_tick>shadow_dragon_persist.ints[6] then
        summonEternal()
    end
end