local function fixOverflow(a,max)
	max=max or 400000000
	return a < 0 and max or a
end

local function checkOverflows(unit)
	for _,attribute in ipairs(unit.body.physical_attrs) do
		attribute.value=fixOverflow(attribute.value)
	end
	unit.body.physical_attrs.STRENGTH.value=fixOverflow(unit.body.physical_attrs.STRENGTH.value,2512195) --http://www.bay12games.com/dwarves/mantisbt/view.php?id=8333
	for _,soul in ipairs(unit.status.souls) do --soul[0] is a pointer to the current soul
		for _,attribute in ipairs(soul.mental_attrs) do
			attribute.value=fixOverflow(attribute.value)
		end
	end
	unit.body.blood_max=fixOverflow(unit.body.blood_max)
	unit.body.blood_count=fixOverflow(unit.body.blood_count)
end

local function fixAllOverflows()
	for _,unit in ipairs(df.global.world.units.active) do
		checkOverflows(unit)
	end
end

dfhack.onStateChange.overflow = function(code) --Many thanks to Warmist for pointing this out to me!
	if code==SC_WORLD_LOADED then
		dfhack.timeout(200,'ticks',callback)
	end
end

function overflow()
	fixAllOverflows()
	dfhack.timeout(200,'ticks',overflow)
end