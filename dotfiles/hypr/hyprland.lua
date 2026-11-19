-- ==============================================================================
-- Hyprland 0.57+ Lua Configuration
-- Tailored for Apple MacBook Pro 13" Retina (Early 2015, MacBookPro12,1)
-- ==============================================================================

--------------------------------------------------------------------------------
-- 1. Monitors
--------------------------------------------------------------------------------
-- Internal Retina 13.3" (2560x1600 @ 60Hz) with 2x integer HiDPI scaling
-- Effective crisp desktop workspace: 1280x800
hl.monitor({
    output   = "eDP-1",
    mode     = "2560x1600@60",
    position = "0x0",
    scale    = 2,
})

-- External fallback / dynamic plug
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

--------------------------------------------------------------------------------
-- 2. Environment Variables
--------------------------------------------------------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_SCALE", "2")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

--------------------------------------------------------------------------------
-- 3. Core Look & Feel and Input Configuration
--------------------------------------------------------------------------------
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(89b4faff)", "rgba(cba6f7ff)" }, angle = 45 },
            inactive_border = "rgba(313244aa)",
        },
        layout        = "dwindle",
        allow_tearing = false,
    },

    decoration = {
        rounding           = 10,
        active_opacity     = 0.98,
        inactive_opacity   = 0.90,
        fullscreen_opacity = 1.0,

        blur = {
            enabled = true,
            size    = 6,
            passes  = 3,
        },

        shadow = {
            enabled      = true,
            range        = 15,
            render_power = 3,
            color        = "rgba(00000055)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },

    input = {
        kb_layout   = "us",
        kb_variant  = "mac",
        follow_mouse = 1,
        sensitivity = 0.2, -- Calibrated for Broadcom SPI multitouch trackpad

        touchpad = {
            natural_scroll       = true,  -- Standard macOS two-finger scrolling
            tap_to_click         = true,
            drag_lock            = false,
            disable_while_typing = true,
            clickfinger_behavior = true,  -- Two-finger tap = right-click, three-finger = middle-click
            scroll_factor        = 0.4,
        },
    },
})

--------------------------------------------------------------------------------
-- 4. Multi-Touch Gestures
--------------------------------------------------------------------------------
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

--------------------------------------------------------------------------------
-- 5. Curves & Animations
--------------------------------------------------------------------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "windows",    enabled = true, speed = 4.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "easeInOutCubic", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4,   bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4,   bezier = "easeOutQuint", style = "slide" })

--------------------------------------------------------------------------------
-- 6. Autostart Applications & Daemons
--------------------------------------------------------------------------------
hl.on("hyprland.start", function()
    local home = os.getenv("HOME") or ""
    local bin  = home .. "/.local/bin/"

    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd(bin .. "battery-monitor.sh --daemon")
    hl.exec_cmd(bin .. "display-switch.sh auto")
end)

--------------------------------------------------------------------------------
-- 7. Keybindings
--------------------------------------------------------------------------------
local mod  = "SUPER"
local home = os.getenv("HOME") or ""
local bin  = home .. "/.local/bin/"

-- Core Apps & Window Management
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SPACE",  hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mod .. " + M",      hl.dsp.exit())

-- Screen Brightness Keys (Mac F1 / F2)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(bin .. "brightness.sh screen up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(bin .. "brightness.sh screen down"), { locked = true, repeating = true })

-- Keyboard Backlight Keys (Mac F5 / F6)
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(bin .. "brightness.sh kbd up"),   { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(bin .. "brightness.sh kbd down"), { locked = true, repeating = true })

-- Audio Volume Keys (Mac F10 / F11 / F12)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(bin .. "volume.sh up"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(bin .. "volume.sh down"),     { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(bin .. "volume.sh mute"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(bin .. "volume.sh mic-mute"), { locked = true, repeating = true })

-- Media Player Control (Mac F7 / F8 / F9)
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots
hl.bind("Print",                 hl.dsp.exec_cmd(bin .. "screenshot.sh full"))
hl.bind(mod .. " + SHIFT + S",   hl.dsp.exec_cmd(bin .. "screenshot.sh area"))
hl.bind(mod .. " + SHIFT + E",   hl.dsp.exec_cmd(bin .. "screenshot.sh area --edit"))

-- Display Switching
hl.bind(mod .. " + SHIFT + D",   hl.dsp.exec_cmd(bin .. "display-switch.sh auto"))

-- Focus Navigation (Arrow Keys)
hl.bind(mod .. " + left",        hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right",       hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",          hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",        hl.dsp.focus({ direction = "down" }))

-- Workspaces 1 through 10
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Mouse Workspace Scrolling
hl.bind(mod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))

-- Mouse Window Drag & Resize
hl.bind(mod .. " + mouse:272",   hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273",   hl.dsp.window.resize(), { mouse = true })

--------------------------------------------------------------------------------
-- 8. Window Rules
--------------------------------------------------------------------------------
hl.window_rule({ name = "float-pavucontrol",    match = { class = "pavucontrol" },            float = true })
hl.window_rule({ name = "float-blueman",        match = { class = "blueman-manager" },        float = true })
hl.window_rule({ name = "float-nm-connection",  match = { class = "nm-connection-editor" },   float = true })
hl.window_rule({ name = "float-imv",            match = { class = "imv" },                    float = true })
hl.window_rule({ name = "float-mpv",            match = { class = "mpv" },                    float = true })
hl.window_rule({ name = "float-swappy",         match = { class = "swappy" },                 float = true })
hl.window_rule({ name = "float-pip",            match = { title = "Picture-in-Picture" },     float = true, pin = true })
hl.window_rule({ name = "suppress-maximize",    match = { class = ".*" },                     suppress_event = "maximize" })
