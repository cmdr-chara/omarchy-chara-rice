-- Chara — Determination visual overrides.
-- Theme colors still come from Omarchy's generated current/theme/hyprland.lua.

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
  },

  decoration = {
    rounding = 6,
    dim_inactive = true,
    dim_strength = 0.08,

    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "rgba(10090bcc)",
    },

    blur = {
      enabled = true,
      size = 4,
      passes = 1,
      vibrancy = 0.12,
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
