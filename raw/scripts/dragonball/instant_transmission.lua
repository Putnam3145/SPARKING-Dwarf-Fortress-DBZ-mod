-- Allows instant transmission.

if df.global.gamemode~=1 then
	qerror("Adventure mode only (for now). Sorry!")
end

function getTileType(x,y,z)
    local block = dfhack.maps.getTileBlock(x,y,z)
    if block then
        return block.tiletype[x%16][y%16]
    else
        return 0
    end
end

function getPowerLevel(saiyan)
    local strength,endurance,toughness,spatialsense,kinestheticsense,willpower
	if saiyan.curse.attr_change then
		strength = ((saiyan.body.physical_attrs.STRENGTH.value+saiyan.curse.attr_change.phys_att_add.STRENGTH)/3550)*(saiyan.curse.attr_change.phys_att_perc.STRENGTH/100)
		endurance = ((saiyan.body.physical_attrs.ENDURANCE.value+saiyan.curse.attr_change.phys_att_add.ENDURANCE)/1000)*(saiyan.curse.attr_change.phys_att_perc.ENDURANCE/100)
		toughness = ((saiyan.body.physical_attrs.TOUGHNESS.value+saiyan.curse.attr_change.phys_att_add.TOUGHNESS)/2250)*(saiyan.curse.attr_change.phys_att_perc.TOUGHNESS/100)
		spatialsense = ((saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value+saiyan.curse.attr_change.ment_att_add.SPATIAL_SENSE)/1500)*(saiyan.curse.attr_change.ment_att_perc.SPATIAL_SENSE/100)
		kinestheticsense = ((saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value+saiyan.curse.attr_change.ment_att_add.KINESTHETIC_SENSE)/1000)*(saiyan.curse.attr_change.ment_att_perc.KINESTHETIC_SENSE/100)
		willpower = ((saiyan.status.current_soul.mental_attrs.WILLPOWER.value+saiyan.curse.attr_change.ment_att_add.WILLPOWER)/1000)*(saiyan.curse.attr_change.ment_att_perc.WILLPOWER/100)
	else
        strength = saiyan.body.physical_attrs.STRENGTH.value/3550
		endurance = saiyan.body.physical_attrs.ENDURANCE.value/1000
		toughness = saiyan.body.physical_attrs.TOUGHNESS.value/2250
		spatialsense = saiyan.status.current_soul.mental_attrs.SPATIAL_SENSE.value/1500
		kinestheticsense = saiyan.status.current_soul.mental_attrs.KINESTHETIC_SENSE.value/1000
		willpower = saiyan.status.current_soul.mental_attrs.WILLPOWER.value/1000
	end
	local exhaustion = getExhaustion(saiyan)
	local bodysize = (saiyan.body.blood_count/100)^2
	powerlevel = bodysize*((strength*endurance*toughness*spatialsense*kinestheticsense*willpower)^(1/6))*exhaustion
	if isWinded(saiyan) then powerlevel=powerlevel/1.2 end
	if isStunned(saiyan) then powerlevel=powerlevel/1.5 end
	if isParalyzed(saiyan) then powerlevel=powerlevel/5 end
	if isUnconscious(saiyan) then powerlevel=powerlevel/10 end
	if powerlevel == 1/0 or unitIsGod(saiyan) then
		return "immeasurable"
	else
		return math.floor(powerlevel)
	end
end

local function positionIsValid(x,y,z)
	local occupancy = dfhack.maps.getTileBlock(x,y,z).occupancy[x%16][y%16]
	local tiletype = getTileType(x,y,z)
	local attrs = df.tiletype.attrs[tiletype]
	if occupancy.building~=0 or occupancy.unit or not dfhack.maps.isValidTilePos(x,y,z) or attrs.shape == df.tiletype_shape.WALL  then return false else return true end
end

local dialog = require('gui.dialogs')

local function teleport(player,unitID)
	local unit = df.global.world.units.all[unitID]
	local playeroccupancy = dfhack.maps.getTileBlock(player.pos).occupancy[player.pos.x%16][player.pos.y%16]
	local teleportToPosX = unit.pos.x
	local teleportToPosY = unit.pos.y
	local timesTried = 0
	teleportToPosY = unit.pos.y - 1
	repeat
		if timesTried > 4 then qerror("Failed to teleport.") end
		local hasNotTried = true
		if teleportToPosY < unit.pos.y and hasNotTried then
			teleportToPosY = unit.pos.y
			teleportToPosX = unit.pos.x-1 
			hasNotTried = false
		end
		if teleportToPosX < unit.pos.x and hasNotTried then
			teleportToPosX = unit.pos.x
			teleportToPosY = unit.pos.y+1
			hasNotTried = false
		end
		if teleportToPosY > unit.pos.y and hasNotTried then
			teleportToPosY = unit.pos.y
			teleportToPosX = unit.pos.x+1 
			hasNotTried = false
		end
		if teleportToPosX > unit.pos.x and hasNotTried then
			teleportToPosX = unit.pos.x
			teleportToPosY = unit.pos.y-1
			hasNotTried = false
		end
		timesTried = timesTried + 1
	until positionIsValid(teleportToPosX,teleportToPosY,unit.pos.z)
	dfhack.gui.showAnnouncement("You put two fingers up to your head and concentrate...",11)
	player.pos.x = teleportToPosX
	player.pos.y = teleportToPosY
	player.pos.z = unit.pos.z
	if not player.flags1.on_ground then playeroccupancy.unit = false else playeroccupancy.unit_grounded = false end
end

function selectUnit() --taken straight from here, but edited so I can understand it better: https://gist.github.com/warmist/4061959/... again. Also edited for syndromeTrigger, but in a completely different way.
    local creatures=df.global.world.units.all
    local tbl={}
    local tunit=df.global.world.units.active[0]
    for k,creature in ipairs(creatures) do
		local plevel=math.ceil(getPowerLevel(creature))
		local racename=df.creature_raw.find(creature.race).caste[creature.caste].caste_name[0]
		table.insert(tbl,{racename.." "..plevel.." ".. (creature==tunit and "(You!)" or ""),nil,k})
    end
    local f=function(name,C)
        teleport(tunit,C[3])
    end
	dialog.showListPrompt("Left is species, right is power level.","Choose creature to teleport to:",COLOR_WHITE,tbl,f)
end

selectUnit()