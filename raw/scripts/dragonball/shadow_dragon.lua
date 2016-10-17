local function someReasonableLocation()
    for k,v in ipairs(df.global.world.buildings.other.WORKSHOP_CUSTOM) do
        if df.building_def.find(v.custom_type).code=='SHENRON_SUMMONING_WORKSHOP' then
            return {v.x2,v.y2,v.z}
        end
    end
    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isCitizen(v) then
            return {v.pos.x,v.pos.y,v.pos.z}
        end
    end
end

function init_shadow_dragons()
    dfhack.script_environment('dragonball/ki').setWorldKiMode('bttl')
    local alphaMessage=[["Thanks for summoning the dragon so often. I'm Alpha Shenron, and we are the Shadow Dragons. If you take too long to defeat us, the Eternal will come and destroy the universe. No pressure."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,PAUSE=true,RECENTER=false},copyall(df.global.cursor),alphaMessage,COLOR_LIGHTCYAN)
    local gaia_shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=1,age=25,name='Gaia Shenron',civ_id=-1})
    gaia_shenron.flags1.invades=true
    gaia_shenron.flags1.marauder=true
    gaia_shenron.flags1.active_invader=true
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
    shadow_dragon_persist.ints[7]=0
    shadow_dragon_persist:save()    
    require('repeat-util').scheduleEvery('shadow dragons',100,'ticks',shadow_dragon_loop)
end

local function summonEternal()
    local eternal=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='ENTROPY_SOLDIERS_DB',caste=0,age=1000000,name='Tenebrion',civ_id=-1})
    eternal.flags1.invades=true
    eternal.flags1.marauder=true
    eternal.flags1.active_invader=true
    eternal.flags2.visitor_uninvited=true
    eternal.flags3.no_meandering=true
    local message=[[The Eternal has arrived!]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},eternal.pos,message,COLOR_LIGHTRED)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=eternal.id
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[3]=8
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[5]=df.global.cur_year+1
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[6]=df.global.cur_year_tick
    shadow_dragon_persist:save()
end

local shadow_dragon_action={}

shadow_dragon_action[2]=function()
    local shenron=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='SHADOW_DRAGON_DB',caste=2,age=25,name='Hades Shenron',civ_id=-1})
    shenron.flags1.invades=true
    shenron.flags1.marauder=true
    shenron.flags2.visitor_uninvited=true
    shenron.flags3.no_meandering=true
    shenron.flags1.active_invader=true
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
    shenron.flags1.active_invader=true
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
    shenron.flags1.active_invader=true
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
    shenron.flags1.active_invader=true
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
    shenron.flags1.active_invader=true
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
    shenron.flags1.active_invader=true
    local message=[["What does it take?! Does the afterlife just hate you and refuse you entry, or what?! ...Hh. I apologize. Genuinely. I let myself get carried away. I don't resent you at all. I mean, I'll still kill you since you insist on fighting, but please rest assured I feel nothing but respect for any of you. You see, my philosophy is simple. I believe that we were all created for a purpose. There are, of course, the creators and destroyers of worlds, or of universes. Simple enough. Then myself and the other Shadow Dragonswe are the Eternal's creatures, and our purpose is to enact its supreme will. As, you'll notice, I am doing so now. You, on the other hand..."]]
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

shadow_dragon_action[9]=function()
    local message=[["You killed Entropy's lacky? That means you generated an infinity core! Okay, Entropy's going to be looking for your world, and it'll take him a while. You'll need to get stronger as quickly as possible during that time! Good luck!"]]
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},someReasonableLocation(),message,COLOR_LIGHTCYAN)
    shadow_dragon_persist.ints[2]=3
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[5]=df.global.cur_year+1
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[6]=df.global.cur_year_tick
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[7]=1
    shadow_dragon_persist:save()
end

