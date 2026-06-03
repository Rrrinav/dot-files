-- ~/.config/hypr/hyprland.lua
-- Hyprland 0.55+ Lua config
-- Docs: https://wiki.hypr.land/Configuring/Start/

-- PYWAL COLORS
local function wal_color(index)
  local f = io.open(os.getenv("HOME") .. "/.cache/wal/colors", "r")
  if not f then return nil end
  local i, line = 0, nil
  for l in f:lines() do
    if i == index then
      line = l; break
    end
    i = i + 1
  end
  f:close()
  return line and ("rgb(" .. line:gsub("#", "") .. ")") or nil
end

local color4  = wal_color(4) or "rgb(89b4fa)"
local color10 = wal_color(10) or "rgb(a6e3a1)"

-- MONITOR
hl.monitor({
  output   = "eDP-1",
  mode     = "1920x1080@144",
  position = "0x0",
  scale    = 1,
})

-- PROGRAMS
local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "rofi -show drun -no-fixed-num-lines"
local mainMod     = "SUPER"
local HOME        = os.getenv("HOME")

-- AUTOSTART
hl.on("hyprland.start", function()
  hl.exec_cmd("swww-daemon")
  hl.exec_cmd("eww daemon")
  hl.exec_cmd("eww open bar")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("dunst")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- MAIN CONFIG
hl.config({
  input = {
    kb_layout    = "us",
    kb_options   = "compose:ralt",
    follow_mouse = 1,
    sensitivity  = 0,
    touchpad     = {
      natural_scroll = true,
    },
  },

  general = {
    gaps_in          = 2,
    gaps_out         = 2,
    border_size      = 1,
    col              = {
      active_border   = color4, --.. " " .. color10 .. " 45deg",
      inactive_border = "rgba(afafaf5f)",
    },
    resize_on_border = true,
    layout           = "dwindle",
    allow_tearing    = false,
  },

  decoration = {
    rounding         = 0,
    active_opacity   = 1.0,
    inactive_opacity = 0.9,
    blur             = {
      enabled           = true,
      size              = 3,
      passes            = 3,
      vibrancy          = 0.5,
      vibrancy_darkness = 0.5,
    },
  },

  dwindle = {
    -- pseudotile was removed in 0.55
    preserve_split = true,
  },

  misc = {
    force_default_wallpaper = -1,
  },
})

-- ANIMATIONS  (separate from hl.config in 0.55+)
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default", style = "slide" })

-- PER-DEVICE CONFIG
hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})

-- WINDOW RULES
hl.window_rule({
  match        = { class = "Rofi" },
  float        = true,
  center       = true,
  stay_focused = true,
})

-- GESTURES
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- KEYBINDS
-- Apps
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.kill())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(
  'sh ' .. HOME .. '/.local/bin/pywal.sh | dunstify "Select wallpapers" -t 1000'
))

-- ── Focus movement ───────────────────────────────────────────
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Window swapping (vim keys)
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.swap({ direction = "u" }))

-- ── Workspaces 1–10 ─────────────────────────────────────────
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({
    workspace = i,
    on_current_monitor = true
  }))
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = true }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Mouse: move / resize windows (drag binds)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag());
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- ── Brightness ──────────────────────────────────────────────
local function brightness(step)
  return hl.dsp.exec_cmd(
    string.format(
      'brightnessctl set %s; p=$(brightnessctl -m | cut -d, -f4 | tr -d "%%"); dunstify -h int:value:$p -r 9991 "Brightness" "$p%%"',
      step
    )
  )
end

hl.bind("XF86MonBrightnessUp", brightness("+2%"))
hl.bind("XF86MonBrightnessDown", brightness("2%-"))

-- ── Volume / Audio ──────────────────────────────────────────
local function notify_cmd(cmd, title, replace_id, value_cmd)
  return hl.dsp.exec_cmd(string.format(
    '%s; p=$(%s); dunstify -h int:value:$p -r %d "%s" "$p%%"',
    cmd,
    value_cmd,
    replace_id,
    title
  ))
end

-- Volume
hl.bind("XF86AudioRaiseVolume",
  notify_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+", "Volume", 9992,
    [[wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}']]))
hl.bind("XF86AudioLowerVolume",
  notify_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "Volume", 9992,
    [[wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}']]))

local function cmd_output(cmd)
  local f = assert(io.popen(cmd))
  local out = f:read("*a")
  f:close()
  return out
end

local function toggle_speaker()
  os.execute("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  local muted = cmd_output("wpctl get-volume @DEFAULT_AUDIO_SINK@"):find("%[MUTED%]") ~= nil
  os.execute(('dunstify -r 9992 "Volume" "%s"'):format(muted and "Muted" or "Unmuted"))
end

local function toggle_mic()
  os.execute("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
  local muted = cmd_output("wpctl get-volume @DEFAULT_AUDIO_SOURCE@"):find("%[MUTED%]") ~= nil
  os.execute(('dunstify -r 9993 "Microphone" "%s"'):format(muted and "Muted" or "Unmuted"))
end

hl.bind("XF86AudioMute", toggle_speaker)
hl.bind("XF86AudioMicMute", toggle_mic)

-- ── Misc ─────────────────────────────────────────────────────
hl.bind("SHIFT + F4", hl.dsp.exec_cmd(HOME .. "/.local/bin/toggle_bar.sh"))

-- ── Screenshots ──────────────────────────────────────────────
-- No leading comma for bare keys like Print
hl.bind("Print", hl.dsp.exec_cmd(
  'grim -g "$(slurp)" - | wl-copy && wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png' ..
  ' | dunstify "Screenshot of region taken" -t 1000'
))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
  'grim - | wl-copy && wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png' ..
  ' | dunstify "Screenshot taken" -t 1000'
))

-- ── Clipboard / Window switcher ──────────────────────────────
hl.bind("ALT + SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(HOME .. "/.local/bin/rofi-windows.sh"))

-- ── Resize submap ────────────────────────────────────────────
hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
  hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
  hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
  hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
  hl.bind("escape", hl.dsp.submap("reset"))
end)
