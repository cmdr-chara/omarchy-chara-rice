# Design system

## Identity

The desktop uses near-black and dark burgundy foundations with muted garnet
`#A45D68` as the persistent accent. Permanent UI avoids saturated bright red.
Undertale's soul colors appear only when they communicate a state:

- red: determination, critical failure, or destructive confirmation;
- orange: warning or active recording;
- yellow: attention and pending work;
- green: success and healthy state;
- cyan: network and Bluetooth;
- blue: capture and informational state;
- purple: media and audio.

Rounded battle-box outlines, compact spacing, restrained translucency, and short
animations keep the theme recognizable without sacrificing daily readability.

## Components

- Rise V1 owns the primary panel; V2 remains a compatible optional variant.
- Omarchy Shell owns launcher, notifications, OSD, lock, idle, and menus.
- Native Rise Codex usage is retained instead of adding a duplicate agent.
- Mirador owns workspace overview; Quick Look owns file preview.
- The live wallpaper is optional and isolated in a restartable user service.

## Portability boundaries

The repository deliberately excludes location, monitor names, Bluetooth MAC
addresses, package inventories, local backup timestamps, fonts with restricted
terms, and fan-art files. User-specific values live in environment or local
configuration files outside Git.