shadow_dragon_action[10]=function() 
    local soldier=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='ENTROPY_SOLDIERS_DB',caste=2,age=1000000,name='Ignis',civ_id=-1})
    soldier.flags1.invades=true
    soldier.flags1.marauder=true
    soldier.flags2.visitor_uninvited=true
    soldier.flags3.no_meandering=true
    soldier.flags1.active_invader=true
    local message=[["Oh, boy, you killed Lucius? I haven't seen action in so long... I'm gonna enjoy killing all of you. I am Ignis. Haa!"]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},soldier.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=soldier.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[11]=function()
    local soldier=dfhack.script_environment('dragonball/spawn-unit').place({position=someReasonableLocation(),race='ENTROPY_SOLDIERS_DB',caste=3,age=1000000,name='Ignis',civ_id=-1})
    soldier.flags1.invades=true
    soldier.flags1.marauder=true
    soldier.flags2.visitor_uninvited=true
    soldier.flags3.no_meandering=true
    soldier.flags1.active_invader=true
    local message=[["Can't take too long, Entropy wants this thing over with, and I was chosen because unlike some people, I get things done. Lord Entropy isn't stupid. He's not taking any chances...which is why he sent someone three times as powerful as Lucius or Ignis. Mortis, pleased to kill you."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},soldier.pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=soldier.id
    shadow_dragon_persist:save()
end

shadow_dragon_action[12]=function() 
    local spawn_unit=dfhack.script_environment('dragonball/spawn-unit').place
    local location=someReasonableLocation()
    local soldiers={ --wait is this supposed to be winnable i can't tell
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=4,age=1000000,name='Praelia',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=5,age=1000000,name='Victoria',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=6,age=1000000,name='Crystallos',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=7,age=1000000,name='Impetia',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=8,age=1000000,name='Nereid',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=9,age=1000000,name='Terra',civ_id=-1})
    }
    for _,soldier in ipairs(soldiers) do
        soldier.flags1.invades=true
        soldier.flags1.marauder=true
        soldier.flags2.visitor_uninvited=true
        soldier.flags3.no_meandering=true
        soldier.flags1.active_invader=true
    end
    local message=[["Lord Entropy is not one for sending one soldier at a time, letting you get stronger. As Mortis likely said, he is not stupid."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},soldiers[1].pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=soldiers[1].id
    shadow_dragon_persist:save()
end

shadow_dragon_action[13]=function()
    local spawn_unit=dfhack.script_environment('dragonball/spawn-unit').place
    local location=someReasonableLocation()
    local soldiers={ --wait is this supposed to be winnable i can't tell
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=10,age=1000000,name='Raptor',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=11,age=1000000,name='Incipiens',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=12,age=1000000,name='Terminus',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_SOLDIERS_DB',caste=13,age=1000000,name='Anima',civ_id=-1}),
    spawn_unit({position=location,race='ENTROPY_AND_SAMSARA_DB',caste=1,age=1000000,name='Lord Entropy',civ_id=-1})    
    }
    for _,soldier in ipairs(soldiers) do
        soldier.flags1.invades=true
        soldier.flags1.marauder=true
        soldier.flags2.visitor_uninvited=true
        soldier.flags3.no_meandering=true
        soldier.flags1.active_invader=true
    end
    local message=[["Okay, now I am getting annoyed."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=true,PAUSE=true},soldiers[5].pos,message,COLOR_LIGHTCYAN)
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=soldiers[1].id
    shadow_dragon_persist:save()
end

shadow_dragon_action[14]=function()
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[2]=2
    shadow_dragon_persist:save()
    require('repeat-util').cancel('shadow dragons')
    local message=[["Haha, wow, you killed Lord Entropy? Good, I don't have to. Maybe one of you'll be strong enough for me to have fun with one day. Maybe. I doubt it. Don't expect to see me again, except maybe answering your prayers and helping the weak."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,RECENTER=false,PAUSE=true},{},message,COLOR_LIGHTCYAN)
    dfhack.script_environment('dragonball/ki').setWorldKiMode('super')
end

function init_entropy()
    local luciusMessage=[["So, you managed to destroy Tenebrion? That's adorable. I am Lucius, a soldier of Entropy. Tenebrion was the weakest among us. Prepare yourself."]]
    dfhack.gui.makeAnnouncement(df.announcement_type.ERA_CHANGE,{DO_MEGA=true,PAUSE=true,RECENTER=false},copyall(df.global.cursor),alphaMessage,COLOR_LIGHTCYAN)
    local soldier=dfhack.script_environment('dragonball/spawn-unit').place({position={},race='ENTROPY_SOLDIERS_DB',caste=1,age=25,name='Lucius',civ_id=-1})
    soldier.flags1.invades=true
    soldier.flags1.marauder=true
    soldier.flags2.visitor_uninvited=true
    soldier.flags3.no_meandering=true
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    shadow_dragon_persist.ints[4]=soldier.id
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[5]=100000
    shadow_dragon_persist:save()
    shadow_dragon_persist.ints[7]=0
    shadow_dragon_persist:save()
end

function shadow_dragon_loop()
    local shadow_dragon_persist=dfhack.persistent.save({key='DRAGONBALL_WISH_COUNT'})
    local cur_shadow_dragon=df.unit.find(shadow_dragon_persist.ints[4])
    if cur_shadow_dragon.flags1.dead and shadow_dragon_persist.ints[7]==0 then
        shadow_dragon_persist.ints[3]=shadow_dragon_persist.ints[3]+1
        shadow_dragon_persist:save()
        shadow_dragon_action[shadow_dragon_persist.ints[3]]()
    end
    if df.global.cur_year>=shadow_dragon_persist.ints[5] and df.global.cur_year_tick>shadow_dragon_persist.ints[6] then
        if shadow_dragon_persist.ints[2]==1 then
            summonEternal()
        elseif shadow_dragon_persist.ints[2]==3 then
            init_entropy()
        end
    end
end
