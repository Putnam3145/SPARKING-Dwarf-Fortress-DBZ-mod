local function unitCanUseKi(unit_id)
    local unit = df.unit.find(unit_id)
    if not unit then return false end
    for _,class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if class.value=='NATURAL_KI' then return true end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for _,synclass in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            if synclass.value == "KI" then return true end
        end
    end
    return false
end

function adjust_ki_mult_persist(unit_id,persist_key,amount)
    if not persist_key then return false end
    local persist=dfhack.persistent.save({key='DBZ_KI/'..persist_key..'/'..unit_id})
    persist.ints[1]=persist.ints[1]<0 and amount or persist.ints[1]*amount
    persist:save()
end

function adjust_ki_boost_persist(unit_id,persist_key,amount)
    if not persist_key then return false end
    local persist=dfhack.persistent.save({key='DBZ_KI/'..persist_key..'/'..unit_id})
    persist.ints[2]=persist.ints[2]<0 and amount or persist.ints[2]+amount
    persist:save()
end

local function get_ki_mult_persist(unit_id,persist_key)
    if not persist_key then return 1 end
    local persist=dfhack.persistent.get('DBZ_KI/'..persist_key..'/'..unit_id)
    if persist then return persist.ints[1] end
end

local function get_ki_boost_persist(unit_id,persist_key)
    if not persist_key then return 0 end
    local persist=dfhack.persistent.get('DBZ_KI/'..persist_key..'/'..unit_id)
    if persist then return persist.ints[2] end
end

local function get_ki_boost(unit)
    local multiplier,boost=1,0
    for _,class in ipairs(df.creature_raw.find(unit.race).caste[unit.caste].creature_class) do
        if class.value:find('KI_MULTIPLIER_') then 
            multiplier=multiplier*(tonumber(class.value:sub(15)) or get_ki_mult_persist(unit.id,class.value:sub(15)) or 1)
        elseif class.value:find('KI_BOOST_') then
            boost=boost+(tonumber(class.value:sub(10)) or get_ki_boost_persist(synclass.value:sub(10)) or 0)
        end
    end
    for _,syndrome in ipairs(unit.syndromes.active) do
        for __,synclass in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            if synclass.value:find('KI_MULTIPLIER_') then 
                multiplier=multiplier*(tonumber(synclass.value:sub(15)) or get_ki_mult_persist(unit.id,synclass.value:sub(15)) or 1)
            elseif synclass.value:find('KI_BOOST_') then
                boost=boost+(tonumber(synclass.value:sub(10)) or get_ki_boost_persist(synclass.value:sub(10)) or 0)
            end
        end
    end
    return multiplier,boost
end

local function calculate_max_ki(unit)
    local willpower = unit.status.current_soul.mental_attrs.WILLPOWER.value
    local focus = unit.status.current_soul.mental_attrs.FOCUS.value
    local endurance = unit.body.physical_attrs.ENDURANCE.value
    local multiplier,boost=get_ki_boost(unit)
    return (willpower+focus+endurance+boost)*multiplier,multiplier,boost
end

local function get_new_fraction(unit)
    for _,syndrome in ipairs(unit.syndromes.active) do
        for __,synclass in ipairs(df.syndrome.find(syndrome.type).syn_class) do
            if synclass.value:find('KI_INVEST_FRACTION_') then
                return tonumber(synclass.value:sub(20))
            end
        end
    end
    return nil
end

function init_ki(unit_id)
    if not unitCanUseKi(unit_id) then
        return false
    end
    local unitKi=dfhack.persistent.save({key='DBZ_KI/'..unit_id})
    local unit=df.unit.find(unit_id)
    if unitKi.ints[2]>0 then
        local boost,multiplier
        unitKi.ints[2],boost,multiplier=calculate_max_ki(unit)
        local new_fraction=get_new_fraction(unit)
        if unitKi.ints[4]==1 then
            if new_fraction then
                unitKi.ints[3]=math.min(new_fraction,unitKi.ints[3])
            else
                unitKi.ints[3]=math.max(100,unitKi.ints[3])
                unitKi.ints[4]=0
            end
        else
            if new_fraction then
                unitKi.ints[4]=1
                unitKi.ints[3]=math.min(new_fraction,unitKi.ints[3])
            end
        end
        unitKi.ints[4]=new_fraction and 1 or 0
        if unitKi.ints[5]~=1 and (boost>0 or multiplier>1) then
            unitKi.ints[5]=1
            unitKi.ints[1]=(unitKi.ints[1]+boost)*multiplier
        elseif unitKi.ints[5]==1 and boost==0 and multiplier==1 then
            unitKi.ints[5]=0
        end
        unitKi:save()
        return unitKi.ints[2]
    end
    local maxKi=calculate_max_ki(unit)
    unitKi.ints[2]=maxKi
    unitKi.ints[1]=maxKi
    unitKi.ints[3]=100
    unitKi:save()
    return unitKi.ints[2]
end

function get_unit_ki_persist_entry(unit_id)
    if not init_ki(unit_id) then
        local notActuallyAKiTable={ints={0,0,1}}
        notActuallyAKiTable.save=function(self)
            return false
        end
        return notActuallyAKiTable
    end
    return dfhack.persistent.save({key='DBZ_KI/'..unit_id})
end

function get_ki_investment(unit_id)
    local unitKi = get_unit_ki_persist_entry(unit_id)
    return math.min(math.ceil(unitKi.ints[2]/unitKi.ints[3]),unitKi.ints[1])
end

function set_ki_investment(unit_id,fraction)
    local unitKi = get_unit_ki_persist_entry(unit_id)
    unitKi.ints[3]=fraction
    unitKi:save()
    return unitKi.ints[3]
end

function get_ki(unit_id)
    return get_unit_ki_persist_entry(unit_id).ints[1]
end

function get_max_ki(unit_id)
    return get_unit_ki_persist_entry(unit_id).ints[2]
end

function adjust_max_ki(unit_id,amount)
    adjust_ki_boost_persist(unit_id,'BASE',amount)
end

function adjust_ki(unit_id,amount,force)
    local unitKi=get_unit_ki_persist_entry(unit_id)
    local unit=df.unit.find(unit_id)
    if unitKi.ints[1]+amount<0 then
        if not force then
            return false
        else
            local castFromHitpoints=unitKi.ints[1]+amount
            unit.body.blood_count=unit.body.blood_count-castFromHitpoints
            unit.counters2.exhaustion=unit.counters2.exhaustion+castFromHitpoints
            unit.counters.pain=unit.counters.pain+castFromHitpoints
            unitKi.ints[1]=0
            unitKi:save()
            return 0
        end
    else
        unitKi.ints[1]=math.max(0,math.min(unitKi.ints[1]+amount,unitKi.ints[2]))
        unitKi:save()
        return unitKi.ints[1]
    end
end