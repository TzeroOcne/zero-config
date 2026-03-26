-- Pull in the wezterm API
local wezterm = require("wezterm") ---@type Wezterm
local ws = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local sessions = wezterm.plugin.require("https://github.com/abidibo/wezterm-sessions")
local act = wezterm.action
local mux = wezterm.mux

-- This table will hold the configuration.
local config = wezterm.config_builder()

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Tokyo Night"

-- Spawn a fish shell in login mode
config.set_environment_variables = {
  prompt = '$P',
}
config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "-c", "zsh" }
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.window_background_opacity = 0.85
config.window_decorations = "RESIZE"
config.audible_bell = "Disabled"
config.leader = { key = "a", mods = "CTRL" }
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.keys = {
  {
    key = "I",
    mods = "SHIFT|CTRL",
    escape = true,
    action = act.SendString "\027[6 q",
  },
  {
    key = "S",
    mods = "SHIFT|CTRL",
    action = act.Search { CaseInSensitiveString="" },
  },
	{
		key = "t",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab{
      cwd = '~',
      domain = 'DefaultDomain',
		},
	},
	{
		key = "1",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab({
			args = { "pwsh" },
		}),
	},
	{
		key = "2",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab({
			args = { "wsl" },
		}),
	},
	{
		key = "3",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab({
			args = { "wsl", "-u", "tzeroocne" },
		}),
	},
	{
		key = "4",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab({
			args = { "C:\\Program Files\\Git\\bin\\bash.exe", "-c", "zsh" },
		}),
	},
	{
		key = "5",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab({
			args = { "cmd.exe ", "/c", "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64 -shell bash -c zsh" },
		}),
	},
	{
		key = "f",
		mods = "CTRL|ALT",
		action = act.SpawnCommandInNewTab({
			args = { "lf" },
		}),
	},
	{
		key = " ",
		mods = "CTRL",
		action = act.SendKey({
			key = " ",
			mods = "CTRL",
		}),
	},
	{
		key = "d",
		mods = "CTRL",
		action = act.SendKey({
			key = "d",
			mods = "CTRL",
		}),
	},
	{
		key = " ",
		mods = "CTRL|SHIFT",
		action = act.SendKey({
			key = " ",
			mods = "CTRL|SHIFT",
		}),
	},
  {
    key = "DownArrow",
    mods = "ALT",
    action = act.SendKey({
      key = "DownArrow",
      mods = "ALT",
    }),
  },
  {
    key = "s",
    mods = "ALT",
    action = ws.switch_workspace(),
  },
  {
    name = "Save Session",
    description = "Save the current session",
    key = "s",
    mods = "LEADER",
    action = act({ EmitEvent = "save_session" }),
  },
  {
    name = 'Load Session',
    description = 'Load a saved session',
    key = 'l',
    mods = 'LEADER',
    action = act({ EmitEvent = "load_session" }),
  },
  {
    name = 'Restore Session',
    description = 'Restore the last saved session',
    key = 'r',
    mods = 'LEADER',
    action = act({ EmitEvent = "restore_session" }),
  },
  {
    name = 'Delete Session',
    description = 'Delete a saved session',
    key = 'd',
    mods = 'CTRL|SHIFT',
    action = act({ EmitEvent = "delete_session" }),
  },
  {
    name = 'Edit Session',
    description = 'Edit a saved session',
    key = 'e',
    mods = 'CTRL|SHIFT',
    action = act({ EmitEvent = "edit_session" }),
  },
-- Prompt for a name to use for a new workspace and switch to it.
  {
    name = 'New Workspace With Name',
    description = 'Create a new workspace with a specified name',
    key = 'n',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Fuchsia' } },
        { Text = 'Enter name for new workspace' },
      },
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(
            act.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    },
  },
}

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 8

wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- and finally, return the configuration to wezterm
return config
