-- ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗
-- ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║
-- ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝
-- Kali-Hyprland -- the kali-clean look, on Wayland
-- Author: KermitPurple96
--
-- Colours, gaps, borders and keybindings mirror the i3 setup in
-- https://github.com/KermitPurple96/kali-clean, plus the three things i3
-- could never do: real window animations, rounded corners and blur.
--
-- FORMAT: this is the Lua config. Hyprland 0.51+ reads ~/.config/hypr/
-- hyprland.lua; the old hyprland.conf still loads on 0.56 but prints
-- "support for which will be removed in Hyprland 0.57". The .conf version
-- of this file is kept in legacy/ for older installs only. Do not put both
-- in ~/.config/hypr.
--
-- PERFORMANCE: this setup assumes NO GPU. In a VMware guest, ticking
-- "Accelerate 3D graphics" is frequently worse than useless -- on plenty of
-- hosts the VM then refuses to boot at all -- so the working assumption here
-- is that vmwgfx reports "Available shader model: Legacy", there is no
-- GLES 3.x, and Hyprland renders through llvmpipe on the CPU.
--
-- That does not mean giving up the effects. It means paying attention to
-- which ones are expensive and why, which is what the profile below does.
-- Software rendering cost is (damaged pixels) x (passes over them), so:
--
--   * blur passes are a multiplier -- 1 pass costs about half of 2
--   * blur xray lets floating windows blur the wallpaper instead of
--     re-blurring the windows stacked underneath them
--   * new_optimizations caches blur for surfaces that have not changed, so
--     a still terminal costs nothing per frame
--   * noise and vibrancy are per-pixel maths on top of the blur itself
--   * full-screen animations (workspace slides) redraw every pixel every
--     frame; window open/close animations only touch one window's box
--   * shadows are pure overdraw around every window, for the least payoff
--
-- The `soft` profile below keeps rounding, blur and window animations and
-- drops exactly the things in that list that cost the most per pixel.

---------------------------
---- EFFECTS SWITCH -------
---------------------------
-- Set HYPR_EFFECTS before starting the session (the login entries do it):
--
--   soft  DEFAULT. Rounding, blur and window animations, tuned so a CPU
--         renderer can keep up. No shadows, no full-screen workspace
--         animation, single-pass blur.
--   full  Everything, generous. Only worth it on a machine with a real GPU.
--   lite  Rounding only. The panic button if even `soft` drags.
--
local profile = string.lower(os.getenv("HYPR_EFFECTS") or "soft")
if profile ~= "full" and profile ~= "lite" then
    -- anything unrecognised (including "off"/"none" typed from memory)
    -- falls back to the safe middle rather than to the expensive end
    if profile == "off" or profile == "none" then profile = "lite" else profile = "soft" end
end

local FX = {
    full = {
        blur = true,  blur_size = 8, blur_passes = 2,
        blur_xray = false, blur_popups = true,
        blur_noise = 0.0117, blur_vibrancy = 0.1696,
        shadow = true,
        anim = true, anim_speed = 5,
        anim_workspaces = true, ws_speed = 4,
        border_speed = 2,
    },
    soft = {
        -- One pass, radius 5. With new_optimizations on, a window that is
        -- not moving costs nothing after the frame that drew it. 5 rather
        -- than 4 because kitty now sits at 0.55 alpha: there is a lot more
        -- wallpaper showing through, so it wants a softer frost.
        blur = true,  blur_size = 5, blur_passes = 1,
        -- xray: floating windows blur the wallpaper instead of re-blurring
        -- everything stacked under them. Needs new_optimizations.
        blur_xray = true,  blur_popups = false,
        -- noise and vibrancy are extra per-pixel maths on top of the blur.
        blur_noise = 0.0,  blur_vibrancy = 0.0,
        shadow = false,
        anim = true, anim_speed = 3,
        -- Workspace switching IS on now. It redraws every pixel on screen
        -- for the whole animation, which is why it used to be off here --
        -- so the lever that keeps it affordable is duration, not curve.
        -- 2 = 200ms. Short enough that llvmpipe only has to composite a
        -- handful of frames, long enough to read as a slide.
        anim_workspaces = true, ws_speed = 2,
        -- Focus feedback. This is the one you feel on every SUPER+arrow,
        -- so it is the one that must not lag: 100ms, near-instant.
        border_speed = 1,
    },
    lite = {
        blur = false, blur_size = 1, blur_passes = 1,
        blur_xray = false, blur_popups = false,
        blur_noise = 0.0, blur_vibrancy = 0.0,
        shadow = false,
        anim = false, anim_speed = 1,
        anim_workspaces = false, ws_speed = 1,
        border_speed = 1,
    },
}

