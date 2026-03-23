-- Calculate Easter Sunday for a given year (Anonymous Gregorian algorithm)
function getEasterDate(year)
    local a = year % 19
    local b = math.floor(year / 100)
    local c = year % 100
    local d = math.floor(b / 4)
    local e = b % 4
    local f = math.floor((b + 8) / 25)
    local g = math.floor((b - f + 1) / 3)
    local h = (19 * a + b - d - g + 15) % 30
    local i = math.floor(c / 4)
    local k = c % 4
    local l = (32 + 2 * e + 2 * i - h - k) % 7
    local m = math.floor((a + 11 * h + 22 * l) / 451)
    local month = math.floor((h + l - 7 * m + 114) / 31)
    local day = ((h + l - 7 * m + 114) % 31) + 1
    return month, day
end

-- Check if a given date is Easter Sunday
function isEaster(year, month, day)
    local easterMonth, easterDay = getEasterDate(year)
    return month == easterMonth and day == easterDay
end

local is_easter = false

-- Check today's date
local today = os.date("*t")

is_easter = isEaster(today.year, today.month, today.day)

if debug.enabled then
    print("\nEaster dates:")
    for year = 2024, 2030 do
        local m, d = getEasterDate(year)
        print(string.format("  %d: %s %d", year, os.date("%B", os.time { year = year, month = m, day = d }), d))
    end
end

local force_easter = false
IS_EASTER = is_easter or (debug.enabled and force_easter)
