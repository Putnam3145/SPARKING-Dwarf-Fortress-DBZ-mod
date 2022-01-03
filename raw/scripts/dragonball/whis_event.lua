local script=require('gui.script')

local function getPowerLevel(saiyan)
    return dfhack.script_environment('dragonball/ki').get_max_ki_pre_boost(saiyan)
end

function get_S_cells(unit)
    local persist=dfhack.persistent.save{key='DRAGONBALL/S_CELLS/'..unit.id}
    for i=1,7 do
        if persist.ints[i]<0 then persist.ints[i]=0 end
    end
    --ints[1] is S-cells
    --ints[2] is experience with Super Saiyan 2
    --ints[3] is super saiyan anger event
    --ints[4] is trained by angel
    return persist:save()
end

local function buildUnitList()
    local list={}
    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isDwarf(v) and dfhack.units.isCitizen(v) then
            table.insert(list,{dfhack.TranslateName(dfhack.units.getVisibleName(v))..' '..getPowerLevel(v.id),nil,v})
        end
    end
    return list
end

local function do_event()
    local alreadyDone=dfhack.persistent.save{key='DRAGONBALL/WHIS'}
    if df.global.gamemode~=df.game_mode.ADVENTURE then
        if alreadyDone.ints[1]==1 then return false end
        local choices=buildUnitList()
        script.showMessage('Dragon Ball',[["Hmm, this is the place? Hello, everyone. I am Whis, attendant to Lord Beerus the Destroyer. I have come to offer my teaching to two of you Saiyans, to learn how to tap into the power of gods."]],COLOR_LIGHTCYAN)
        local unit1
        while not unit1 or not ok do
            ok,index,unitTable=script.showListPrompt('Dragon Ball','Which saiyans do you want to send with Whis? (First)',COLOR_LIGHTGREEN,choices)
            unit1=unitTable[3]
        end
        local unit2
        while not unit2 or unit1==unit2 or not ok do
            ok,index,unitTable=script.showListPrompt('Dragon Ball','Which saiyans do you want to send with Whis? (Second)',COLOR_LIGHTGREEN,choices)
            unit2=unitTable[3]
        end
        local unit1god=get_S_cells(unit1)
        local unit2god=get_S_cells(unit2)
        unit1god.ints[4]=1
        unit2god.ints[4]=1
        unit1god:save()
        unit2god:save()
        alreadyDone.ints[1]=1
        alreadyDone:save()
    else
        local unit=df.global.world.units.active[0]
        local god=get_S_cells(unit)
        if god.ints[4]>=1 then return false end
        script.showMessage('Dragon Ball','"Hello, '..unit.name.first_name..'. I am Whis, attendant to Lord Beerus the Destroyer."',COLOR_LIGHTCYAN)
        script.showMessage('Dragon Ball',[["I've been watching you with interest and have decided to offer my teaching to you in god ki."]],COLOR_LIGHTCYAN)
        local result=script.showYesNoPrompt('Dragon Ball','"Would you accept this offer?"')
        if result then
            god.ints[4]=1
            god:save()
        elseif result==false then --pressing escape gets you nil
            god.ints[4]=3
            god:save()
            script.showMessage('Dragon Ball','"Shame."')
        end
    end
end

script.start(do_event)