local fx = FX[profile]

-- HYPR_OVERLAY=1 turns on Hyprland's own frame-timing overlay. This is how
-- you find out what a setting actually costs instead of guessing: change
-- one value, hit SUPER+SHIFT+C to reload, watch the numbers.
local overlay = (os.getenv("HYPR_OVERLAY") == "1")

---------------------------
---- PALETTE --------------
---------------------------
-- Lifted straight out of the kali-clean i3 config:
--   $bg       1C1D2B  i3bar background
--   $bgAlt    282A3E  focused workspace / module background
--   $fg       E6FFF5  statusline foreground
--   $accent   82c8ff  client.focused border
--   $inactive 333333  client.unfocused border
--   $urgent   900000  client.urgent
--   $vpn      3BB92D  i3blocks tun0 indicator
local accent   = "rgba(82c8ffff)"
local inactive = "rgba(333333ff)"

-- The focused window's border. Deliberately NOT $accent: the bar, the
-- launcher and the notifications keep kali-clean's blue, and the one thing
-- that says "this window has focus" is lime. #00FF00 is the same green the
-- kitty cursor already uses, so the two read as one accent.
-- At border_size = 1 a muted green would simply disappear -- a 1px line has
-- to be bright to register at all, which is why this is full-intensity.
local focus    = "rgba(00ff00ff)"
local shadowC  = "rgba(1a1a1aee)"
local barBg    = "rgba(1C1D2Bff)"
local barBgAlt = "rgba(282A3Eff)"

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nemo"
local menu        = "~/.config/hypr/scripts/launcher.sh"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Wallpaper: the Wayland stand-in for kali-clean's ~/.fehbg (feh cannot
    -- paint a Wayland root window, so swaybg does it).
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh")

    -- Bar, notifications, tray applet
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("nm-applet --indicator")

    -- Whichever polkit agent this box actually shipped
    hl.exec_cmd("~/.config/hypr/scripts/polkit-agent.sh")

    -- i3-kitty's VM clipboard fix, unchanged
    hl.exec_cmd("~/.config/i3/clipboard_fix.sh")

    -- i3-kitty: exec --no-startup-id clipmenud
    -- clipmenud is X11. cliphist is the Wayland store: wl-paste watches the
    -- clipboard and pipes every change into it, and SUPER+C picks one back
    -- out (see scripts/clipboard.sh). Harmless no-op if cliphist is absent.
    hl.exec_cmd("command -v cliphist >/dev/null 2>&1 && wl-paste --type text --watch cliphist store")
    hl.exec_cmd("command -v cliphist >/dev/null 2>&1 && wl-paste --type image --watch cliphist store")

    -- i3-kitty: exec --no-startup-id vmware-user-suid-wrapper
    -- Drives VMware guest clipboard sync and display resize.
    hl.exec_cmd("command -v vmware-user-suid-wrapper >/dev/null 2>&1 && vmware-user-suid-wrapper")

    -- ...but only half of it. vmware-user resizes the display through
    -- xrandr, which is an X11 call with no Wayland equivalent, so under
    -- Hyprland the guest never follows the VMware window. vmwgfx still
    -- publishes the new size as the connector's preferred mode; this
    -- watches for that and applies it.
    hl.exec_cmd("~/.config/hypr/scripts/vmware-autofit.sh")

    -- vmtoolsd only bridges the X11 CLIPBOARD selection to the host, but
    -- every client here is Wayland-native (xwayland: 0), so their
    -- clipboard writes never reach it on their own. This mirrors the two
    -- clipboards both ways so host<->guest copy/paste actually works.
    hl.exec_cmd("~/.config/hypr/scripts/vmware-clipboard-bridge.sh")

    -- Hand the session environment to systemd/dbus so portals and tray work
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Rescue terminal. Cheap insurance: if keybinds ever fail to register
    -- again you still land in a usable window instead of a bare desktop.
    hl.exec_cmd(terminal)
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE",       "24")
hl.env("HYPRCURSOR_SIZE",    "24")
hl.env("XCURSOR_THEME",      "Dracula-cursors")
hl.env("QT_QPA_PLATFORM",    "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND",        "wayland,x11")
hl.env("SDL_VIDEODRIVER",    "wayland")
hl.env("CLUTTER_BACKEND",    "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Software rendering: keep these consistent with the session wrapper
-- (vmware/start-hyprland-vmware decides the same thing from dmesg).
hl.env("LIBGL_ALWAYS_SOFTWARE",    "1")
hl.env("WLR_NO_HARDWARE_CURSORS",  "1")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        -- gaps_in  = between windows        (i3 `gaps inner`)
        -- gaps_out = between windows and the SCREEN EDGE (i3 `gaps outer`)
        --
        -- i3-kitty had inner 4 / outer 2, which left windows almost flush
        -- against the edge of the screen. The spacing between windows was
        -- already fine, so only gaps_out goes up.
        gaps_in  = 4,
        gaps_out = 10,

        -- 1px: as thin as Hyprland will draw and still show a colour.
        -- (0 removes the border entirely, along with the focus indicator
        -- and the drag-to-resize edge, so 1 is the real minimum.)
        -- This is a global -- Hyprland draws the frame for EVERY window,
        -- Wayland-native and XWayland alike -- so "all apps" needs no
        -- per-app rules. The i3 config carries the same `border pixel 1`.
        border_size = 1,

        col = {
            -- Focused: lime. Unfocused: kali-clean's #333333, which at 1px
            -- is almost invisible -- exactly the point, only the active
            -- window should draw the eye.
            active_border   = focus,
            inactive_border = inactive,
        },

        layout           = "dwindle",
        resize_on_border = true,
        allow_tearing    = false,
    },

    decoration = {
        -- Rounded corners: the first thing i3 never had.
        rounding       = 10,
        rounding_power = 2.0,

        -- Leave these at 1.0. Per-window transparency comes from the app
        -- itself (kitty's background_opacity) so blur has real alpha to
        -- work behind; stacking a second opacity on top double-dims it.
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- Shadows are overdraw around every window on screen, for the
        -- smallest visual return of anything here. `soft` and `lite` skip
        -- them; only `full` pays.
        shadow = {
            enabled      = fx.shadow,
            range        = 14,
            render_power = 3,
            color        = shadowC,
            offset       = { 0, 0 },
        },

        -- Blur: the second thing i3 never had. kitty sits at 0.83 alpha,
        -- so this is what you actually see through it.
        blur = {
            enabled = fx.blur,
            size    = fx.blur_size,
            passes  = fx.blur_passes,

            -- Non-negotiable on a CPU renderer: this is what stops a still
            -- window from being re-blurred on every single frame.
            new_optimizations = true,

            xray               = fx.blur_xray,
            ignore_opacity     = true,
            popups             = fx.blur_popups,
            popups_ignorealpha = 0.2,
            noise              = fx.blur_noise,
            contrast           = 1.0,
            brightness         = 1.0,
            vibrancy           = fx.blur_vibrancy,
            vibrancy_darkness  = 0.0,

            -- The special (scratchpad) workspace is not bound to a key in
            -- this keymap, so never spend blur on it.
            special = false,
        },

        dim_inactive = false,
        dim_strength = 0.05,
    },

    dwindle = {
        -- `pseudotile` is no longer a dwindle option in 0.56; it lives on
        -- as the SUPER+P dispatcher and the `pseudo` window rule.
        preserve_split = true,
        smart_split    = false,
    },

    master = {
        new_status = "master",
    },

    -- Hyprland's answer to i3's stacking/tabbed layouts (SUPER+S / SUPER+W)
    group = {
        col = {
            -- Same rule as a normal window: the active one is lime.
            border_active   = focus,
            border_inactive = inactive,
        },
        groupbar = {
            enabled       = true,
            font_family   = "Hack Nerd Font",
            font_size     = 10,
            height        = 16,
            gradients     = false,
            render_titles = true,
            col = {
                active   = barBgAlt,
                inactive = barBg,
            },
        },
    },

    misc = {
        force_default_wallpaper         = 0,
        disable_hyprland_logo           = true,
        disable_splash_rendering        = true,
        disable_hyprland_guiutils_check = true,
        mouse_move_enables_dpms         = true,
        key_press_enables_dpms          = true,
        focus_on_activate               = true,
    },
})

