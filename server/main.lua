local QBCore = nil
local ESX = nil

CreateThread(function()
    if Config.Framework == 'auto' or Config.Framework == 'qb' then
        if GetResourceState('qb-core') == 'started' then
            QBCore = exports['qb-core']:GetCoreObject()
        end
    end
    if (Config.Framework == 'auto' or Config.Framework == 'esx') and not QBCore then
        if GetResourceState('es_extended') == 'started' then
            ESX = exports['es_extended']:getSharedObject()
        end
    end
end)

local currentWeather = Config.StartWeather
local masterSeconds = ((Config.BaseTime or 8) * 3600) + ((Config.TimeOffset or 0) * 60)
local isTimeFrozen = Config.FreezeTime
local isBlackout = Config.Blackout
local dynamicWeather = Config.DynamicWeather
local weatherInterval = Config.NewWeatherTimer
local timeSpeed = Config.TimeSpeed or 1
local weatherTimer = weatherInterval
local tableName = Config.DatabaseTable or 'ft_weathersystem'
local dbSaveTimer = nil

if Config.RealTimeSync then
    local d = Config.RealTimeUTC and os.date('!*t') or os.date('*t')
    masterSeconds = (d.hour * 3600) + (d.min * 60) + (d.sec or 0)
end

local function executeQuery(query, params, cb)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute(query, params or {}, cb)
    elseif GetResourceState('mysql-async') == 'started' then
        MySQL.Async.execute(query, params or {}, cb)
    elseif GetResourceState('ghmattimysql') == 'started' then
        exports.ghmattimysql:execute(query, params or {}, cb)
    else
        if cb then cb(nil) end
    end
end

