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
    local yukiPerc=
    local stressLevel=unit.status.current_soul.personality.stressLevel
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
    for k,need in ipairs(unit.status.current_soul.personality.unk_v4201_1a) do
        distractednessTotal=distractednessTotal+need.unk_8
    end
    return distractednessTotal>0 and math.min(1,8/(math.log(distractednessTotal)/math.log(2)) or 1 --i think the same equation ought to work for both...
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
            local plevelcolor=powerLevel<1000 and COLOR_RED powerLevel<2000 and COLOR_LIGHTRED or powerLevel<4000 and COLOR_WHITE or powerLevel<8000 and COLOR_GREEN or powerLevel<16000 and COLOR_LIGHTGREEN or powerLevel<32000 and COLOR_LIGHTCYAN or COLOR_LIGHTMAGENTA
            dfhack.screen.paintString({fg=plevelcolor},0,21,'Power Level ' ..powerLevel..'/'..potential)
        end
    end
end

function DungeonScouter:onGetSelectedUnit()
   return self._native.parent.unit 
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