-- Renderer / logging. NOTE: vfr lives under `debug`, not `misc`.
hl.config({
    debug = {
        -- Skip redraws when nothing changed. Costs nothing when you have a
        -- GPU, and is the single biggest win when you do not.
        vfr = true,

        -- Logs stay ON and also go to stdout. The runtime log lives in
        -- /run/user/1000/hypr/<id>/hyprland.log, which is tmpfs and is gone
        -- the moment the VM is powered off -- and a session you cannot type
        -- in is one you can only end by powering off. stdout is captured to
        -- ~/hyprland-last.log by the session wrapper and survives that.
        disable_logs       = false,
        enable_stdout_logs = true,

        -- HYPR_OVERLAY=1: live frame timings, for tuning the profile above.
        overlay = overlay,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- This box is a Spanish layout. Change to "us" (or whatever you
        -- use) if you are not; it is the only machine-specific line here.
        kb_layout  = "es",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- No touchpad gestures: 0.56 declares them with hl.gesture(), and defining
-- none is how you get kali-clean's behaviour (i3 had no gestures either).

--------------------
---- ANIMATIONS ----
--------------------
-- The third thing i3 never had. Curves are named after what they feel like.

hl.curve("wind",      { type = "bezier", points = { {0.05, 0.9},  {0.1,  1.05} } })
hl.curve("overshot",  { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.10} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0.00}, {0.66, -0.56} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.25, 1.00}, {0.50, 1.00} } })
hl.curve("linear",    { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.config({ animations = { enabled = fx.anim } })

if fx.anim then
    -- `speed` is in deciseconds: fx.anim_speed = 3 is a 300ms animation.
    -- On a CPU renderer the honest lever is duration, not curve -- a
    -- shorter animation is literally fewer frames to composite.
    local s = fx.anim_speed

    -- Window open/close/move: bounded to one window's box, so these are
    -- the animations worth keeping. This is the "windows animate" the
    -- whole exercise was about.
    hl.animation({ leaf = "windows",     enabled = true, speed = s,     bezier = "overshot",  style = "popin 80%" })
    hl.animation({ leaf = "windowsIn",   enabled = true, speed = s,     bezier = "overshot",  style = "popin 80%" })
    hl.animation({ leaf = "windowsOut",  enabled = true, speed = s - 1, bezier = "smoothOut", style = "popin 80%" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = s - 1, bezier = "wind",      style = "slide" })

    -- Border colour crossfade -- this is what you see on every SUPER+arrow.
    -- It was `speed = 10`, and speed is in DECISECONDS, so that was a full
    -- one-second fade from grey to lime: the "border changes slowly" you
    -- were looking at. fx.border_speed is 1 in `soft` (100ms), which reads
    -- as instant while still smoothing the colour step.
    hl.animation({ leaf = "border",      enabled = true, speed = fx.border_speed, bezier = "linear" })

    -- Opacity fades: cheap, and they are what stops windows from popping.
    -- The parent `fade` leaf covers both directions; naming the In/Out
    -- children as well lets a window fade in gently and leave briskly,
    -- which is what makes a close feel responsive rather than sluggish.
    hl.animation({ leaf = "fade",        enabled = true, speed = s + 2, bezier = "smoothIn" })
    hl.animation({ leaf = "fadeIn",      enabled = true, speed = s + 2, bezier = "smoothIn" })
    hl.animation({ leaf = "fadeOut",     enabled = true, speed = s,     bezier = "smoothOut" })
    -- fadeSwitch is the other half of the focus change. Leaving it at
    -- s+2 (500ms) would keep SUPER+arrow feeling sluggish even with the
    -- border fixed, so it tracks border_speed instead.
    hl.animation({ leaf = "fadeSwitch",  enabled = true, speed = fx.border_speed + 1, bezier = "smoothIn" })
    hl.animation({ leaf = "fadeDim",     enabled = true, speed = s + 2, bezier = "smoothIn" })

    -- Bar, launcher and notifications: layer surfaces, small area, so the
    -- slide is affordable even on llvmpipe. wofi sliding in on SUPER+D and
    -- dunst popups easing in are the two you actually notice.
    hl.animation({ leaf = "layers",      enabled = true, speed = s,     bezier = "overshot",  style = "slide" })
    hl.animation({ leaf = "layersIn",    enabled = true, speed = s,     bezier = "overshot",  style = "slide" })
    hl.animation({ leaf = "layersOut",   enabled = true, speed = s - 1, bezier = "smoothOut", style = "slide" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = s + 2, bezier = "smoothIn" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = s,     bezier = "smoothOut" })

    -- Workspace switching moves EVERY pixel on screen for the whole
    -- duration of the animation. It is by far the most expensive thing in
    -- this file on a CPU renderer, and it is the one you trigger most
    -- often. `full` gets the slide; `soft` switches instantly.
    -- Workspace switching. `slide` (horizontal) rather than the old
    -- `slidevert`, because SUPER+1..0 reads as a row, not a column -- the
    -- workspaces slide the way the number keys are laid out.
    --
    -- `wind` rather than `overshot`: an overshoot bezier travels past the
    -- target and comes back, which on a full-screen slide means compositing
    -- extra frames of the whole screen for an effect you barely see.
    if fx.anim_workspaces then
        hl.animation({ leaf = "workspaces",    enabled = true, speed = fx.ws_speed, bezier = "wind", style = "slide" })
        hl.animation({ leaf = "workspacesIn",  enabled = true, speed = fx.ws_speed, bezier = "wind", style = "slide" })
        hl.animation({ leaf = "workspacesOut", enabled = true, speed = fx.ws_speed, bezier = "wind", style = "slide" })
    else
        hl.animation({ leaf = "workspaces", enabled = false })
    end
end

----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- No opacity rule for kitty on purpose: kitty draws itself at
-- background_opacity 0.83 and Hyprland blurs whatever alpha the app hands
-- it. A rule here would multiply with that and turn the terminal murky.
--
-- Alacritty has no equivalent knob in kali-clean's alacritty.yml, so it
-- gets its 85% here -- the same value compton used in the i3 setup.
hl.window_rule({
    name    = "alacritty-opacity",
    match   = { class = "^(Alacritty)$" },
    opacity = "0.85 0.85",
})

-- Float the dialogs i3 would have floated anyway
hl.window_rule({ name = "float-pavucontrol", match = { class = "^(pavucontrol)$" },          float = true })
hl.window_rule({ name = "float-nm-editor",   match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "float-blueman",     match = { class = "^(blueman-manager)$" },      float = true })
-- Nemo's equivalent of Thunar's "File Operation Progress": a separate
-- window, titled "File Operations", that appears while a copy or move runs
-- with no main window to host the popover.
hl.window_rule({
    name  = "float-nemo-progress",
    match = { class = "^(nemo)$", title = "^(File Operations)$" },
    float = true,
})
hl.window_rule({ name = "float-pip", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })

-- XWayland apps that come up misdrawn on a VM
hl.window_rule({
    name    = "flameshot-noblur",
    match   = { class = "^(flameshot)$", xwayland = true },
    no_blur = true,
})

---------------------
---- LAYER RULES ----
---------------------
-- Blur behind the bar, the launcher and notifications.

-- waybar repaints about once a second and is otherwise static, so
-- new_optimizations caches its blur and it costs essentially nothing.
hl.layer_rule({ name = "blur-waybar",        match = { namespace = "waybar" },        blur = true, ignore_alpha = 0.0 })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.0 })

