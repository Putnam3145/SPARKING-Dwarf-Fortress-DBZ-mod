local function getPowerLevel(saiyan)
    local focus = saiyan.status.current_soul.mental_attrs.FOCUS.value
    local endurance = saiyan.body.physical_attrs.ENDURANCE.value
    local willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value
    return focus+willpower+endurance
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
        local script=require('gui.script')
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
    local deathWasNatural={}
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
    local script=require('gui.script')
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

function hackWish(unit,callback)
    dfhack.run_script('gui/create-item','-unit',unit.id,'-restrictive','-multi')
    return true
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
    repeat
        local okay,selection=script.showListPrompt('Wish','Choose your wish.',COLOR_GREEN,{'Item','Immortality','Ressurection'})
        if selection==1 then
            okay=hackWish(unit)
        elseif selection==2 then
            okay=immortalityWish(adventure)
        elseif selection==3 then
            okay=ressurectionWish(unit.pos)
        end
    until okay
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