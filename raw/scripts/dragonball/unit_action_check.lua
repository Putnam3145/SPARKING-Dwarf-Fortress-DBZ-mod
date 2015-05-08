onUnitAction=onUnitAction or dfhack.event.new()

local actions_already_checked=actions_already_checked or {}

local function checkForActions()
    for k,unit in ipairs(df.global.world.units.active) do
        actions_already_checked[unit.id]=actions_already_checked[unit.id] or {}
        local unit_action_checked=actions_already_checked[unit.id]
        for _,action in ipairs(unit.actions) do
            if not unit_action_checked[action.id] then
                onUnitAction(unit.id,action)
                unit_action_checked[action.id]=true
            end
        end
    end
end

function enableEvent()
    require('repeat-util').scheduleEvery('onAction',1,'ticks',checkForActions) --surprisingly fast
end

function disableEvent()
    require('repeat-util').cancel('onAction')
end