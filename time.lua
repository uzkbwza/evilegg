local time = {}

time.time = 0
time.tick = 0
time.frame = 0

time.scale = 1
time.love_time = 0
time.love_delta = 0

TICKRATE = conf.delta_tickrate

ONE_MILLISECOND = TICKRATE / 1000
ONE_SECOND = TICKRATE
ONE_MINUTE = ONE_SECOND * 60
ONE_HOUR = ONE_MINUTE * 60
ONE_DAY = ONE_HOUR * 24
ONE_WEEK = ONE_DAY * 7
ONE_MONTH = ONE_DAY * 30
ONE_YEAR = 3.156e7

function format_hhmmss(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    seconds = seconds % 60
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%02d:%02d", minutes, seconds)
    end
end

function format_hhmmss_decimal(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local sec = math.floor(seconds % 60)
    local dec = math.floor((seconds - math.floor(seconds)) * 100)
    if hours > 0 then
        return string.format("%02d:%02d:%02d.%02d", hours, minutes, sec, dec)
    else
        return string.format("%02d:%02d.%02d", minutes, sec, dec)
    end
end

function format_hhmmssms(milliseconds)
    local hours = math.floor(milliseconds / 3600000)
    local minutes = math.floor((milliseconds % 3600000) / 60000)
    local seconds = math.floor((milliseconds % 60000) / 1000)
    local ms = milliseconds % 1000
    if hours > 0 then
        return string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, ms)
    else
        return string.format("%02d:%02d.%03d", minutes, seconds, ms)
    end
end

function format_hhmmssms1(milliseconds)
    local hours = math.floor(milliseconds / 3600000)
    local minutes = math.floor((milliseconds % 3600000) / 60000)
    local seconds = math.floor((milliseconds % 60000) / 1000)
    local ms = math.floor((milliseconds % 1000) / 100)
    if hours > 0 then
        return string.format("%02d:%02d:%02d.%01d", hours, minutes, seconds, ms)
    else
        return string.format("%02d:%02d.%01d", minutes, seconds, ms)
    end
end

return time