local function fetchQuery(query, params, cb)
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    elseif GetResourceState('mysql-async') == 'started' then
        MySQL.Async.fetchAll(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    elseif GetResourceState('ghmattimysql') == 'started' then
        exports.ghmattimysql:execute(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    else
        if cb then cb(nil) end
    end
end

local function saveStateToKVP()
    local state = {
        weather = currentWeather,
        time_seconds = math.floor(masterSeconds),
        freeze_time = isTimeFrozen,
        blackout = isBlackout,
        dynamic_weather = dynamicWeather,
        weather_interval = weatherInterval,
        time_speed = timeSpeed
    }
    SetResourceKvp('ft_weathersystem_state', json.encode(state))
end

local function saveStateToDB()
    if not Config.SaveToDatabase then return end

    saveStateToKVP()

    local hasSql = (GetResourceState('oxmysql') == 'started') or
                   (GetResourceState('mysql-async') == 'started') or
                   (GetResourceState('ghmattimysql') == 'started')

    if not hasSql then return end

    local query = string.format([[
        INSERT INTO `%s` (`id`, `weather`, `time_seconds`, `freeze_time`, `blackout`, `dynamic_weather`, `weather_interval`, `time_speed`)
        VALUES (1, @weather, @time_seconds, @freeze_time, @blackout, @dynamic_weather, @weather_interval, @time_speed)
        ON DUPLICATE KEY UPDATE
        `weather` = VALUES(`weather`),
        `time_seconds` = VALUES(`time_seconds`),
        `freeze_time` = VALUES(`freeze_time`),
        `blackout` = VALUES(`blackout`),
        `dynamic_weather` = VALUES(`dynamic_weather`),
        `weather_interval` = VALUES(`weather_interval`),
        `time_speed` = VALUES(`time_speed`);
    ]], tableName)

    local params = {
        ['@weather'] = currentWeather,
        ['@time_seconds'] = math.floor(masterSeconds),
        ['@freeze_time'] = isTimeFrozen and 1 or 0,
        ['@blackout'] = isBlackout and 1 or 0,
        ['@dynamic_weather'] = dynamicWeather and 1 or 0,
        ['@weather_interval'] = weatherInterval,
        ['@time_speed'] = timeSpeed
    }

    executeQuery(query, params)
end

local function queueSaveState()
    if not Config.SaveToDatabase then return end
    if dbSaveTimer then return end
    dbSaveTimer = SetTimeout(500, function()
        dbSaveTimer = nil
        saveStateToDB()
    end)
end

local function broadcastStateSync()
    TriggerClientEvent('ft_weathersystem:client:syncState', -1, {
        weather = currentWeather,
        blackout = isBlackout,
        freezeTime = isTimeFrozen,
        dynamicWeather = dynamicWeather,
        weatherInterval = weatherInterval,
        timeSpeed = timeSpeed
    })
end

CreateThread(function()
    if not Config.SaveToDatabase then return end
    Wait(1500)

    local hasSql = (GetResourceState('oxmysql') == 'started') or
                   (GetResourceState('mysql-async') == 'started') or
                   (GetResourceState('ghmattimysql') == 'started')

    if hasSql then
        local createTableQuery = string.format([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `id` INT(11) NOT NULL DEFAULT 1,
                `weather` VARCHAR(50) NOT NULL DEFAULT '%s',
                `time_seconds` INT(11) NOT NULL DEFAULT %d,
                `freeze_time` TINYINT(1) NOT NULL DEFAULT %d,
                `blackout` TINYINT(1) NOT NULL DEFAULT %d,
                `dynamic_weather` TINYINT(1) NOT NULL DEFAULT %d,
                `weather_interval` INT(11) NOT NULL DEFAULT %d,
                `time_speed` INT(11) NOT NULL DEFAULT %d,
                `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], tableName,
            Config.StartWeather or 'EXTRASUNNY',
            ((Config.BaseTime or 8) * 3600) + ((Config.TimeOffset or 0) * 60),
            Config.FreezeTime and 1 or 0,
            Config.Blackout and 1 or 0,
            Config.DynamicWeather and 1 or 0,
            Config.NewWeatherTimer or 10,
            Config.TimeSpeed or 1
        )

        executeQuery(createTableQuery, {}, function()
            local selectQuery = string.format('SELECT * FROM `%s` WHERE `id` = 1 LIMIT 1', tableName)
            fetchQuery(selectQuery, {}, function(result)
                if result and result[1] then
                    local data = result[1]
                    if data.weather then currentWeather = data.weather end
                    if data.time_seconds then masterSeconds = tonumber(data.time_seconds) or masterSeconds end
                    if data.freeze_time ~= nil then isTimeFrozen = (tonumber(data.freeze_time) == 1 or data.freeze_time == true) end
                    if data.blackout ~= nil then isBlackout = (tonumber(data.blackout) == 1 or data.blackout == true) end
                    if data.dynamic_weather ~= nil then dynamicWeather = (tonumber(data.dynamic_weather) == 1 or data.dynamic_weather == true) end
                    if data.weather_interval then
                        weatherInterval = tonumber(data.weather_interval) or weatherInterval
                        weatherTimer = weatherInterval
                    end
                    if data.time_speed then timeSpeed = tonumber(data.time_speed) or timeSpeed end

                    print('^2[ft_weathersystem]^0 Restored environment state from database.')
                else
                    saveStateToDB()
                    print('^2[ft_weathersystem]^0 Initial environment row saved to database.')
                end

                TriggerClientEvent('ft_weathersystem:client:syncWeather', -1, currentWeather, isBlackout)
                TriggerClientEvent('ft_weathersystem:client:syncTime', -1, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, true)
                broadcastStateSync()
            end)
        end)
    else
        local kvpData = GetResourceKvpString('ft_weathersystem_state')
        if kvpData then
            local success, data = pcall(json.decode, kvpData)
            if success and data then
                if data.weather then currentWeather = data.weather end
                if data.time_seconds then masterSeconds = tonumber(data.time_seconds) or masterSeconds end
                if data.freeze_time ~= nil then isTimeFrozen = data.freeze_time end
                if data.blackout ~= nil then isBlackout = data.blackout end
                if data.dynamic_weather ~= nil then dynamicWeather = data.dynamic_weather end
                if data.weather_interval then
                    weatherInterval = tonumber(data.weather_interval) or weatherInterval
                    weatherTimer = weatherInterval
                end
                if data.time_speed then timeSpeed = tonumber(data.time_speed) or timeSpeed end

                print('^2[ft_weathersystem]^0 Restored environment state from KVP.')

                TriggerClientEvent('ft_weathersystem:client:syncWeather', -1, currentWeather, isBlackout)
                TriggerClientEvent('ft_weathersystem:client:syncTime', -1, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, true)
                broadcastStateSync()
            end
        else
            saveStateToKVP()
        end
    end
end)

local function permDebug(src, msg)
    if Config.DebugPermissions then
        print(('^3[ft_weathersystem]^0 perms %s: %s'):format(tostring(src), msg))
    end
end

local function hasFrameworkGroup(src)
    if Config.UseFrameworkGroups == false then return false end

    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            for _, group in ipairs(Config.AdminGroups or {}) do
                if QBCore.Functions.HasPermission(src, group) or Player.PlayerData.group == group then
                    return true
                end
            end
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local group = xPlayer.getGroup()
            for _, adminGroup in ipairs(Config.AdminGroups or {}) do
                if group == adminGroup then return true end
            end
        end
    end

    return false
end

local warnedAboutExport = false

local function hasAdminMenuPermission(src)
    local cfg = Config.AdminMenu
    if not cfg or cfg.Enabled ~= true then return false end

    local resource = cfg.Resource or 'ft_adminmenu'

    if GetResourceState(resource) ~= 'started' then
        permDebug(src, ('admin menu "%s" is not started'):format(resource))
        return false
    end

    local ok, allowed = pcall(function()
        return exports[resource]:HasPermission(src, cfg.Permission or '')
    end)

    if not ok then

        if not warnedAboutExport then
            warnedAboutExport = true
            print(('^1[ft_weathersystem] %s has no HasPermission export (%s). Update ft_adminmenu, or set Config.AdminMenu.Enabled = false.^0')
                :format(resource, tostring(allowed)))
        end
        return false
    end

    return allowed == true
end

local function hasAce(src)
    if Config.UseAce == false then return false end

    for _, ace in ipairs(Config.AceObjects or {}) do
        if IsPlayerAceAllowed(src, ace) then return true end
    end

    return false
end

local function hasAdminPermission(src)

    if src == 0 then return true end

    if hasFrameworkGroup(src) then
        permDebug(src, 'allowed by framework group')
        return true
    end

    if hasAdminMenuPermission(src) then
        permDebug(src, ('allowed by %s (%s)')
            :format(Config.AdminMenu.Resource or 'ft_adminmenu',
                    (Config.AdminMenu.Permission or '') ~= '' and Config.AdminMenu.Permission or 'any admin'))
        return true
    end

    if hasAce(src) then
        permDebug(src, 'allowed by ace')
        return true
    end

    permDebug(src, 'refused by every source')
    return false
end

local function notifyPlayer(src, message, msgType)
    if src == 0 then
        print(message)
        return
    end
    if QBCore then
        TriggerClientEvent('QBCore:Notify', src, message, msgType or 'primary')
    elseif ESX then
        TriggerClientEvent('esx:showNotification', src, message)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^3[Weather]^0', message } })
    end
end

local function setWeather(type)
    local target = string.upper(type or '')
    local valid = false
    for _, w in ipairs(Config.AvailableWeatherTypes) do
        if w == target then
            valid = true
            break
        end
    end
    if not valid then return false end

    currentWeather = target
    weatherTimer = weatherInterval
    TriggerClientEvent('ft_weathersystem:client:syncWeather', -1, currentWeather, isBlackout)
    broadcastStateSync()
    queueSaveState()
    return true
end

local function setTime(hour, minute)
    local h = tonumber(hour)
    local m = tonumber(minute) or 0
    if not h or h < 0 or h > 23 or m < 0 or m > 59 then
        return false
    end

    masterSeconds = (h * 3600) + (m * 60)
    TriggerClientEvent('ft_weathersystem:client:syncTime', -1, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, true)
    queueSaveState()
    return true
end

local function setBlackout(state)
    if state == nil then
        isBlackout = not isBlackout
    else
        isBlackout = state == true
    end
    TriggerClientEvent('ft_weathersystem:client:syncWeather', -1, currentWeather, isBlackout)
    broadcastStateSync()
    queueSaveState()
    return isBlackout
end

local function setTimeFreeze(state)
    if state == nil then
        isTimeFrozen = not isTimeFrozen
    else
        isTimeFrozen = state == true
    end
    TriggerClientEvent('ft_weathersystem:client:syncTime', -1, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, false)
    broadcastStateSync()
    queueSaveState()
    return isTimeFrozen
end

local function setDynamicWeather(state)
    if state == nil then
        dynamicWeather = not dynamicWeather
    else
        dynamicWeather = state == true
    end
    broadcastStateSync()
    queueSaveState()
    return dynamicWeather
end

local function setWeatherInterval(interval)
    local num = tonumber(interval)
    if num and num >= 1 and num <= 120 then
        weatherInterval = num
        weatherTimer = num
        broadcastStateSync()
        queueSaveState()
        return true
    end
    return false
end

local function setTimeSpeed(speed)
    local num = tonumber(speed)
    if num and num >= 1 and num <= 60 then
        timeSpeed = num
        TriggerClientEvent('ft_weathersystem:client:syncTime', -1, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, false)
        broadcastStateSync()
        queueSaveState()
        return true
    end
    return false
end

local function nextWeatherStage()
    if currentWeather == 'CLEAR' or currentWeather == 'CLOUDS' or currentWeather == 'EXTRASUNNY' then
        currentWeather = (math.random(1, 5) > 2) and 'CLEARING' or 'OVERCAST'
    elseif currentWeather == 'CLEARING' or currentWeather == 'OVERCAST' then
        local roll = math.random(1, 6)
        if roll == 1 then
            currentWeather = (currentWeather == 'CLEARING') and 'FOGGY' or 'RAIN'
        elseif roll == 2 then
            currentWeather = 'CLOUDS'
        elseif roll == 3 then
            currentWeather = 'CLEAR'
        elseif roll == 4 then
            currentWeather = 'EXTRASUNNY'
        elseif roll == 5 then
            currentWeather = 'SMOG'
        else
            currentWeather = 'FOGGY'
        end
    elseif currentWeather == 'THUNDER' or currentWeather == 'RAIN' then
        currentWeather = 'CLEARING'
    elseif currentWeather == 'SMOG' or currentWeather == 'FOGGY' then
        currentWeather = 'CLEAR'
    else
        currentWeather = 'CLEAR'
    end
    TriggerClientEvent('ft_weathersystem:client:syncWeather', -1, currentWeather, isBlackout)
    broadcastStateSync()
    queueSaveState()
end

RegisterNetEvent('ft_weathersystem:server:requestSync', function()
    local src = source
    TriggerClientEvent('ft_weathersystem:client:syncWeather', src, currentWeather, isBlackout)
    TriggerClientEvent('ft_weathersystem:client:syncTime', src, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, true)
    TriggerClientEvent('ft_weathersystem:client:syncState', src, {
        weather = currentWeather,
        blackout = isBlackout,
        freezeTime = isTimeFrozen,
        dynamicWeather = dynamicWeather,
        weatherInterval = weatherInterval,
        timeSpeed = timeSpeed
    })
end)

RegisterNetEvent('ft_weathersystem:server:setWeather', function(weather)
    local src = source
    if not hasAdminPermission(src) then return end
    if setWeather(weather) then
        notifyPlayer(src, _L('weather_updated', string.upper(weather)), 'success')
    else
        notifyPlayer(src, _L('weather_invalid'), 'error')
    end
end)

RegisterNetEvent('ft_weathersystem:server:setTime', function(hour, minute)
    local src = source
    if not hasAdminPermission(src) then return end
    if setTime(hour, minute) then
        notifyPlayer(src, _L('time_updated', tonumber(hour), tonumber(minute or 0)), 'success')
    else
        notifyPlayer(src, _L('time_invalid'), 'error')
    end
end)

RegisterNetEvent('ft_weathersystem:server:toggleBlackout', function(state)
    local src = source
    if not hasAdminPermission(src) then return end
    local newBlackout = setBlackout(state)
    if newBlackout then
        notifyPlayer(src, _L('blackout_enabled'), 'primary')
    else
        notifyPlayer(src, _L('blackout_disabled'), 'primary')
    end
end)

RegisterNetEvent('ft_weathersystem:server:toggleFreezeTime', function(state)
    local src = source
    if not hasAdminPermission(src) then return end
    local newFreeze = setTimeFreeze(state)
    if newFreeze then
        notifyPlayer(src, _L('time_frozen'), 'primary')
    else
        notifyPlayer(src, _L('time_unfrozen'), 'primary')
    end
end)

RegisterNetEvent('ft_weathersystem:server:toggleDynamicWeather', function(state)
    local src = source
    if not hasAdminPermission(src) then return end
    local newDynamic = setDynamicWeather(state)
    if newDynamic then
        notifyPlayer(src, _L('weather_unfrozen'), 'primary')
    else
        notifyPlayer(src, _L('weather_frozen'), 'primary')
    end
end)

RegisterNetEvent('ft_weathersystem:server:setInterval', function(interval)
    local src = source
    if not hasAdminPermission(src) then return end
    if setWeatherInterval(interval) then
        notifyPlayer(src, _L('interval_updated', interval), 'success')
    end
end)

RegisterNetEvent('ft_weathersystem:server:setTimeSpeed', function(speed)
    local src = source
    if not hasAdminPermission(src) then return end
    if setTimeSpeed(speed) then
        notifyPlayer(src, _L('timespeed_updated', speed), 'success')
    end
end)

RegisterCommand(Config.UICommand, function(source)
    if not hasAdminPermission(source) then
        notifyPlayer(source, _L('no_permission'), 'error')
        return
    end
    local totalSec = math.floor(masterSeconds)
    local h = math.floor(totalSec / 3600) % 24
    local m = math.floor((totalSec % 3600) / 60)
    TriggerClientEvent('ft_weathersystem:client:openUI', source, {
        weather = currentWeather,
        blackout = isBlackout,
        hour = h,
        minute = m,
        freezeTime = isTimeFrozen,
        dynamicWeather = dynamicWeather,
        weatherInterval = weatherInterval,
        timeSpeed = timeSpeed
    })
end, false)

RegisterCommand('weather', function(source, args)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    if not args[1] then return notifyPlayer(source, _L('weather_invalid'), 'error') end
    if setWeather(args[1]) then
        notifyPlayer(source, _L('weather_updated', string.upper(args[1])), 'success')
    else
        notifyPlayer(source, _L('weather_invalid'), 'error')
    end
end, false)

RegisterCommand('time', function(source, args)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    if not args[1] then return notifyPlayer(source, _L('time_invalid'), 'error') end
    if setTime(args[1], args[2] or 0) then
        notifyPlayer(source, _L('time_updated', tonumber(args[1]), tonumber(args[2] or 0)), 'success')
    else
        notifyPlayer(source, _L('time_invalid'), 'error')
    end
end, false)

RegisterCommand('freezetime', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    local frozen = setTimeFreeze()
    notifyPlayer(source, frozen and _L('time_frozen') or _L('time_unfrozen'), 'primary')
end, false)

RegisterCommand('freezeweather', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    local dyn = setDynamicWeather()
    notifyPlayer(source, dyn and _L('weather_unfrozen') or _L('weather_frozen'), 'primary')
end, false)

RegisterCommand('blackout', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    local state = setBlackout()
    notifyPlayer(source, state and _L('blackout_enabled') or _L('blackout_disabled'), 'primary')
end, false)

RegisterCommand('morning', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    setTime(9, 0)
    notifyPlayer(source, _L('time_updated', 9, 0), 'success')
end, false)

RegisterCommand('noon', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    setTime(12, 0)
    notifyPlayer(source, _L('time_updated', 12, 0), 'success')
end, false)

RegisterCommand('evening', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    setTime(18, 0)
    notifyPlayer(source, _L('time_updated', 18, 0), 'success')
end, false)

RegisterCommand('night', function(source)
    if not hasAdminPermission(source) then return notifyPlayer(source, _L('no_permission'), 'error') end
    setTime(23, 0)
    notifyPlayer(source, _L('time_updated', 23, 0), 'success')
end, false)

CreateThread(function()
    local lastTick = os.time()
    while true do
        Wait(1000)
        local now = os.time()
        local elapsed = now - lastTick
        lastTick = now

        if not isTimeFrozen then
            if Config.RealTimeSync then
                local d = Config.RealTimeUTC and os.date('!*t') or os.date('*t')
                masterSeconds = (d.hour * 3600) + (d.min * 60) + (d.sec or 0)
            else
                local rate = 30.0 * (timeSpeed or 1)
                masterSeconds = (masterSeconds + (elapsed * rate)) % 86400
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        TriggerClientEvent('ft_weathersystem:client:syncTime', -1, masterSeconds, isTimeFrozen, timeSpeed, Config.RealTimeSync, false)
    end
end)

CreateThread(function()
    while true do
        Wait(300000)
        TriggerClientEvent('ft_weathersystem:client:syncWeather', -1, currentWeather, isBlackout)
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        if dynamicWeather then
            weatherTimer = weatherTimer - 1
            if weatherTimer <= 0 then
                nextWeatherStage()
                weatherTimer = weatherInterval
            end
        end
    end
end)

exports('getWeatherState', function() return currentWeather end)
exports('getBlackoutState', function() return isBlackout end)
exports('getTimeFreezeState', function() return isTimeFrozen end)
exports('getDynamicWeather', function() return dynamicWeather end)
exports('getWeatherInterval', function() return weatherInterval end)
exports('getTimeSpeed', function() return timeSpeed end)
exports('getTime', function()
    local totalSec = math.floor(masterSeconds)
    return math.floor(totalSec / 3600) % 24, math.floor((totalSec % 3600) / 60)
end)

exports('setWeather', setWeather)
exports('setTime', setTime)
exports('setBlackout', setBlackout)
exports('setTimeFreeze', setTimeFreeze)
exports('setDynamicWeather', setDynamicWeather)
exports('setWeatherInterval', setWeatherInterval)
exports('setTimeSpeed', setTimeSpeed)
exports('nextWeatherStage', nextWeatherStage)
