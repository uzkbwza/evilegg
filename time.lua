local time = {}

time.time = 0
time.tick = 0
time.frames = 0

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
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


return time
