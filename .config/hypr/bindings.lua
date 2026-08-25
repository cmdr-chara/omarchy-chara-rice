-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Familiar desktop shortcuts, while keeping Omarchy's minimal tiling workflow.
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("CTRL + ALT + T", "Terminal", { omarchy = "terminal" })

-- Omarchy's calculator preinstall has been removed.
hl.unbind("SUPER + CTRL + Q")
hl.unbind("XF86Calculator")

-- SUPER+SHIFT+S is an Omarchy web-app shortcut for Google Maps by default.
-- Reuse it for the familiar region screenshot shortcut.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- Zero-process volume and brightness controls. Hyprland dispatches each key
-- directly to the resident Chara OSD through its global-shortcut protocol.
hl.unbind("XF86AudioRaiseVolume")
hl.unbind("XF86AudioLowerVolume")
hl.unbind("XF86AudioMute")
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.unbind("SHIFT + XF86MonBrightnessUp")
hl.unbind("SHIFT + XF86MonBrightnessDown")
hl.unbind("ALT + XF86MonBrightnessUp")
hl.unbind("ALT + XF86MonBrightnessDown")

o.bind("XF86AudioRaiseVolume", "Volume up", hl.dsp.global("chara-osd:volume-up"), { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", hl.dsp.global("chara-osd:volume-down"), { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", hl.dsp.global("chara-osd:volume-mute"), { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", hl.dsp.global("chara-osd:brightness-up"), { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", hl.dsp.global("chara-osd:brightness-down"), { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", hl.dsp.global("chara-osd:brightness-max"), { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", hl.dsp.global("chara-osd:brightness-min"), { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precisely", hl.dsp.global("chara-osd:brightness-fine-up"), { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precisely", hl.dsp.global("chara-osd:brightness-fine-down"), { locked = true, repeating = true })

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Replace Omarchy's former Obsidian shortcut with Mirador.
hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "Workspace overview", "omarchy-shell shell toggle mirador '{}'")