-- NO BLUR ON THE LAUNCHER. This is half of the "SUPER+D stutters when I
-- type" fix. A launcher repaints its whole surface on every keystroke as
-- the result list changes, and a blurred surface has to have its blur
-- recomputed on every one of those repaints -- new_optimizations cannot
-- cache anything that keeps changing. On llvmpipe that is a full-surface
-- gaussian per keypress, which is exactly where the dropped keystrokes
-- came from. The other half is the launcher itself: see launcher.sh.
hl.layer_rule({ name = "noblur-fuzzel", match = { namespace = "launcher" }, blur = false })
hl.layer_rule({ name = "noblur-wofi",   match = { namespace = "wofi" },     blur = false })

---------------------
---- KEYBINDINGS ----
---------------------
-- One-for-one with kali-clean's i3 config, except where noted.

local mainMod = "SUPER"

-- RESCUE BINDS. Deliberately avoid SUPER: if the host grabs the Super key,
-- or if a SUPER bind fails to register, these still get you a terminal and
-- a clean way out instead of a power cycle.
-- `submap_universal` keeps them alive inside the resize submap too.
--
-- Note what is NOT here: CTRL+ALT+F1..F12. Those need no binding at all.
-- Hyprland handles them internally in CKeybindManager::handleVT, which is
-- called straight from onKeyEvent and never consults the submap or the
-- user's binds -- it hands the VT switch to libseat/logind, so it needs no
-- root either. CTRL+ALT+F3 is therefore the one escape that survives every
-- mistake in this file. Binding it here could only make things worse.
hl.bind("CTRL + ALT + T",         hl.dsp.exec_cmd(terminal), { submap_universal = true })
hl.bind("ALT + Return",           hl.dsp.exec_cmd(terminal), { submap_universal = true })
hl.bind("CTRL + ALT + BackSpace", hl.dsp.exit(),             { submap_universal = true })

