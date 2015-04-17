local utils=require('utils')

validArgs = validArgs or utils.invert({
 'unit',
 'boost',
 'time',
 'fraction'
})

local args = utils.processArgs({...}, validArgs)

local ki = dfhack.script_environment('dragonball/ki')

local unit=args.unit

local old_max=ki.get_max_ki(unit)

ki.adjust_max_ki(unit,(old_max*args.boost)-old_max)

local old_ki=ki.get_ki(unit)

ki.adjust_ki(unit,ki.(old_ki*args.boost)-old_ki)

ki.set_ki_investment(unit,args.fraction)

if args.time~=0 then
    dfhack.timeout(args.time,'ticks',function() ki.adjust_max_ki(unit,-old_max*args.boost) ki.adjust_ki(unit,-old_ki*args.boost) ki.set_ki_investment(unit,1000) end)
    dfhack.persistent.save({key='KI_BOOST/'..unit,ints={args.unit,args.old_max}))
end

dfhack.onStateChange.ki_boost=function(code)
    if code==SC_WORLD_LOADED then
        for k,v in ipairs(dfhack.persistent.get_all('KI_BOOST',true) do
            ki.adjust_max_ki(v.ints[1],v.ints[2],true)
            ki.adjust_ki(v.ints[1],1)
            ki.set_ki_investment(v.ints[1],1000)
        end
    end
end