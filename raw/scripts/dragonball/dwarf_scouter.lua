local gui=require('gui')

local getPowerLevel=function(unit)
    if not unit then return 'nothing' end
    local powerLevel,kiLevel=dfhack.script_environment('dragonball/ki').get_ki_investment(unit.id)
    local potential=dfhack.script_environment('dragonball/ki').get_max_ki(unit.id)
    if kiLevel>1 then 
        local kiLevelStr=kiLevel==1 and 'demigod' or kiLevel==2 and 'god' or kiLevel==3 and 'one infinity core' or tostring(kiLevel-2)..' infinity cores'
        return powerLevel..' ('..kiLevelStr..')',potential
    else
        return powerLevel,potential
    end
end

function getMilitarySelectedUnit()
    local viewscreen=dfhack.gui.getCurViewscreen()
    if viewscreen._type~=df.viewscreen_layer_militaryst then
        while viewscreen._type~=df.viewscreen_layer_militaryst do
            viewscreen=viewscreen.parent
            if viewscreen._type~=df.viewscreen_layer_militaryst and not viewscreen.parent then return nil end
        end
        if viewscreen._type~=df.viewscreen_layer_militaryst or viewscreen.page~=0 then
            return nil
        end
    end
    if viewscreen.page~=0 then
        return nil
    end
    if viewscreen.layer_objects[1].active then
        local unit = viewscreen.positions.assigned[viewscreen.layer_objects[1].cursor]
        return viewscreen.positions.assigned[viewscreen.layer_objects[1].cursor]
    elseif viewscreen.layer_objects[2].active then
        return viewscreen.positions.candidates[viewscreen.layer_objects[2].cursor] 
    end
end

local TransparentViewscreen=defclass(TransparentViewscreen,gui.Screen)

function TransparentViewscreen:onInput(keys)
    self:inputToSubviews(keys)
    self:sendInputToParent(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    end
end

local MilitaryScouter=defclass(MilitaryScouter,TransparentViewscreen)

function MilitaryScouter:onGetSelectedUnit()
    return getMilitarySelectedUnit()
end

function MilitaryScouter:onRender()
    self._native.parent:render()
    if self._native.parent._type~=df.viewscreen_layer_militaryst then self:dismiss() return end
    if self._native.parent.page==0 and (self._native.parent.layer_objects[1].active or self._native.parent.layer_objects[2].active) then
        local unit=getMilitarySelectedUnit()
        local powerLevel,potential=getPowerLevel(unit)
        powerLevel=powerLevel or 'nothing'
        potential=potential or ''
        if powerLevel~='nothing' then
            dfhack.screen.paintString({fg=COLOR_WHITE},40,3,'Power level: ' .. powerLevel..'/'..potential)
            dfhack.screen.paintString({fg=COLOR_WHITE},40,4,'Power level can be raised to potential')
            dfhack.screen.paintString({fg=COLOR_WHITE},40,5,'through discipline.')
        end
    end
end

local TextViewScouter=defclass(TextViewScouter,TransparentViewscreen)

function TextViewScouter:onRender()
    self._native.parent:render()
    if self._native.parent._type~=df.viewscreen_textviewerst then self:dismiss() return end
    local scroll_pos=self._native.parent.scroll_pos
    if scroll_pos<2 then
        local unit=self._native.parent.parent.unit
        local powerLevel,potential=getPowerLevel(unit)
        powerLevel=powerLevel or 'nothing'
        potential=potential or 'nothing'
        local sex_str=unit.sex==0 and 'her' or unit.sex==1 and 'his' or 'its'
        local powerstr=' power level is '
        powerstr=unit.sex==0 and 'Her'..powerstr or unit.sex==1 and 'His'..powerstr or 'Its'..powerstr --capitalization is important!
        local potentialstr=' and '..sex_str..' current potential is '
        dfhack.screen.paintString({fg=COLOR_WHITE},2,3-scroll_pos,powerstr)
        dfhack.screen.paintString({fg=COLOR_GREEN},#powerstr+2,3-scroll_pos,powerLevel)
        dfhack.screen.paintString({fg=COLOR_WHITE},#powerstr+#tostring(powerLevel)+2,3-scroll_pos,potentialstr)
        dfhack.screen.paintString({fg=COLOR_GREEN},#powerstr+#tostring(powerLevel)+#potentialstr+2,3-scroll_pos,potential)
        dfhack.screen.paintString({fg=COLOR_WHITE},#powerstr+#tostring(powerLevel)+#potentialstr+#tostring(potential)+2,3-scroll_pos,'.')
    end
end

local DungeonScouter=defclass(DungeonScouter,TransparentViewscreen)

function DungeonScouter:onRender()
    local dungeon_viewscreen=self._native.parent
    dungeon_viewscreen:render()
    if dungeon_viewscreen._type~=df.viewscreen_dungeon_monsterstatusst then self:dismiss() return end
    if not(dungeon_viewscreen.view_skills) and dungeon_viewscreen.unit then
        local unit=dungeon_viewscreen.unit
        local powerLevel,potential=getPowerLevel(unit)
        if powerLevel then
            local stringSoFar='Power Level: '
            local plevelcolor=powerLevel<1250 and COLOR_LIGHTRED or powerLevel<2750 and COLOR_WHITE or powerLevel<5000 and COLOR_GREEN or powerLevel<10000 and COLOR_LIGHTGREEN or powerLevel<100000 and COLOR_LIGHTCYAN or COLOR_LIGHTMAGENTA
            dfhack.screen.paintString({fg=plevelcolor},0,21,'Power Level ' ..powerLevel..'/'..potential)
        end
    end
end

local viewscreenActions={}

viewscreenActions[df.viewscreen_layer_militaryst]=function() --yeah that works
    local scouter=MilitaryScouter()
    scouter:show()
end

viewscreenActions[df.viewscreen_textviewerst]=function()
    if dfhack.gui.getCurViewscreen().parent._type==df.viewscreen_unitst then
        local scouter=TextViewScouter()
        scouter:show()
    end
end

viewscreenActions[df.viewscreen_dungeon_monsterstatusst]=function()
    local scouter=DungeonScouter()
    scouter:show()
end

dfhack.onStateChange.dwarf_scouter=function(code)
    if code==SC_VIEWSCREEN_CHANGED then
        local viewfunc=viewscreenActions[dfhack.gui.getCurViewscreen()._type]
        if viewfunc then viewfunc() end
    end
end