-- --- Launching / killing ---------------------------------------------------
-- i3: bindsym $mod+Return exec alacritty  (kitty here, for the blur)
hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd(terminal))
-- i3: bindsym $mod+Shift+q kill
hl.bind(mainMod .. " + SHIFT + Q",      hl.dsp.window.close())
-- i3: bindsym $mod+d exec "rofi -show run"
hl.bind(mainMod .. " + D",              hl.dsp.exec_cmd(menu))
-- Extra: file manager
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(fileManager))

-- Browser. Goes through a wrapper because Firefox is single-instance per
-- profile and finds the running copy over the *user* D-Bus bus, which
-- dbus-user-session shares across every login session -- so while the X11
-- session is also logged in, a plain `firefox` here just makes a window
-- appear over there. scripts/firefox.sh detects that and starts an
-- independent instance instead. See the header of that script.
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("~/.config/hypr/scripts/firefox.sh"))

-- --- Focus -----------------------------------------------------------------
-- i3-kitty uses j = left, k = down, i = up, o = right.
--
-- NOT the kali-clean j/k/l/semicolon row: this repo moved `up` and `right`
-- onto i and o, which sit directly above k and l on the keyboard and need
-- no Spanish-layout special case for `;`. kitty's own
-- ctrl+j/k/i/o neighboring_window binds match, so moving between kitty
-- splits and between Hyprland windows uses the same four keys.
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "down"  }))
hl.bind(mainMod .. " + I", hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + O", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-- --- Moving windows --------------------------------------------------------
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "down"  }))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.window.move({ direction = "right" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- --- Splits and layout -----------------------------------------------------
-- i3: $mod+h split h / $mod+v split v. dwindle's `preselect` is the same
-- idea: it decides where the *next* window lands.
hl.bind(mainMod .. " + H", hl.dsp.layout("preselect r"))
hl.bind(mainMod .. " + V", hl.dsp.layout("preselect d"))
-- i3: $mod+e layout toggle split
hl.bind(mainMod .. " + E", hl.dsp.layout("togglesplit"))

-- i3: $mod+s layout stacking / $mod+w layout tabbed. Hyprland has one
-- primitive for both -- groups -- so both keys toggle it, Tab walks it.
hl.bind(mainMod .. " + S",         hl.dsp.group.toggle())
hl.bind(mainMod .. " + W",         hl.dsp.group.toggle())
hl.bind(mainMod .. " + Tab",       hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.group.prev())

-- i3: $mod+f fullscreen toggle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- --- Floating -------------------------------------------------------------
-- These two are easy to mix up, so, precisely:
--
--   i3:  bindsym $mod+Shift+space floating toggle   <- MAKES A WINDOW FLOAT
--   i3:  bindsym $mod+space       focus mode_toggle <- only MOVES FOCUS
--
-- The one that lifts a window out of the tiling layout and puts it back is
-- SUPER+SHIFT+SPACE. Plain SUPER+SPACE changes no window at all; it jumps
-- focus between the tiled windows and the floating ones. That is what
-- i3-kitty binds, so that is what is bound here.
--
-- (To make SUPER+SPACE the float toggle instead, swap the two dispatchers
-- below -- nothing else depends on either.)

-- Float / unfloat the focused window, and give it a sane size when it
-- becomes floating.
--
-- Hyprland hands a newly-floated window whatever geometry it had while
-- tiled, so floating a full-height tile produced a full-height floating
-- window. These two fractions of the monitor decide the shape instead --
-- deliberately wider than tall, so the window is SHORT in height.
-- Change them and reload (SUPER+SHIFT+C); nothing else depends on them.
local FLOAT_W = 0.55   -- 55% of the monitor width
local FLOAT_H = 0.40   -- 40% of the monitor height

hl.bind(mainMod .. " + SHIFT + space", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))

    local win = hl.get_active_window()
    -- Only resize on the way INTO floating. Going back to tiled, the
    -- layout owns the geometry and we must not touch it.
    if not win or not win.floating then return end

    local mon = hl.get_active_monitor()
    if not mon then return end

    -- HL.Monitor.width/height are in physical pixels; divide by scale to
    -- get the logical size a window is placed in.
    local scale = mon.scale
    if not scale or scale == 0 then scale = 1 end
    local w = math.floor((mon.width  / scale) * FLOAT_W)
    local h = math.floor((mon.height / scale) * FLOAT_H)

    -- resize takes { x, y, relative?, window? }. Without `relative` the
    -- values are the target SIZE rather than a delta -- that is what the
    -- optional flag is distinguishing, and it mirrors the legacy
    -- `resizeactive exact W H` form.
    hl.dispatch(hl.dsp.window.resize({ x = w, y = h }))
    hl.dispatch(hl.dsp.window.center())
end)

