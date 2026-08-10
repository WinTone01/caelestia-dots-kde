#!/usr/bin/env python3
"""Write Caelestia's current colour scheme out as a Vicinae theme.

Vicinae reads themes from $XDG_DATA_HOME/vicinae/themes and watches that
directory, so dropping an updated file in is enough for a running instance to
pick it up — no restart, no IPC. Caelestia publishes the scheme it generated
from the wallpaper to ~/.local/state/caelestia/scheme.json, so the two only
need this translation between them.

Only the colours Vicinae cannot derive on its own are written. Everything else
it works out from the core set, so the file stays short and there is less to
drift when either palette changes.

Usage:
    vicinae-theme.py            # regenerate from the current scheme
    vicinae-theme.py --print    # write nothing, dump the theme to stdout
"""

import json
import os
import sys
from pathlib import Path

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "caelestia/scheme.json"
THEMES = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "vicinae/themes"
THEME_ID = "caelestia"


def hexc(colours: dict, *names: str) -> str:
    """First of `names` present in the scheme, as #rrggbb.

    Schemes carry the Material roles plus whatever extras their flavour adds,
    so the accent lookups list a Material fallback behind the nicer name.
    """
    for name in names:
        value = colours.get(name)
        if value:
            return value if value.startswith("#") else f"#{value}"
    raise KeyError(f"scheme has none of {names}")


def build(scheme: dict) -> str:
    c = scheme["colours"]
    dark = scheme.get("mode", "dark") != "light"
    name = scheme.get("name", "caelestia")
    flavour = scheme.get("flavour", "")
    label = f"Caelestia ({name} {flavour})".replace(" )", ")")

    return f"""# Generated from Caelestia's colour scheme — do not edit by hand.
# Regenerate with: shell/scripts/vicinae-theme.py
# Source: {STATE}

[meta]
version = 1
name = "{label}"
description = "Caelestia's active Material palette"
variant = "{'dark' if dark else 'light'}"

[colors.core]
background = "{hexc(c, 'surface', 'background')}"
foreground = "{hexc(c, 'onSurface', 'text')}"
secondary_background = "{hexc(c, 'surfaceContainer')}"
border = "{hexc(c, 'outlineVariant')}"
accent = "{hexc(c, 'primary')}"
accent_foreground = "{hexc(c, 'onPrimary')}"

[colors.accents]
blue = "{hexc(c, 'blue', 'primary')}"
green = "{hexc(c, 'green', 'success', 'tertiary')}"
red = "{hexc(c, 'red', 'error')}"
yellow = "{hexc(c, 'yellow', 'tertiary')}"
orange = "{hexc(c, 'peach', 'tertiary')}"
magenta = "{hexc(c, 'pink', 'tertiary')}"
purple = "{hexc(c, 'mauve', 'lavender', 'tertiary')}"
cyan = "{hexc(c, 'teal', 'sky', 'secondary')}"

[colors.text]
muted = "{hexc(c, 'onSurfaceVariant')}"
danger = "{hexc(c, 'error')}"
success = "{hexc(c, 'success', 'green', 'tertiary')}"
placeholder = "{hexc(c, 'outline')}"
selection = {{ background = "{hexc(c, 'primary')}", foreground = "{hexc(c, 'onPrimary')}" }}

[colors.input]
border = "{hexc(c, 'outlineVariant')}"
border_focus = "{hexc(c, 'primary')}"
border_error = "{hexc(c, 'error')}"

[colors.list.item.selection]
background = "{hexc(c, 'surfaceContainerHigh')}"
secondary_background = "{hexc(c, 'surfaceContainerHighest')}"

[colors.grid.item]
background = "{hexc(c, 'surfaceContainer')}"

[colors.scrollbars]
background = "{hexc(c, 'outlineVariant')}"

[colors.loading]
bar = "{hexc(c, 'primary')}"
spinner = "{hexc(c, 'onSurface', 'text')}"
"""


def main(argv: list[str]) -> int:
    if not STATE.is_file():
        print(f"no scheme at {STATE} — is the shell running?", file=sys.stderr)
        return 1

    try:
        theme = build(json.loads(STATE.read_text()))
    except (json.JSONDecodeError, KeyError) as exc:
        print(f"cannot build theme from {STATE}: {exc}", file=sys.stderr)
        return 1

    if "--print" in argv:
        print(theme, end="")
        return 0

    THEMES.mkdir(parents=True, exist_ok=True)
    out = THEMES / f"{THEME_ID}.toml"
    # Write and move, so Vicinae's directory watcher never sees a half file.
    tmp = out.with_suffix(".toml.tmp")
    tmp.write_text(theme)
    tmp.replace(out)
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
