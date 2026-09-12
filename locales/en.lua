Locales = Locales or {}

function _L(str, ...)
    local lang = Config and Config.Language or 'en'
    if Locales[lang] and Locales[lang][str] then
        return string.format(Locales[lang][str], ...)
    elseif Locales['en'] and Locales['en'][str] then
        return string.format(Locales['en'][str], ...)
    end
    return str
end

Locales['en'] = {
    ['weather_updated'] = 'Weather has been updated to: %s',
    ['weather_invalid'] = 'Invalid weather type provided!',
    ['time_updated'] = 'Time has been set to: %02d:%02d',
    ['time_invalid'] = 'Invalid time provided (Hour: 0-23, Minute: 0-59)!',
    ['time_frozen'] = 'Time progression has been frozen.',
    ['time_unfrozen'] = 'Time progression has been unfrozen.',
    ['weather_frozen'] = 'Dynamic weather has been frozen.',
    ['weather_unfrozen'] = 'Dynamic weather has been enabled.',
    ['blackout_enabled'] = 'City blackout has been enabled.',
    ['blackout_disabled'] = 'City blackout has been disabled.',
    ['interval_updated'] = 'Weather change interval set to %s minutes.',
    ['timespeed_updated'] = 'Time speed multiplier set to %sx.',
    ['no_permission'] = 'You do not have permission to use this command.'
}