-- i3's `focus mode_toggle`, implemented properly.
--
-- Hyprland has no single dispatcher for this. The usual approximation is
-- `cyclenext floating`, but that cycles *within* the floating windows
-- rather than crossing between the two layers, and it misbehaves when
-- nothing is floating. hl.bind takes a plain Lua function as its
-- dispatcher, and the query API is fully typed in
-- /usr/share/hypr/stubs/hl.meta.lua, so the real behaviour is a few lines:
-- look at what is focused, and focus something in the other mode on this
-- workspace.
hl.bind(mainMod .. " + space", function()
    local current = hl.get_active_window()
    if not current then return end

    local workspace = hl.get_active_workspace()
    if not workspace then return end

    -- HL.Window.floating is a boolean; HL.WindowQueryFilter accepts
    -- `floating` and `workspace`; HL.WorkspaceSelector accepts the
    -- workspace object itself.
    local others = hl.get_windows({
        floating  = not current.floating,
        workspace = workspace,
    })

    -- Nothing in the other mode: leave focus where it is rather than
    -- jumping somewhere surprising.
    if not others or #others == 0 then return end

    -- HL.WindowSelector is string|integer|HL.Window, so the window object
    -- goes straight to focus.
    hl.dispatch(hl.dsp.focus({ window = others[1] }))
end)

