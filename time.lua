local time = {}

time.time = 0
time.tick = 0
time.frames = 0

time.scale = 1

TICKRATE = conf.delta_tickrate

ONE_MILLISECOND = TICKRATE / 1000
ONE_SECOND = TICKRATE
ONE_MINUTE = ONE_SECOND * 60
ONE_HOUR = ONE_MINUTE * 60
ONE_DAY = ONE_HOUR * 24
ONE_WEEK = ONE_DAY * 7
ONE_MONTH = ONE_DAY * 30
ONE_YEAR = 3.156e7

return time
