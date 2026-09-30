# Design system

## Identity

Chara Crimson uses near-black `#100D11`, warm bone text `#F0E5DF`, and crimson
`#F13B45` as its persistent accent. Red pixel souls, SAVE text, and squared
corner frames carry the Undertale identity. Other soul colors communicate state:

- red: determination, critical failure, or destructive confirmation;
- orange: warning or active recording;
- yellow: attention and pending work;
- green: success and healthy state;
- cyan: network and Bluetooth;
- blue: capture and informational state;
- purple: secondary status and ANSI output.

Sharp battle-box corners, compact spacing, restrained translucency, and short
animations keep the theme recognizable without sacrificing daily readability.

## Components

- Rise V1 owns the primary panel; V2 remains a compatible optional variant.
- Omarchy Shell owns launcher, notifications, OSD, lock, idle, and menus.
- Native Rise Codex usage is retained instead of adding a duplicate agent.
- Mirador owns workspace overview; Quick Look owns file preview.
- The live wallpaper is optional and isolated in a restartable user service.
- Chara's menu reuses Omarchy's native application catalog, with a local
  AppLibrary fallback when a cloned plugin's scoped facade lacks the catalog.
- Rise V1 panels share a static PixelPanelFrame; the existing controls retain
  input ownership. The calendar keeps date delegates stable across month changes.
- The browser keeps a dark burgundy seed color. `lucent-chara` preserves
  OpenCode's transparent dark surfaces while recoloring its orange accents.

## Portability boundaries

The repository deliberately excludes location, monitor names, Bluetooth MAC
addresses, package inventories, local backup timestamps, fonts with restricted
terms, and fan-art files. User-specific values live in environment or local
configuration files outside Git.
