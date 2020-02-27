local coroutines_for_funcs = {}

local function_priorities = {}

local function_tables = {}

local current_runs = {}

local function genCoroutineFunc(f)
    return function(run,start_time,time_not_to_overrun)
        while #run>0 do
            local status,err = pcall(f,table.remove(run))
            if not status then
                print(err)
            end
            if (os.clock() - start_time) > time_not_to_overrun then
                run, start_time, time_not_to_overrun = coroutine.yield(run)
            end
        end
    end
end

local function run_schedule()
    local co = coroutine
    local time_not_to_overrun = math.max(0.001,0.5/df.global.enabler.fps)
    for f,c in pairs(coroutines_for_funcs) do
        local actual_time = math.max(time_not_to_overrun,0.05/function_priorities[f])
        if(co.status(c) == "dead") then
            current_runs[f] = {}
            local run = current_runs[f]
            for k,v in ipairs(function_tables[f]) do
                table.insert(run,v)
            end
            coroutines_for_funcs[f] = co.create(genCoroutineFunc(f))
            c = coroutines_for_funcs[f]
        end
        local ran = false
        ran,current_runs[f] = co.resume(c,current_runs[f],os.clock(),actual_time)
    end
end

function add_to_schedule(tbl,f,priority) -- 1 to 50, lower = higher
    coroutines_for_funcs[f] = coroutine.create(genCoroutineFunc(tbl))
    function_priorities[f] = priority
    function_tables[f] = tbl
    current_runs[f] = {}
end

function start_scheduler()
    require('repeat-util').scheduleEvery('Scheduler',1,'ticks',run_schedule)
end