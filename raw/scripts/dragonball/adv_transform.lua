-- Allows instant transmission.

if df.global.gamemode~=1 then
	qerror("Adventure mode only.")
end

local dialog = require('gui.dialogs')

local transformation=dfhack.script_environment('dragonball/transformation')

function selectTransformation() --taken straight from here, but edited so I can understand it better: https://gist.github.com/warmist/4061959/... again. Also edited for syndromeTrigger, but in a completely different way.
    local tunit=df.global.world.units.active[0]
    local all=transformation.get_all_transformations(tunit.id)
    local tbl={}
    for k,v in pairs(all) do
		table.insert(tbl,{v.value..(v.ints[1]==1 and " (transformed)" or ""),nil,v.value})
    end
    local f=function(name,C)
        transformation.transform(tunit.id,C[3],transformation.get_transformation(tunit.id,C[3]).ints[1]==0)
    end
	dialog.showListPrompt("Dragon Ball","Choose transformation to toggle.",COLOR_WHITE,tbl,f)
end

selectTransformation()