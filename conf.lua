local input_presets = require "conf.input_presets"

local lldebuggerPatcher = require("lib.lldebuggerpatcher")

_, steam = pcall(require, "luasteam")

if type(steam) == "table" then
	if not steam.init then 
		steam = nil
	elseif not steam.init() then
		steam = nil
	end
else
	steam = nil
end


IS_EXPORT = not pcall(require, "tools.is_debug")


local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    -- lldebugger = lldebuggerPatcher.start()
    require("lldebugger").start()

    function love.errorhandler(msg)
        error(msg, 2)
    end
end

local conf = {
	
	-- game settings
    name = "EVIL EGG",
    folder = nil,

	manual_gc = true,

	-- window_title = "EVIL EGG",

    room_size = {
		x = 260,
		y = 216,
	},

	-- fennel
	use_fennel = false,
	
	-- display
	viewport_size = {
		x = 280,
		y = 240,
    },

	expand_viewport = true,

    to_vec2 = {
		"room_size",
		"viewport_size",
		"room_padding",
	},
	
	-- display_scale = 2,
	display_scale = IS_EXPORT and 2 or 5,

	-- delta
	use_fixed_delta = false,
    fixed_tickrate = 60,
	delta_tickrate = 60,
    max_delta_seconds = 1/60,
	max_fps = 600,
    max_fixed_ticks_per_frame = 1,

	-- input
	input_actions = {
		shoot = {
			mouse = { "lmb" },
		},

		secondary_weapon = {
            mouse = { "rmb" },
			joystick_axis = { 
				axis = "triggerright",
				dir = 1,
				deadzone = 0.25,
			},
		},

		hover = {
			keyboard = { "space" },
			joystick_axis = { 
				axis = "triggerleft",
				dir = 1,
				deadzone = 0.25,
			},
		},

		skip_bonus_screen = {
			keyboard = { "tab", "escape" },
			joystick = { "start", "a" }
		},
		
		restart = {
			keyboard = { "r" },
			joystick = { "start" },
			-- mouse = { "lmb" }
		},
		
		menu = {
			keyboard = { "escape", },
			joystick = { "start" }
        },

		fullscreen_toggle = {
			keyboard = {
				"f11",
				{"ralt", "return"},
				{"lalt", "return"}
			}
		},

        dont_shoot = {
            joystick = {
                "rightshoulder",
            }
        },

		show_hud = {
			keyboard = {
				{"lctrl"}, 
				{"rctrl"},
			},
			joystick = {"back", "leftshoulder"}
		},

        debug_kill_player = {
            debug = true,
            keyboard = {
                { "lctrl", "k" },
                { "rctrl", "k" }
            }
        },

		debug_editor_toggle = {
			debug = true,
			keyboard = { 
				{ "lctrl", "e" }, 
				{ "rctrl", "e" } 
			}
		},

		debug_draw_toggle = {
			debug = true,
			keyboard = { 
				{ "lctrl", "d" }, 
				{ "rctrl", "d" } 
			}
		},

		debug_draw_bounds_toggle = {
			debug = true,
			keyboard = { 
				{ "lctrl", "b" }, 
				{ "rctrl", "b" } 
			}
		},

		debug_shader_toggle = {
			debug = true,
			keyboard = { 
				{"lctrl", "]"}, 
				{"rctrl", "]"}
			}
		},

		debug_fixed_delta_toggle = {
			debug = true,
			keyboard = { 
				{"lctrl", "t"}, 
				{"rctrl", "t"}
			}
		},

		debug_shader_preset = {
			debug = true,
			keyboard = { 
				{"lctrl", "\\"}, 
				{"rctrl", "\\"}
			}

		},

		debug_count_memory = {
			debug = true,
			keyboard = { 
				{"lctrl", "m"}, 
				{"rctrl", "m"}
			}
        },

		debug_signal_snapshot = {
			debug = true,
			keyboard = { 
				{"lctrl", "g"}, 
				{"rctrl", "g"}
			}
		},

		debug_profile = {
			debug = true,
			keyboard = { 
				{"]"}, 
				{"]"}
			}
		},
		
		debug_console_toggle = {
			debug = true,
			keyboard = { 
				{"`"},
			}
		},

		debug_build_assets = {
			debug = true,
			keyboard = { 
				{ "lctrl", "m" },
				{ "rctrl", "m" }
			}
        },
		
        debug_skip_wave = {
			debug = true,
			keyboard = {
				{ "tab" },
				{ "tab" }
			}
        },

		debug_fast_forward = {
			debug = true,
			keyboard = {
				{ "q" },
			}
		},
		
		debug_toggle_invulnerability = {
			debug = true,
			keyboard = {
				{ "i" },
				{ "i" }
			}
		},

		debug_print_canvas_tree = {
			debug = true,
			keyboard = {
				{ "lctrl", "[" },
				{ "lctrl", "[" }
			}
		},

		debug_turn_on_frame_advance = {
			debug = true,
			keyboard = {
				{ "f" },
				-- { "p" }
			}
        },
		
		debug_turn_off_frame_advance = {
			debug = true,
			keyboard = {
				{ "lctrl", "f" },
                { "rctrl", "f" },
				-- { "p" },
			}
		},

        debug_frame_advance = {
			debug = true,
			keyboard = {
				{ "f" },
				{ "f" }
			}
		},

		debug_toggle_slow_motion = {
			debug = true,
			keyboard = {
				{ "`" },
				{ "`" }
			}
		},


		
	},

	input_vectors = {

	},
}


