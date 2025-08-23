return {
	nothing = {
		actions = {},
		vectors = {},
    },

	basic = {
		actions = {
			primary = {
				keyboard = { "z", "return" },
                joystick = { "a" },
			},
			
			secondary = {
				keyboard = { "x", "rshift" },
				joystick = { "b" }
			},
			
			move_up = {
				keyboard = {"up"},
				joystick = {"dpup"},
				joystick_axis = {
					axis = "lefty",
					dir = -1
				}
			},
			
			move_down = {
				keyboard = {"down"},
				joystick = {"dpdown"},
				joystick_axis = {
					axis = "lefty",
					dir = 1
				}
			},
			
			move_left = {
				keyboard = {"left"},
				joystick = {"dpleft"},
				joystick_axis = {
					axis = "leftx",
					dir = -1
				}
			},
			
			move_right = {
				keyboard = {"right"},
				joystick = {"dpright"},
				joystick_axis = {
					axis = "leftx",
					dir = 1
				}
			},


		},
		vectors = {
			move = {
				left = "move_left",
				right = "move_right",
				up = "move_up",
				down = "move_down",
			},
		}
    },
		
    ui = {
        actions = {
			ui_confirm = {
				keyboard = { "return", "space" },
				joystick = { "a" },
				-- mouse = { "lmb" }
			},

			ui_title_screen_start = {
				keyboard = { "return", "space" },
				joystick = { "start", "a" },
				mouse = { "lmb" }
			},

			ui_cancel = {
				keyboard = { "escape", },
				joystick = { "b" },
				-- mouse = { "rmb" }
			},
		
			ui_nav_up = {
				keyboard = { "up", "w" },
                joystick = { "dpup" },
				joystick_axis = {
					axis = "lefty",
                    dir = -1,
					deadzone = 0.5,
				}
            },
			
			ui_nav_down = {
				keyboard = { "down", "s" },
				joystick = { "dpdown" },
				joystick_axis = {
					axis = "lefty",
                    dir = 1,
					deadzone = 0.5,
				}
            },
			
			ui_nav_left = {
				keyboard = { "left", "a" },
				joystick = { "dpleft" },
				joystick_axis = {
					axis = "leftx",
                    dir = -1,
					deadzone = 0.5,
				}
            },
			
			ui_nav_right = {
				keyboard = { "right", "d" },
				joystick = { "dpright" },
				joystick_axis = {
					axis = "leftx",
                    dir = 1,
					deadzone = 0.5,
				}
            },
        },
		vectors = {
			ui_nav = {
				left = "ui_nav_left",
				right = "ui_nav_right",
				up = "ui_nav_up",
				down = "ui_nav_down",
			},
		}
    },
	
		
	twinstick = {
        actions = {
            shoot = {
                
				mouse = { "lmb" },
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
					dir = -1
				},
                
			},
			
			move_down = {
				keyboard = {"s"},
				joystick = {"dpdown"},
				joystick_axis = {
					axis = "lefty",
					dir = 1
				},
                
			},
			
			move_left = {
				keyboard = {"a"},
				joystick = {"dpleft"},
				joystick_axis = {
					axis = "leftx",
					dir = -1
				},
                
			},
			
			move_right = {
				keyboard = {"d"},
				joystick = {"dpright"},
				joystick_axis = {
					axis = "leftx",
					dir = 1
				},
                
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


		},
		
		vectors = {
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
		}
	},

}
