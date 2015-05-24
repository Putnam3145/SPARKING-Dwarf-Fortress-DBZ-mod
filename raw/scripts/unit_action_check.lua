onUnitAction=onUnitAction or dfhack.event.new()

local actions_already_checked=actions_already_checked or {}

things_to_do_every_action=things_to_do_every_action or {}

actions_to_be_ignored_forever=actions_to_be_ignored_forever or {}

local function checkForActions()
    for _,something_to_do_to_every_action in pairs(things_to_do_every_action) do
        something_to_do_to_every_action[5]=something_to_do_to_every_action[5]+1 or 0
    end
    for k,unit in ipairs(df.global.world.units.active) do
        local unit_id=unit.id
        actions_already_checked[unit_id]=actions_already_checked[unit_id] or {}
        local unit_action_checked=actions_already_checked[unit_id]
        for _,action in ipairs(unit.actions) do
            local action_id=action.id
            if action.type~=-1 then
                for kk,something_to_do_to_every_action in pairs(things_to_do_every_action) do
                    if something_to_do_to_every_action[1] then 
                        if something_to_do_to_every_action[5]>1 or (unit_id==something_to_do_to_every_action[3] and action_id==something_to_do_to_every_action[4]) then
                            things_to_do_every_action[kk]=nil
                        else
                            something_to_do_to_every_action[1](unit_id,action,table.unpack(something_to_do_to_every_action[2]))
                        end
                    end
                end
                if not unit_action_checked[action_id] then
                    onUnitAction(unit_id,action)
                    unit_action_checked[action_id]=true
                end
            end
        end
    end
end

function enableEvent(ticks)
    ticks=ticks or 1
    require('repeat-util').scheduleEvery('onAction',ticks,'ticks',checkForActions) --surprisingly fast
end

function disableEvent()
    require('repeat-util').cancel('onAction')
end

function doSomethingToEveryActionNextTick(unit_id,action_id,func,func_args) --func is thing to do, unit_id and action_id represent the action that gave the "order"
    actions_to_be_ignored_forever[unit_id]=actions_to_be_ignored_forever[unit_id] or {}
    if not actions_to_be_ignored_forever[unit_id][action_id] then
        table.insert(things_to_do_every_action,{func,func_args,unit_id,action_id,0})
    end
    actions_to_be_ignored_forever[unit_id][action_id]=true
end