string = require "lib.stringy"


if IS_EXPORT then
    conf.input_actions.secondary_weapon.keyboard = { "lshift" }
end

-- console stuff
if steam and steam.utils.isSteamRunningOnSteamDeck() then
	conf.platform_force_fullscreen = true
	conf.platform = "steamdeck"
end

local function load_input_preset(preset)
	for k, v in pairs(preset.actions) do
		conf.input_actions[k] = v
	end

	for k, v in pairs(preset.vectors) do
		conf.input_vectors[k] = v
	end
end

load_input_preset(input_presets.twinstick)
load_input_preset(input_presets.ui)

if conf.room_size == nil then
	conf.room_size = {
		x = conf.viewport_size.x,
		y = conf.viewport_size.y,
	}
end


conf.room_padding = {
	x = (conf.viewport_size.x - conf.room_size.x) * 0.5,
	y = (conf.viewport_size.y - conf.room_size.y) * 0.5,
}

-- https://love2d.org/wiki/Config_Files
function love.conf(t)
    -- if true then
	


	-- local headless = false

	t.identity              = conf.folder or conf.name
	t.appendidentity        = false -- Search files in source directory before save directory (boolean)
	t.version               = "12.0"
	t.console               = false
	t.accelerometerjoystick = false
	t.externalstorage       = false
    t.graphics.gammacorrect = false
	t.graphics.renderers    = {"vulkan", "opengl", "metal"}
	t.highdpi        = true
	
	t.audio.mic             = false
	t.audio.mixwithsystem   = true

	t.window.title          = conf.window_title or conf.name
	t.window.icon           = ("assets/icon.png")
	t.window.width          = conf.viewport_size.x * conf.display_scale
    t.window.height         = conf.viewport_size.y * conf.display_scale
    if not IS_EXPORT then
        -- t.window.width          = 1920
        -- t.window.height         = 1080
    end



	t.window.borderless     = false
	t.window.resizable      = true
	t.window.minwidth       = conf.viewport_size.x
	t.window.minheight      = conf.viewport_size.y
	t.window.fullscreen     = false
	t.window.fullscreentype = "desktop"
	
	
	if conf.platform_force_fullscreen then
        t.window.fullscreen = true
        t.window.width = 0
		
		t.window.fullscreentype = "exclusive"
	end

	if IS_EXPORT then
    	-- t.window.fullscreentype = "exclusive"
	end
    t.window.vsync          = 0
	
	-- t.window.vsync
	t.window.msaa           = 0
	t.window.depth          = nil
	t.window.stencil        = nil
	t.window.displayindex    = 1
	t.window.usedpiscale    = false
	t.window.x              = nil
	t.window.y              = nil

	t.modules.audio         = true
	t.modules.data          = true
	t.modules.event         = true
	t.modules.font          = true
	t.modules.graphics      = true
	t.modules.image         = true
	t.modules.joystick      = true
	t.modules.keyboard      = true
	t.modules.math          = true
	t.modules.mouse         = true
	t.modules.physics       = true
	t.modules.sound         = true
	t.modules.system        = true
	t.modules.thread        = true
	t.modules.timer         = true
	t.modules.touch         = true
	t.modules.video         = true
	t.modules.window        = true

	for _, arg in ipairs(arg) do
        print(arg)
        if arg == "headless" then
			local t_ = t
			t_.window = false
		end
	end

	if conf.use_fennel then
		fennel = require("lib.fennel").install({correlate=true,
			moduleName = "lib.fennel"
		})
	end
end

return conf
