-- Pull in the wezterm API
local wezterm = require("wezterm")
local ws = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local act = wezterm.action
local mux = wezterm.mux

-- This table will hold the configuration.
local config = {}

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
    key = "w",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
        resurrect.save_state(resurrect.workspace_state.get_workspace_state())
      end),
  },
  {
    key = "W",
    mods = "LEADER",
    action = resurrect.window_state.save_window_action(),
  },
  {
    key = "T",
    mods = "LEADER",
    action = resurrect.tab_state.save_tab_action(),
  },
  {
    key = "s",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
        resurrect.save_state(resurrect.workspace_state.get_workspace_state())
        resurrect.window_state.save_window_action()
      end),
  },
  {
    key = "r",
    mods = "LEADER",
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)") -- match before '/'
        id = string.match(id, "([^/]+)$") -- match after '/'
        id = string.match(id, "(.+)%..+$") -- remove file extention
        local opts = {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if type == "workspace" then
          local state = resurrect.load_state(id, "workspace")
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == "window" then
          local state = resurrect.load_state(id, "window")
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == "tab" then
          local state = resurrect.load_state(id, "tab")
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end)
    end),
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
