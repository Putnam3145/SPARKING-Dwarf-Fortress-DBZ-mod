local gui=require('gui')
local ki=dfhack.script_environment('dragonball/ki')

local getPowerLevel=function(unit,numOnly)
    if not unit then return 'nothing' end
    local powerLevel,kiLevel=ki.get_ki_investment(unit.id)
    local potential=ki.get_max_ki(unit.id)
    local kiWorldMode=ki.getWorldKiMode()
    if kiWorldMode=='bttl' then
        if kiLevel>1 and not numOnly then 
            local kiLevelStr=kiLevel==1 and 'god' or kiLevel==2 and 'god' or kiLevel==3 and 'one infinity core' or kiLevel<11 and tostring(kiLevel-2)..' infinity cores' or "the culmination"
            return powerLevel..' ('..kiLevelStr..')',potential
        else
            return powerLevel,potential
        end
    else
        if kiLevel==1 and not numOnly then
            return powerLevel..' (god)',potential
        else
            return powerLevel,potential
        end
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
        local powerLevel,potential=getPowerLevel(unit,true)
        if powerLevel then
            local powerstr=' power level is '
            powerstr=unit.sex==0 and 'Her'..powerstr or unit.sex==1 and 'His'..powerstr or 'Its'..powerstr --capitalization is important!
            local powerRatio=powerLevel/potential
            local powerLevelColor=powerRatio<0.2 and COLOR_LIGHTMAGENTA or powerRatio<0.4 and COLOR_RED or powerRatio<0.6 and COLOR_LIGHTRED or powerRatio<0.8 and COLOR_GREEN or powerRatio<1 and COLOR_LIGHTGREEN or COLOR_LIGHTCYAN
            dfhack.screen.paintString({fg=COLOR_WHITE},2,3-scroll_pos,powerstr)
            dfhack.screen.paintString({fg=powerLevelColor},#powerstr+2,3-scroll_pos,powerLevel)
            dfhack.screen.paintString({fg=COLOR_WHITE},#powerstr+#tostring(powerLevel)+2,3-scroll_pos,'/')
            dfhack.screen.paintString({fg=COLOR_LIGHTCYAN},#powerstr+#tostring(powerLevel)+3,3-scroll_pos,potential)
            dfhack.screen.paintString({fg=COLOR_WHITE},#powerstr+#tostring(powerLevel)+#tostring(potential)+3,3-scroll_pos,' (press enter for more info)')
        end
    end
end

function TextViewScouter:onInput(keys)
    self:inputToSubviews(keys)
    self:sendInputToParent(keys)
    if keys.LEAVESCREEN then
        self:dismiss()
    end
    if keys.SELECT then
        self:showMoreInfo()
    end
end

local isPositiveWillpowerEmotion={
    Rage=true,
    Wrath=true,
    Anger=true,
    Ferocity=true,
    Bitterness=true,
    Hatred=true,
    Loathing=true,
    Outrage=true,
}

local function getYukiPerc(unit)
    local m=math
    local stressLevel=unit.status.current_soul.personality.stress_level
    for k,v in ipairs(unit.status.current_soul.personality.emotions) do
        local emotion_type=df.emotion_type[v.type]
        if isPositiveWillpowerEmotion[emotion_type] then
            local multiplicand=tonumber(df.emotion_type.attrs[v.type].divider)
            if multiplicand~=0 then multiplicand=1/m.abs(multiplicand) end
            local stress_addition=v.strength*-multiplicand
            stressLevel=stressLevel-stress_addition
        end
    end
    return stressLevel>0 and m.min(1,8/(m.log(stressLevel)/m.log(2))) or 1
end

local function getShokiPerc(unit) --remember to update once structures are properly mapped!
    local distractednessTotal=0
    for k,need in ipairs(unit.status.current_soul.personality.needs) do
        distractednessTotal=distractednessTotal+need.focus_level
    end
    return distractednessTotal>0 and math.min(1,8/(math.log(distractednessTotal)/math.log(2))) or 1 --i think the same equation ought to work for both...
end

local function averageTo1(number)
    return (1+number)/2
end

function TextViewScouter:showMoreInfo()
    local unit=self._native.parent.parent.unit
    local boost,willpower,focus,endurance = ki.calculate_max_ki_portions(unit)
    local totalKi=willpower+focus+endurance+boost
    local genkipercent,yukipercent,shokipercent=endurance/totalKi,willpower/totalKi,focus/totalKi
    local genkiAdjust=math.min(1,((unit.body.blood_count/unit.body.blood_max)*dfhack.units.getEffectiveSkill(unit,df.job_skill.MELEE_COMBAT)/5)/2)
    local yukiAdjust=math.min(1,(getYukiPerc(unit)*dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)/5)/2)
    local shokiAdjust=math.min(1,(getShokiPerc(unit)*dfhack.units.getEffectiveSkill(unit,df.job_skill.DISCIPLINE)/5)/2)
    local maxKi=ki.get_max_ki(unit.id)
    local maxGenki,maxYuki,maxShoki=(genkipercent*maxKi),(yukipercent*maxKi),(shokipercent*maxKi)
    local genkiInvestment,yukiInvestment,shokiInvestment=math.floor(maxGenki*genkiAdjust+.5),math.floor(maxYuki*yukiAdjust+.5),math.floor(maxShoki*shokiAdjust+.5)
    local dlg=require('gui.dialogs')
    dlg.showMessage('Ki','Genki: '..genkiInvestment..'/'..maxGenki..' Yuki: '..yukiInvestment..'/'..maxYuki..' Shoki: '..shokiInvestment..'/'..maxShoki..'.'..NEWLINE..'Yuki is determined by persevering attributes, stress and discipline, '..NEWLINE..'Shoki by intelligent and aware attributes, distractedness and discipline'..NEWLINE..'and Genki by physical strength, health and fighting skill.')
end

function TextViewScouter:onGetSelectedUnit()
    return self._native.parent.parent.unit
end

local DungeonScouter=defclass(DungeonScouter,TransparentViewscreen)

function DungeonScouter:onRender()
    local dungeon_viewscreen=self._native.parent
    dungeon_viewscreen:render()
    if dungeon_viewscreen._type~=df.viewscreen_dungeon_monsterstatusst then self:dismiss() return end
    if not(dungeon_viewscreen.view_skills) and dungeon_viewscreen.unit then
        local unit=dungeon_viewscreen.unit
        local powerLevel,potential=getPowerLevel(unit,true)
        if powerLevel then
            local stringSoFar='Power Level: '
            local plevelcolor=powerLevel<1000 and COLOR_LIGHTMAGENTA or powerLevel<2000 and COLOR_LIGHTRED or powerLevel<4000 and COLOR_RED or powerLevel<8000 and COLOR_WHITE or powerLevel<16000 and COLOR_GREEN or powerLevel<32000 and COLOR_LIGHTGREEN or COLOR_LIGHTCYAN
            dfhack.screen.paintString({fg=plevelcolor},0,21,'Power Level ' ..powerLevel..'/'..potential)
        end
    end
end

function DungeonScouter:onGetSelectedUnit()
   return self._native.parent.unit 
end

local UnitListScouter=defclass(UnitListScouter,TransparentViewscreen)

function UnitListScouter:changeMode()
    self.display=not self.display
end

local TransformationList=defclass(TransformationList,require('gui.dialogs').MessageBox)

function TransformationList:getWantedFrameSize()
    local width = math.max(self.frame_width or 0, 20, #(self.frame_title or '') + 4)
    local largest_text_width=-100000
    for k,v in ipairs(self.subviews) do
        local curWidth=#v.text
        if curWidth>largest_text_width then largest_text_width=curWidth end
    end
    return math.max(width, largest_text_width), #self.subviews
end

function TransformationList:init(args)
    self.unit=args.unit
    local transformation=dfhack.script_environment('dragonball/transformation')
    local all=transformation.get_all_transformations(self.unit.id)
    local render_table={}
    local widgets=require('gui.widgets')
    if not all then
        table.insert(render_table,widgets.Label{view_id='whoops',text='No transformations known!',text_pen={bg=COLOR_BLACK,fg=COLOR_WHITE},frame={l=0,t=0},auto_height=true})
    else
        for k,v in ipairs(all) do
            table.insert(render_table,widgets.Label{view_id=v.value,text=v.value,text_pen={bg=COLOR_BLACK,fg=v.ints[1]==1 and COLOR_LIGHTGREEN or COLOR_WHITE},frame={l=0,t=k-1},auto_height=true})
        end
    end
    self.subviews=render_table
end

function UnitListScouter:onInput(keys)
    self:inputToSubviews(keys)
    self:sendInputToParent(keys)
    if keys.CUSTOM_F then
        self:changeMode()
    elseif keys.CUSTOM_T then
        TransformationList{unit=dfhack.gui.getSelectedUnit()}:show()
    end
    if keys.LEAVESCREEN or keys.UNITVIEW_RELATIONSHIPS_ZOOM then
        self:dismiss()
    end
end

function UnitListScouter:onGetSelectedUnit()
    local parent=self._native.parent
    return parent.units[parent.page][parent.cursor_pos[parent.page]]
end

function UnitListScouter:onResize(w,h)
    self.jobX=math.floor(w/2)
    self.pageY=h-9
    self.buttonDisplayX=12
    self.recalculateButtonDisplay=true --putting this code into the onResize function results in utterly screwy results, best put it in once the rendering's back to normal
end

function UnitListScouter:onRender()
    self._native.parent:render()
    self.buttonDisplayTimeout=self.buttonDisplayTimeout and self.buttonDisplayTimeout-1 or 10
    if self.buttonDisplayTimeout<=0 then
        self.recalculateButtonDisplay=true
    end
    if self._native.parent._type~=df.viewscreen_unitlistst then self:dismiss() return end
    if self.recalculateButtonDisplay then
        local old_x=self.buttonDisplayX
        local old_y=self.buttonDisplayY
        local h=df.global.gps.dimy
        for i=2,df.global.gps.dimx do
            local tile1,tile2=dfhack.screen.readTile(i,h-2),dfhack.screen.readTile(i+1,h-2)
            if (tile1.ch==0 or tile1.ch==32 or tile1.bg==tile1.fg) then
                if (tile2.ch==0 or tile2.ch==32 or tile2.bg==tile2.fg) then
                    self.buttonDisplayX=i+1
                    self.recalculateButtonDisplay=false
                    break
                end
            end
        end
        self.buttonDisplayTimeout=math.ceil(df.global.enabler.gfps/30)
    end
    if self.display then
        local parent=self._native.parent
        local stupidWorkaround='                                      '
        local curPage=math.floor(parent.cursor_pos[parent.page]/self.pageY)
        for k,v in ipairs(self.powerLevels[parent.page]) do
            if math.floor((k-1)/self.pageY)==curPage and v[1] then
                local yPos=((k-1)%self.pageY)+4
                local pRatio=v[1]/v[2]
                local plevelcolor=v[1]==2250 and COLOR_LIGHTMAGENTA or pRatio<0.1 and COLOR_LIGHTRED or pRatio<0.35 and COLOR_RED or pRatio<0.6 and COLOR_WHITE or pRatio<0.85 and COLOR_GREEN or pRatio<1 and COLOR_LIGHTGREEN or COLOR_LIGHTCYAN
                if parent.cursor_pos[parent.page]==k-1 then
                    dfhack.screen.paintString({fg=COLOR_BLACK,bg=COLOR_GREY},self.jobX,yPos,v[1]..'/'..v[2]..stupidWorkaround)
                else
                    dfhack.screen.paintString({fg=plevelcolor,bg=COLOR_BLACK},self.jobX,yPos,v[1])
                    dfhack.screen.paintString({fg=COLOR_LIGHTCYAN,bg=COLOR_BLACK},self.jobX+#tostring(v[1]),yPos,'/'..v[2]..stupidWorkaround)
                end
            end
        end
    end
    dfhack.screen.paintString({fg=COLOR_LIGHTRED,bg=COLOR_BLACK},self.buttonDisplayX,df.global.gps.dimy-2,'f')
    dfhack.screen.paintString({fg=COLOR_WHITE,bg=COLOR_BLACK},self.buttonDisplayX+1,df.global.gps.dimy-2,': scouter')
    dfhack.screen.paintString({fg=COLOR_LIGHTRED,bg=COLOR_BLACK},self.buttonDisplayX+11,df.global.gps.dimy-2,'t')
    dfhack.screen.paintString({fg=COLOR_WHITE,bg=COLOR_BLACK},self.buttonDisplayX+12,df.global.gps.dimy-2,': transformations')
end

function UnitListScouter:init(args)
    self.display=false
    self.powerLevels={}
    for k,unitList in ipairs(args.parent.units) do
        self.powerLevels[k]={}
        for kk,unit in ipairs(unitList) do
            table.insert(self.powerLevels[k],{getPowerLevel(unit)})
        end
    end
end

local FollowScouter = defclass(FollowScouter,require('gui.dwarfmode').DwarfOverlay)

function FollowScouter:onResize(w,h)
    self.yPlacement = h-2
end

function FollowScouter:onRender()
    if (df.global.ui.follow_unit == -1) or self._native.parent._type ~= df.viewscreen_dwarfmodest then self:dismiss() return end
    self._native.parent:render()
    local unit = df.unit.find(df.global.ui.follow_unit)
    if not unit then self:dismiss() return end
    self.xPlacement = #dfhack.TranslateName(dfhack.units.getVisibleName(unit))+#dfhack.units.getProfessionName(unit)+13
    local pen = dfhack.screen.readTile(self.xPlacement,self.yPlacement)
    repeat
        self.xPlacement = self.xPlacement+2
        pen = dfhack.screen.readTile(self.xPlacement,self.yPlacement)
    until pen.ch < 65 or pen.ch > 122
    self.xPlacement = self.xPlacement + 1
    local powerLevels = {getPowerLevel(unit)}
    local pRatio = powerLevels[1]/powerLevels[2]
    local plevelcolor=pRatio<0.1 and COLOR_LIGHTRED or pRatio<0.35 and COLOR_RED or pRatio<0.6 and COLOR_WHITE or pRatio<0.85 and COLOR_GREEN or pRatio<1 and COLOR_LIGHTGREEN or COLOR_LIGHTCYAN
    dfhack.screen.paintString({fg=plevelcolor,bg=COLOR_BLACK},self.xPlacement,self.yPlacement,powerLevels[1])
    dfhack.screen.paintString({fg=COLOR_LIGHTCYAN,bg=COLOR_BLACK},self.xPlacement+#tostring(powerLevels[1]),self.yPlacement,'/'..powerLevels[2])
end

function FollowScouter:onInput(keys)
    self:inputToSubviews(keys)
    self:sendInputToParent(keys)
    if keys.LEAVESCREEN then
        df.global.ui.follow_unit = -1
        self:dismiss()
    end
end

function FollowScouter:onIdle()
    self._native.parent:logic()
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

viewscreenActions[df.viewscreen_unitlistst]=function()
    local extraUnitListScreen=UnitListScouter{parent=dfhack.gui.getCurViewscreen()}
    extraUnitListScreen:show()
end

viewscreenActions[df.viewscreen_dwarfmodest]=function()
    if df.global.ui.follow_unit ~= -1 then
        local scouter = FollowScouter()
        scouter:show()
    end
end

local function tryFollowScouter()
    if(df.global.ui.follow_unit == -1 or dfhack.gui.getCurViewscreen()._type ~= df.viewscreen_dwarfmodest) then return end
    local scouter = FollowScouter()
    scouter:show()
end

dfhack.onStateChange.dwarf_scouter=function(code)
    if code==SC_VIEWSCREEN_CHANGED then
        local viewfunc=viewscreenActions[dfhack.gui.getCurViewscreen()._type]
        if viewfunc then viewfunc() end
    end
    require('repeat-util').scheduleEvery("Dwarf Scouter",2,'frames',tryFollowScouter)
end