-- i3: bindsym $mod+a focus parent
--
-- This is the ONE binding in kali-clean's i3 config with no true Hyprland
-- equivalent. i3 builds a tree of containers and $mod+a walks up it, so
-- the next command applies to the parent instead of the window. dwindle
-- has no addressable parent container and 0.56 ships no `focusparent`
-- dispatcher -- `strings /usr/bin/Hyprland` lists movefocus, focuswindow,
-- focuscurrentorlast and the group dispatchers, and nothing else.
--
-- So SUPER+A gets the nearest thing that is actually useful rather than
-- being left dead: jump back to the window you were on last. If what you
-- wanted the parent for was "treat these windows as one unit", that is
-- SUPER+S / SUPER+W (groups).
--
-- `last` is the verified key -- Hyprland's own error text spells out the
-- accepted set: "hl.focus: unrecognized arguments. Expected one of:
-- direction, monitor, window, urgent_or_last, last".
hl.bind(mainMod .. " + A", hl.dsp.focus({ last = true }))

-- i3-kitty: bindsym $mod+c exec --no-startup-id clipmenu
-- clipmenu is X11-only; cliphist is the Wayland equivalent.
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard.sh"))
-- Same picker, but deletes the chosen entry instead of pasting it.
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-delete.sh"))

-- i3-kitty: bindsym $mod+n  rename the focused workspace (was i3-input)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace-rename.sh"))
-- i3-kitty: bindsym $mod+b  clear the name, back to the bare number
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/workspace-clear.sh"))

