-- ==============================================================================
-- Hyprland 0.57+ Lua Configuration
-- Tailored for Apple MacBook Pro 13" (Early 2015, MacBookPro12,1)
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- 1. Monitors Configuration
-- -----------------------------------------------------------------------------
-- Internal Retina 13.3" (2560x1600 @ 60Hz) with 2x integer HiDPI scaling
-- Effective crisp desktop workspace: 1280x800
monitor = {
    "eDP-1,2560x1600@60,0x0,2",
    ",preferred,auto,1"
}

-- -----------------------------------------------------------------------------
-- 2. Environment Variables
-- -----------------------------------------------------------------------------
env = {
    "XCURSOR_SIZE,24",
    "HYPRCURSOR_SIZE,24",
    "GDK_SCALE,2",
    "GDK_BACKEND,wayland,x11,*",
    "QT_QPA_PLATFORM,wayland;xcb",
    "QT_AUTO_SCREEN_SCALE_FACTOR,1",
    "QT_WAYLAND_DISABLE_WINDOWDECORATION,1",
    "XDG_CURRENT_DESKTOP,Hyprland",
    "XDG_SESSION_TYPE,wayland",
    "XDG_SESSION_DESKTOP,Hyprland",
    "MOZ_ENABLE_WAYLAND,1",
    "ELECTRON_OZONE_PLATFORM_HINT,wayland"
}

-- -----------------------------------------------------------------------------
-- 3. Input & Apple Trackpad Settings
-- -----------------------------------------------------------------------------
input = {
    kb_layout = "us",
    kb_variant = "mac",
    kb_model = "",
    kb_options = "terminate:ctrl_alt_bksp",
    kb_rules = "",

    follow_mouse = 1,
    sensitivity = 0.2, -- Fine-tuned for Apple Broadcom multitouch trackpad

    touchpad = {
        natural_scroll = true,          -- Standard macOS two-finger scrolling
        tap-to-click = true,
        drag_lock = false,
        disable_while_typing = true,
        clickfinger_behavior = true,    -- Two-finger tap = right-click, three-finger = middle-click
        scroll_factor = 0.4
    }
}

gestures = {
    workspace_swipe = true,
    workspace_swipe_fingers = 3,
    workspace_swipe_distance = 300,
    workspace_swipe_cancel_ratio = 0.2,
    workspace_swipe_min_speed_to_force = 5
}

-- -----------------------------------------------------------------------------
-- 4. General & Appearance
-- -----------------------------------------------------------------------------
general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    col.active_border = "rgba(89b4faff) rgba(cba6f7ff) 45deg",
    col.inactive_border = "rgba(313244aa)",
    layout = "dwindle",
    allow_tearing = false
}

decoration = {
    rounding = 10,
    active_opacity = 0.98,
    inactive_opacity = 0.90,
    fullscreen_opacity = 1.0,

    blur = {
        enabled = true,
        size = 6,
        passes = 3,
        new_optimizations = true,
        xray = false,
        ignore_opacity = true
    },

    shadow = {
        enabled = true,
        range = 15,
        render_power = 3,
        color = "rgba(00000055)"
    }
}

animations = {
    enabled = true,
    bezier = {
        "easeOutQuint, 0.23, 1, 0.32, 1",
        "easeInOutCubic, 0.65, 0, 0.35, 1",
        "linear, 0, 0, 1, 1",
        "quick, 0.15, 0, 0.1, 1"
    },
    animation = {
        "windows, 1, 4.5, easeOutQuint",
        "windowsOut, 1, 3.5, easeInOutCubic, popin 80%",
        "border, 1, 8, default",
        "fade, 1, 4, default",
        "workspaces, 1, 4, easeOutQuint, slide"
    }
}

dwindle = {
    pseudotile = true,
    preserve_split = true
}

master = {
    new_status = "master"
}

misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vfr = true,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true
}

-- -----------------------------------------------------------------------------
-- 5. Autostart Applications & Daemons
-- -----------------------------------------------------------------------------
exec_once = {
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "waybar",
    "dunst",
    "swww-daemon",
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
    "~/.local/bin/battery-monitor.sh --daemon",
    "~/.local/bin/display-switch.sh auto"
}

-- -----------------------------------------------------------------------------
-- 6. Keybindings
-- -----------------------------------------------------------------------------
local mod = "SUPER"

