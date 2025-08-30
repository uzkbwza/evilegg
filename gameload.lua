
EGG_ROOM_START = 20
EGG_ROOM_PERIOD = 20

if debug.enabled then
	function Screens.LevelEditor:custom_map_process(tab)
		print("custom_map_process")
	end
end

graphics.load_image_font("score_pickup_font", "font_score_pickup", "0123456789G")
graphics.load_image_font("greenoid", "font_greenoid", "0123456789GL,.KP")
graphics.load_image_font("score_pickup_font_white", "font_score_pickup_white", "0123456789")

local font_chars = " ABCDEFGHIJKLMNOPQRSTUVWXYZ+-1234567890[].×/,:'←→!?\"✓_⮌𝓛𝓡◉ⓁⓇ ◐◑⇥%‼⏲◒┕┍⬥⮞⮟⮜⮝ⓐⓑⓧⓨⒺ$"
graphics.load_image_font("image_font1", "font_font1", font_chars)
graphics.load_image_font("image_font2", "font_font2", font_chars)
graphics.load_image_font("image_neutralfont1", "font_neutralfont1", " ABCDEFGHIJKLMNOPQRSTUVWXYZ+-1234567890[].×/,:'←→!?\"✓_⮌abcdefghijklmnopqrstuvwxyz‼⏲")

graphics.load_image_font("image_bigfont1", "font_bigfont1", " APRHOSITNCXDEFQUVGLKBMWJZY")

graphics.load_image_font("egglanguage", "font_egglanguage", "abcdefghijklmnopqrstuvwxyz")
graphics.load_image_font("bignum", "font_bignum", "1234567890.,x")

---@diagnostic disable-next-line: lowercase-global
control_glyphs = {
	rt = "𝓡",
    lt = "𝓛",
    lb = "┕",
    rb = "┍",
	r = "Ⓡ",
	l = "Ⓛ",
	space = " ",
	start = "◉",
    lmb = "◐",
    rmb = "◑",
    mmb = "◒",
    tab = "⇥",
    dpl = "⮜",
    dpr = "⮞",
    dpu = "⮝",
    dpd = "⮟",
    back = "⬥",
    a = "ⓐ",
    b = "ⓑ",
    x = "ⓧ",
    y = "ⓨ",
    esc = "Ⓔ",
}

remap_keys = {
	triggerright = "rt",
    triggerleft = "lt",
    leftshoulder = "lb",
    rightshoulder = "rb",
    start = "start",
    select = "select",
    back = "back",
    pause = "pause",
    menu = "menu",
    restart = "restart",
    exit = "exit",
    dpleft = "dpl",
    dpright = "dpr",
    dpup = "dpu",
    dpdown = "dpd",
    leftstick = "l",
    rightstick = "r",
    escape = "esc",
}

BaseEnemy = require("obj.Spawn.Enemy.BaseEnemy")
Worlds = filesystem.get_modules("world")
