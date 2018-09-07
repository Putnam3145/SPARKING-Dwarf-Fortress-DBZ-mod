if df.global.gamemode~=df.game_mode.ADVENTURE then qerror('this script should only be run in adventure mode!') end

local persist=dfhack.persistent.save{key='ADV_HOLDING_BACK'}

persist.ints[1]=math.max(0,persist.ints[1])

persist.ints[1]=math.max(0,math.min(1,1-persist.ints[1]))

if persist.ints[1]==1 then
    dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{D_DISPLAY=false,A_DISPLAY=true},unit.pos,'You begin holding back.',11)
else
    dfhack.gui.makeAnnouncement(df.announcement_type.MARTIAL_TRANCE,{D_DISPLAY=false,A_DISPLAY=true},unit.pos,'You stop holding back.',11)
end

persist:save()