bind = {
    -- Core Apps & Terminals
    { mod, "Return", "exec, kitty" },
    { mod, "Q", "killactive," },
    { mod, "E", "exec, thunar" },
    { mod, "V", "togglefloating," },
    { mod, "SPACE", "exec, rofi -show drun" },
    { mod, "P", "pseudo," },
    { mod, "J", "togglesplit," },
    { mod, "L", "exec, hyprlock" },
    { mod, "F", "fullscreen, 0" },

    -- Screen Brightness Keys (Mac F1 / F2)
    { "", "XF86MonBrightnessUp", "exec, ~/.local/bin/brightness.sh screen up" },
    { "", "XF86MonBrightnessDown", "exec, ~/.local/bin/brightness.sh screen down" },

    -- Keyboard Backlight Keys (Mac F5 / F6)
    { "", "XF86KbdBrightnessUp", "exec, ~/.local/bin/brightness.sh kbd up" },
    { "", "XF86KbdBrightnessDown", "exec, ~/.local/bin/brightness.sh kbd down" },

    -- Audio Volume Keys (Mac F10 / F11 / F12)
    { "", "XF86AudioRaiseVolume", "exec, ~/.local/bin/volume.sh up" },
    { "", "XF86AudioLowerVolume", "exec, ~/.local/bin/volume.sh down" },
    { "", "XF86AudioMute", "exec, ~/.local/bin/volume.sh mute" },
    { "", "XF86AudioMicMute", "exec, ~/.local/bin/volume.sh mic-mute" },

    -- Media Player Control (Mac F7 / F8 / F9)
    { "", "XF86AudioPlay", "exec, playerctl play-pause" },
    { "", "XF86AudioNext", "exec, playerctl next" },
    { "", "XF86AudioPrev", "exec, playerctl previous" },

    -- Screenshots (Print / Super+Shift+S)
    { "", "Print", "exec, ~/.local/bin/screenshot.sh full" },
    { mod .. " SHIFT", "S", "exec, ~/.local/bin/screenshot.sh area" },
    { mod .. " SHIFT", "E", "exec, ~/.local/bin/screenshot.sh area --edit" },

    -- Display Switching
    { mod .. " SHIFT", "D", "exec, ~/.local/bin/display-switch.sh auto" },

    -- Focus Navigation
    { mod, "left", "movefocus, l" },
    { mod, "right", "movefocus, r" },
    { mod, "up", "movefocus, u" },
    { mod, "down", "movefocus, d" },

    -- Workspaces 1 to 10
    { mod, "1", "workspace, 1" },
    { mod, "2", "workspace, 2" },
    { mod, "3", "workspace, 3" },
    { mod, "4", "workspace, 4" },
    { mod, "5", "workspace, 5" },
    { mod, "6", "workspace, 6" },
    { mod, "7", "workspace, 7" },
    { mod, "8", "workspace, 8" },
    { mod, "9", "workspace, 9" },
    { mod, "0", "workspace, 10" },

    -- Move active window to workspace
    { mod .. " SHIFT", "1", "movetoworkspace, 1" },
    { mod .. " SHIFT", "2", "movetoworkspace, 2" },
    { mod .. " SHIFT", "3", "movetoworkspace, 3" },
    { mod .. " SHIFT", "4", "movetoworkspace, 4" },
    { mod .. " SHIFT", "5", "movetoworkspace, 5" },
    { mod .. " SHIFT", "6", "movetoworkspace, 6" },
    { mod .. " SHIFT", "7", "movetoworkspace, 7" },
    { mod .. " SHIFT", "8", "movetoworkspace, 8" },
    { mod .. " SHIFT", "9", "movetoworkspace, 9" },
    { mod .. " SHIFT", "0", "movetoworkspace, 10" },

    -- Mouse workspace scroll
    { mod, "mouse_down", "workspace, e+1" },
    { mod, "mouse_up", "workspace, e-1" }
}

-- Mouse drag window moving and resizing
bindm = {
    { mod, "mouse:272", "movewindow" },
    { mod, "mouse:273", "resizewindow" }
}

-- -----------------------------------------------------------------------------
-- 7. Window Rules
-- -----------------------------------------------------------------------------
windowrulev2 = {
    "float, class:^(pavucontrol)$",
    "float, class:^(blueman-manager)$",
    "float, class:^(nm-connection-editor)$",
    "float, class:^(imv)$",
    "float, class:^(mpv)$",
    "float, class:^(swappy)$",
    "float, title:^(Media viewer)$",
    "float, title:^(Picture-in-Picture)$",
    "pin, title:^(Picture-in-Picture)$",
    "suppressevent maximize, class:.*"
}
