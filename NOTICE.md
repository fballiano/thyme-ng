# Third-party material

`thyme-ng` itself is MIT licensed. See [LICENSE](LICENSE).

## Thyme

`thyme-ng` reproduces the behaviour of Thyme by João Moreno. No code from that
project is copied; the whole implementation is new.

- Source: https://github.com/joaomoreno/thyme
- Licence: MIT, Copyright (c) João Moreno

## KeyboardShortcuts

Used for the global hot keys and for the shortcut recorder in the settings.
Fetched by Swift Package Manager, not vendored.

- Source: https://github.com/sindresorhus/KeyboardShortcuts
- Licence: MIT, Copyright (c) Sindre Sorhus

## Tabler Icons

The application icon redraws the `stopwatch` outline from Tabler Icons. The
24 x 24 path is reproduced in `Tools/make-icon.swift`.

- Source: https://tabler.io/icons
- Licence: MIT, Copyright (c) 2020-2026 Paweł Kuna

## SF Symbols

The menu bar uses the `stopwatch` symbol from SF Symbols, which ships with
macOS. It is drawn at run time by the system and is not redistributed with this
application.

Apple's licence does not allow an SF Symbol to be used as an application icon,
which is why the application icon comes from Tabler Icons instead.

- Source: Apple SF Symbols, https://developer.apple.com/sf-symbols/
- Licence: Apple SF Symbols licence agreement
