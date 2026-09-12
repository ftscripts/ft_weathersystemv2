local currentWeather = Config.StartWeather
local lastWeather = currentWeather
local currentSeconds = ((Config.BaseTime or 8) * 3600)
local isTimeFrozen = Config.FreezeTime
local isBlackout = Config.Blackout
local dynamicWeather = Config.DynamicWeather
local weatherInterval = Config.NewWeatherTimer
local timeSpeed = Config.TimeSpeed or 1
local isRealTimeSync = Config.RealTimeSync
local syncDisabled = false
local isUIOpen = false
local lastSentMinute = -1
local lastSentHour = -1

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('ft_weathersystem:server:requestSync')
end)

RegisterNetEvent('esx:playerLoaded', function()
    TriggerServerEvent('ft_weathersystem:server:requestSync')
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('ft_weathersystem:server:requestSync')
end)

CreateThread(function()
    TriggerServerEvent('ft_weathersystem:server:requestSync')
end)

RegisterNetEvent('ft_weathersystem:client:syncWeather', function(weather, blackout)
    currentWeather = weather
    isBlackout = blackout

    if isUIOpen then
        SendNUIMessage({
            action = 'syncWeather',
            weather = currentWeather,
            blackout = isBlackout
        })
    end
end)

RegisterNetEvent('ft_weathersystem:client:syncTime', function(serverSec, freeze, speed, realTime, snap)
    isTimeFrozen = freeze
    if speed then timeSpeed = speed end
    if realTime ~= nil then isRealTimeSync = realTime end

    if snap or math.abs(currentSeconds - serverSec) > 120 then
        currentSeconds = serverSec
    end
end)

RegisterNetEvent('ft_weathersystem:client:syncState', function(data)
    if data.weather ~= nil then currentWeather = data.weather end
    if data.blackout ~= nil then isBlackout = data.blackout end
    if data.freezeTime ~= nil then isTimeFrozen = data.freezeTime end
    if data.dynamicWeather ~= nil then dynamicWeather = data.dynamicWeather end
    if data.weatherInterval ~= nil then weatherInterval = data.weatherInterval end
    if data.timeSpeed ~= nil then timeSpeed = data.timeSpeed end

    if isUIOpen then
        SendNUIMessage({
            action = 'syncState',
            weather = currentWeather,
            blackout = isBlackout,
            freezeTime = isTimeFrozen,
            dynamicWeather = dynamicWeather,
            weatherInterval = weatherInterval,
            timeSpeed = timeSpeed
        })
    end
end)

RegisterNetEvent('ft_weathersystem:client:enableSync', function()
    syncDisabled = false
    TriggerServerEvent('ft_weathersystem:server:requestSync')
end)

RegisterNetEvent('ft_weathersystem:client:disableSync', function()
    syncDisabled = true
    SetRainLevel(0.0)
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')
    NetworkOverrideClockTime(18, 0, 0)
end)

RegisterNetEvent('ft_weathersystem:client:openUI', function(data)
    isUIOpen = true
    lastSentHour = data.hour
    lastSentMinute = data.minute
    if data.weather ~= nil then currentWeather = data.weather end
    if data.blackout ~= nil then isBlackout = data.blackout end
    isTimeFrozen = data.freezeTime
    dynamicWeather = data.dynamicWeather
    weatherInterval = data.weatherInterval
    timeSpeed = data.timeSpeed

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openWeather',
        weather = currentWeather,
        blackout = isBlackout,
        hour = data.hour,
        minute = data.minute,
        freezeTime = data.freezeTime,
        dynamicWeather = data.dynamicWeather,
        weatherInterval = data.weatherInterval,
        timeSpeed = data.timeSpeed
    })
end)

RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('ft_weathersystem:server:setWeather', data.mode)
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('ft_weathersystem:server:setTime', data.hour, data.minute)
    cb('ok')
end)

RegisterNUICallback('freezeTime', function(_, cb)
    TriggerServerEvent('ft_weathersystem:server:toggleFreezeTime')
    cb('ok')
end)

RegisterNUICallback('dynamicweather', function(_, cb)
    TriggerServerEvent('ft_weathersystem:server:toggleDynamicWeather')
    cb('ok')
end)

RegisterNUICallback('dynamictime', function(_, cb)
    TriggerServerEvent('ft_weathersystem:server:toggleFreezeTime')
    cb('ok')
end)

RegisterNUICallback('toggleBlackout', function(data, cb)
    TriggerServerEvent('ft_weathersystem:server:toggleBlackout', data and data.state)
    cb('ok')
end)

RegisterNUICallback('blackout', function(data, cb)
    TriggerServerEvent('ft_weathersystem:server:toggleBlackout', data and data.state)
    cb('ok')
end)

RegisterNUICallback('setWeatherInterval', function(data, cb)
    TriggerServerEvent('ft_weathersystem:server:setInterval', data.interval)
    cb('ok')
end)

RegisterNUICallback('setTimeSpeed', function(data, cb)
    TriggerServerEvent('ft_weathersystem:server:setTimeSpeed', data.speed)
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

CreateThread(function()
    while true do
        if not syncDisabled then
            if lastWeather ~= currentWeather then
                lastWeather = currentWeather
                SetWeatherTypeOverTime(currentWeather, 15.0)
                Wait(15000)
            end

            Wait(100)
            SetArtificialLightsState(isBlackout)
            SetArtificialLightsStateAffectsVehicles(Config.BlackoutVehicle)
            ClearOverrideWeather()
            ClearWeatherTypePersist()
            SetWeatherTypePersist(lastWeather)
            SetWeatherTypeNow(lastWeather)
            SetWeatherTypeNowPersist(lastWeather)

            if lastWeather == 'XMAS' then
                SetForceVehicleTrails(true)
                SetForcePedFootstepsTracks(true)
            else
                SetForceVehicleTrails(false)
                SetForcePedFootstepsTracks(false)
            end

            if lastWeather == 'RAIN' then
                SetRainLevel(0.3)
            elseif lastWeather == 'THUNDER' then
                SetRainLevel(0.5)
            else
                SetRainLevel(0.0)
            end
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    local lastGameTime = GetGameTimer()

    while true do
        Wait(0)
        local now = GetGameTimer()
        local dt = (now - lastGameTime) / 1000.0
        lastGameTime = now

        if not syncDisabled then
            if not isTimeFrozen then
                local rate = isRealTimeSync and 1.0 or (30.0 * (timeSpeed or 1))
                currentSeconds = (currentSeconds + (dt * rate)) % 86400.0
            end

            local totalSec = math.floor(currentSeconds)
            local hour = math.floor(totalSec / 3600) % 24
            local minute = math.floor((totalSec % 3600) / 60)
            local second = totalSec % 60

            NetworkOverrideClockTime(hour, minute, second)

            if isUIOpen and (minute ~= lastSentMinute or hour ~= lastSentHour) then
                lastSentMinute = minute
                lastSentHour = hour
                SendNUIMessage({
                    action = 'updateTime',
                    hour = hour,
                    minute = minute
                })
            end
        else
            Wait(500)
        end
    end
end)