-- Extra dwindle niceties. Centre moved off SUPER+C, which i3-kitty uses
-- for the clipboard.
hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + Comma",  hl.dsp.window.center())

-- --- Workspaces ------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10  -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- --- Session ---------------------------------------------------------------
-- i3: $mod+Shift+c reload / $mod+Shift+r restart. Both reload here, since
-- Hyprland re-reads its config in place and has no separate restart.
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
-- i3: $mod+Shift+e exit (i3-nagbar). wofi stands in for the nagbar.
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/exit.sh"))

-- --- Screenshot ------------------------------------------------------------
-- i3: bindsym $mod+P exec flameshot gui  ->  grim + slurp, copied and saved
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind("Print",                   hl.dsp.exec_cmd("grim - | wl-copy"))

-- --- Mouse -----------------------------------------------------------------
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- --- Media / volume keys (no i3 equivalent, but free) ----------------------
-- wpctl, not pactl: this box runs PipeWire/WirePlumber and has no
-- pulseaudio-utils installed.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })

-- --- Resize outside the mode ----------------------------------------------
-- i3-kitty has two sets: CTRL for fine 1px nudges, CTRL+SHIFT for 20px
-- steps, each on both j/i/k/o and the arrow keys.
--
-- i3's `resize shrink width` shrinks from the right edge, so the sign
-- convention below matches: j/left shrink width, o/right grow width.

-- fine: 1px
hl.bind(mainMod .. " + CTRL + J",     hl.dsp.window.resize({ x = -1, y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + I",     hl.dsp.window.resize({ x = 0,  y = 1,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K",     hl.dsp.window.resize({ x = 0,  y = -1, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + O",     hl.dsp.window.resize({ x = 1,  y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -1, y = 0,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,  y = 1,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,  y = -1, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 1,  y = 0,  relative = true }), { repeating = true })

-- coarse: 20px
hl.bind(mainMod .. " + CTRL + SHIFT + J",     hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + I",     hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + K",     hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + O",     hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })

-----------------------------------------------------------------------------
-- RESIZE MODE -- i3's `mode "resize"`, entered with SUPER+R
-----------------------------------------------------------------------------

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    -- i3-kitty's resize mode: j shrink width / i grow height /
    -- k shrink height / o grow width, all 20px.
    hl.bind("J", hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
    hl.bind("I", hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
    hl.bind("K", hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
    hl.bind("O", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })

    -- and the same on the arrows
    hl.bind("left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { repeating = true })
    hl.bind("right", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { repeating = true })

    -- i3: Return or Escape go back to "default"
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)
