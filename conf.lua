usersettings = require "usersettings"
local input_presets = require "conf.input_presets"

local lldebuggerPatcher = require("lib.lldebuggerpatcher")

IS_EXPORT = not pcall(require, "tools.is_debug")

local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    -- lldebugger = lldebuggerPatcher.start()
    require("lldebugger").start()

    function love.errorhandler(msg)
        error(msg, 2)
    end
end

string = require "lib.stringy"

local conf = {
	
	-- game settings
    name = "THE VIDEO GAME RETURNS",
    folder = nil,
	window_title = nil,

    room_size = {
		x = 260,
		y = 216,
	},

	-- fennel
	use_fennel = false,
	
	-- display
	viewport_size = {
		x = 300,
		y = 240,
    },

	expand_viewport = true,

	
    to_vec2 = {
		"room_size",
		"viewport_size",
		"room_padding",
	},
	
	display_scale = IS_EXPORT and 3 or 6,

	-- delta
	use_fixed_delta = false,
    fixed_tickrate = 60,
	delta_tickrate = 60,
    max_delta_seconds = 1/60,
	max_fps = IS_EXPORT and 500 or 5000,
    max_fixed_ticks_per_frame = 1,

	-- input
	input_actions = {
		shoot = {
			mouse = { "lmb" },
		},

		hover = {
			keyboard = { "space" },
			joystick_axis = { 
				axis = "triggerleft",
				dir = 1,
				deadzone = 0.25,
			},
        },
		
		restart = {
			keyboard = { "r" },
			joystick = { "start" },
			-- mouse = { "lmb" }
		},

		confirm = {
			keyboard = { "z", "return" },
			joystick = { "start", "a" },
			mouse = { "lmb" }
		},

		menu = {
			keyboard = { "escape", },
			joystick = { "start" }
		}, 
		
		move_up = {
			keyboard = {"w"},
			joystick = {"dpup"},
			joystick_axis = {
				axis = "lefty",
				dir = -1,
				deadzone = 0.0,
			},
		},
		
		move_down = {
			keyboard = {"s"},
			joystick = {"dpdown"},
			joystick_axis = {
				axis = "lefty",
				dir = 1,
				deadzone = 0.0,
			},
		},
		
		move_left = {
			keyboard = {"a"},
			joystick = {"dpleft"},
			joystick_axis = {
				axis = "leftx",
				dir = -1,
				deadzone = 0.0,
			},
		},
		
		move_right = {
			keyboard = {"d"},
			joystick = {"dpright"},
			joystick_axis = {
				axis = "leftx",
				dir = 1,
				deadzone = 0.0,
			}
		},
		
		aim_up = {
			keyboard = { "up" },
			joystick = { "y" },
			joystick_axis = {
				axis = "righty",
				deadzone = 0.0,
				dir = -1
			}
		},
		
		aim_down = {
			keyboard = {"down"},
			joystick = { "a" },
			joystick_axis = {
				axis = "righty",
				dir = 1,
				deadzone = 0.0,
			}
		},
		
		aim_left = {
			keyboard = {"left"},
			joystick = { "x" },
			joystick_axis = {
				axis = "rightx",
				deadzone = 0.0,
				dir = -1
			}
		},
		
		aim_right = {
			keyboard = {"right"},
			joystick = { "b" },
			joystick_axis = {
				axis = "rightx",
				dir = 1,
				deadzone = 0.0,
			} 
		},
		
		aim_up_digital = {
			keyboard = { "up" },
			joystick = { "y" },

		},
		
		aim_down_digital = {
			keyboard = {"down"},
			joystick = { "a" },

		},
		
		aim_left_digital = {
			keyboard = {"left"},
			joystick = { "x" },
		},
		

		aim_right_digital = {
			keyboard = {"right"},
			joystick = { "b" },
		},
		

		aim_up_analog = {
			joystick_axis = {
				axis = "righty",
				deadzone = 0.0,
				dir = -1
			}
		},


		aim_down_analog = {
			joystick_axis = {
				axis = "righty",
				deadzone = 0.0,
				dir = 1
			}
		},

		aim_left_analog = {
			joystick_axis = {
				axis = "rightx",
				deadzone = 0.0,
				dir = -1
			}
		},

		aim_right_analog = {
			joystick_axis = {
				axis = "rightx",
				deadzone = 0.0,
				dir = 1
			}
		},

		fullscreen_toggle = {
			keyboard = {
				"f11",
				{"ralt", "return"},
				{"lalt", "return"}
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

		debug_profile = {
			debug = true,
			keyboard = { 
				{"lctrl", "p"}, 
				{"rctrl", "p"}
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
		}

		
	},

	input_vectors = {
		move = {
			left = "move_left",
			right = "move_right",
			up = "move_up",
			down = "move_down",
		},
		aim = {
			left = "aim_left",
			right = "aim_right",
			up = "aim_up",
			down = "aim_down",
		},
		aim_digital = {
			left = "aim_left_digital",
			right = "aim_right_digital",
			up = "aim_up_digital",
			down = "aim_down_digital",
		},
		aim_analog = {
			left = "aim_left_analog",
			right = "aim_right_analog",
			up = "aim_up_analog",
			down = "aim_down_analog",
		},
	},
}

local function load_input_preset(preset)
	for k, v in pairs(preset.actions) do
		conf.input_actions[k] = v
	end

	for k, v in pairs(preset.vectors) do
		conf.input_vectors[k] = v
	end
end

load_input_preset(input_presets.twinstick)

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
	t.window.icon           = nil
	t.window.width          = conf.viewport_size.x * conf.display_scale
    t.window.height         = conf.viewport_size.y * conf.display_scale
    -- if not IS_EXPORT then
	-- t.window.width          = 1920
	-- t.window.height         = 1080
	-- end

	t.window.borderless     = false
	t.window.resizable      = true
	t.window.minwidth       = conf.viewport_size.x
	t.window.minheight      = conf.viewport_size.y
	t.window.fullscreen     = usersettings.fullscreen and IS_EXPORT
    t.window.fullscreentype = "desktop"
    -- t.window.fullscreentype = "exclusive"
	if usersettings.vsync then
        t.window.vsync = -1
    else
		t.window.vsync = 0
	end
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
