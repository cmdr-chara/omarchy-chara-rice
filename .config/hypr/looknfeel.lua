-- Chara Crimson: crisp edges, generous spacing, responsive motion.
-- Theme colors still come from Omarchy's generated current/theme/hyprland.lua.

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 2,
    resize_on_border = true,
  },

  decoration = {
    rounding = 2,
    dim_inactive = true,
    dim_strength = 0.04,

    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = "rgba(07060add)",
    },

    blur = {
      enabled = true,
      size = 5,
      passes = 2,
      vibrancy = 0.08,
    },
  },
})

-- Mirador exposes a transparent overview layer; compositor blur keeps the
-- overview legible without adding a second background or animation service.
hl.layer_rule({
  name = "mirador-blur",
  match = { namespace = "^omarchy-workspace-overview$" },
  blur = true,
})

-- Responsive Chara transitions: retain blur, shadows, and easing, with less
-- zoom and shorter opening/moving animations on the laptop's 60 Hz panel.
-- Hyprland animation speed is a duration in deciseconds.
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.6, bezier = "easeOutQuint", style = "popin 98%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.4, bezier = "linear", style = "popin 98%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "almostLinear" })
hl.animation({ leaf = "border", enabled = true, speed = 2.2, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.4, bezier = "linear", style = "fade" })
