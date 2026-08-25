# Security policy

Please report a suspected credential leak, unsafe installer behavior, or command
injection privately through GitHub's security-advisory interface for this
repository. Do not include real credentials, private configuration, or personal
logs in a public issue.

The installer is intentionally user-scoped, refuses root execution, never edits
`/usr/share/omarchy`, and requires `--yes`. Optional package installation and
live-wallpaper activation require separate flags.
