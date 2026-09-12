Config = {}

Config.Framework = 'auto'                       -- auto / esx / qb / standalone

Config.Language = 'en'                          -- file in locales/

-- permissions, a player passing any one of the three is allowed
Config.UseFrameworkGroups = true

Config.AdminGroups = {
    'admin',
    'superadmin',
    'god'
}

Config.AdminMenu = {
    Enabled    = true,
    Resource   = 'ft_adminmenu',
    Permission = 'weatherTab',
}

Config.UseAce = true

-- add_ace group.admin ft_weather.admin allow
Config.AceObjects = {
    'command',
    'ft_weather.admin',
}

Config.DebugPermissions = false                 -- prints why someone was refused

Config.UICommand = 'weatherui'

-- defaults, only used on first ever start, after that the saved state wins
Config.StartWeather = 'EXTRASUNNY'
Config.BaseTime = 8                             -- hour
Config.TimeOffset = 0
Config.FreezeTime = false
Config.Blackout = false
Config.BlackoutVehicle = false
Config.DynamicWeather = true                    -- weather changes on its own
Config.NewWeatherTimer = 10                     -- minutes between changes
Config.TimeSpeed = 1                            -- 1 = 1 game minute per real second

Config.SaveToDatabase = true                    -- false = kvp only
Config.DatabaseTable = 'ft_weathersystem'       -- created automatically

Config.RealTimeSync = false                     -- follow real world clock, ignores TimeSpeed
Config.RealTimeUTC = false

-- list shown in the dashboard
Config.AvailableWeatherTypes = {
    'EXTRASUNNY',
    'CLEAR',
    'NEUTRAL',
    'SMOG',
    'FOGGY',
    'OVERCAST',
    'CLOUDS',
    'CLEARING',
    'RAIN',
    'THUNDER',
    'SNOW',
    'BLIZZARD',
    'SNOWLIGHT',
    'XMAS',
    'HALLOWEEN'
}
