onUnitAction=onUnitAction or dfhack.event.new()

local actions_already_checked=actions_already_checked or {}

local function action_already_checked(unit_id,action_id)
    local unit_action_checked=actions_already_checked[unit_id]
    if unit_action_checked then
        return unit_action_checked[action_id]
    end
end

local function checkForActions()
    for k,unit in ipairs(df.global.world.units.active) do
        for _,action in ipairs(unit.actions) do
            if not action_already_checked(unit.id,action.id) then
                onUnitAction(unit.id,action)
                actions_already_checked[unit.id]=actions_already_checked[unit.id] or {}
                actions_already_checked[unit.id][action.id]=true
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