<div align="center">

<img src="Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="140" alt="thyme-ng" />

# thyme-ng

**A menu bar stopwatch for macOS.**

[![Latest release](https://img.shields.io/github/v/release/fballiano/thyme-ng?style=for-the-badge&color=2F7D3A&labelColor=1B1F23)](https://github.com/fballiano/thyme-ng/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/fballiano/thyme-ng/total?style=for-the-badge&color=2F7D3A&labelColor=1B1F23)](https://github.com/fballiano/thyme-ng/releases)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-2F7D3A?style=for-the-badge&labelColor=1B1F23&logo=apple&logoColor=white)](#install)
[![MIT licence](https://img.shields.io/badge/licence-MIT-2F7D3A?style=for-the-badge&labelColor=1B1F23)](LICENSE)

### [⬇︎ Download the latest DMG](https://github.com/fballiano/thyme-ng/releases/latest)

</div>

<table align=center><tr><td align=center>
<strong>If you find my work valuable, please consider sponsoring</strong><br />
<a href="https://github.com/sponsors/fballiano" target=_blank title="Sponsor me on GitHub"><img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#white" alt="Sponsor me on GitHub" /></a>
<a href="https://www.buymeacoffee.com/fballiano" target=_blank title="Buy me a coffee"><img src="https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy me a coffee" /></a>
<a href="https://www.paypal.com/paypalme/fabrizioballiano" target=_blank title="Donate via PayPal"><img src="https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Donate via PayPal" /></a>
</td></tr></table>

---

## Features

| | |
| --- | --- |
| **Always in view** | The menu bar shows `MM:SS`, then `HH:MM:SS` after an hour. |
| **Global hot keys** | Start, restart and finish from any application. |
| **Tagged sessions** | Every finished session keeps its date, its length and a label. |
| **Sleep aware** | It pauses on sleep, screensaver and screen lock, then continues. |
| **Scriptable** | AppleScript, Shortcuts and Spotlight drive the same commands. |
| **Your data, exported** | One click writes every session to JSON. |
| **Tidy by itself** | Old sessions go away, so the list stays short. |
| **Light** | A 2.5 MB universal application. No dock icon, no window in your way. |

## Install

Download the DMG from the [latest release](https://github.com/fballiano/thyme-ng/releases/latest).
Open it and drag **thyme-ng** into **Applications**.

> [!IMPORTANT]
> The application is signed ad hoc, not with an Apple Developer ID, so macOS
> blocks the first launch. Open **System Settings → Privacy & Security** and
> select **Open Anyway**.
>
> A terminal does the same thing:
>
> ```bash
> xattr -dr com.apple.quarantine /Applications/thyme-ng.app
> open /Applications/thyme-ng.app
> ```

The application has no dock icon. It appears in the menu bar.

| Item | Value |
| --- | --- |
| macOS | 15.0 or later |
| Hardware | Apple silicon and Intel (universal binary) |

## Settings

Open **Preferences…** from the menu, or press <kbd>⌘</kbd><kbd>,</kbd>.

| Setting | Default | What it does |
| --- | --- | --- |
| Pause during sleep | on | Pauses when the Mac sleeps, continues on wake. |
| Pause during screensaver or screen lock | on | Same, for the screen. |
| Ask for a tag when a session finishes | off | Shows a small window to label the session. |
| Show notifications | on | A banner on start, pause and stop. |
| Delete old sessions automatically | on, keep 10 | Keeps only the newest N sessions. |
| Start thyme-ng at login | off | Registers a login item through `SMAppService`. |

The **Shortcuts** tab holds the three global hot keys: Start / Pause, Restart and
Finish. No shortcut is set until you record one.

## Automation

```applescript
tell application "thyme-ng" to start
tell application "thyme-ng" to pause
tell application "thyme-ng" to toggle
tell application "thyme-ng" to restart
tell application "thyme-ng" to stop
tell application "thyme-ng" to elapsed   -- returns "12:34"
```

From a terminal:

```bash
osascript -e 'tell application "thyme-ng" to toggle'
```

The same commands are App Intents, so the Shortcuts app lists them under
**thyme-ng**: Start Timer, Pause Timer, Toggle Timer, Finish Timer and Get
Elapsed Time. Spotlight runs them too.

## Export

`Export…` writes a JSON array, newest session first:

```json
[
  {
    "date" : "2026-08-11T09:30:00+01:00",
    "duration" : 3661,
    "tag" : "writing"
  }
]
```

`duration` is a whole number of seconds.

## Where the data lives

| What | Where |
| --- | --- |
| Sessions | `~/Library/Application Support/thyme-ng/thyme-ng.store` (SwiftData) |
| Settings | `~/Library/Preferences/com.fabrizioballiano.thyme-ng.plist` |

<details>
<summary><strong>Build from source</strong></summary>

<br />

You need Xcode 26 or later.

```bash
make install     # build the Release app and copy it to /Applications
```

Other targets:

```bash
make build       # build only
make test        # run the unit tests
make run         # build, then launch
make dmg         # build the Release app and pack it into ./dist/*.dmg
make generate    # rebuild ThymeNG.xcodeproj from project.yml (needs xcodegen)
make uninstall   # remove /Applications/thyme-ng.app
```

To work in Xcode, open `ThymeNG.xcodeproj` and press Run. The project signs ad
hoc, which is enough for your own Mac. To sign with your Apple ID, select the
`ThymeNG` target, open **Signing & Capabilities**, and choose your team.

`ThymeNG.xcodeproj` is generated from `project.yml`, but it is committed, so you
do not need XcodeGen unless you change the project layout.

A push of a tag `v*` builds the DMG and publishes a release from GitHub Actions.

</details>

<details>
<summary><strong>How it is built</strong></summary>

<br />

| Part | Choice |
| --- | --- |
| Language | Swift 6, strict concurrency |
| Interface | SwiftUI `MenuBarExtra` |
| Storage | SwiftData |
| Notifications | `UserNotifications` |
| Global hot keys | [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) |
| Login item | `SMAppService` |
| Tests | Swift Testing |
| Project file | XcodeGen |

```
Sources/ThymeNG/
├── ThymeNGApp.swift        the scenes
├── AppModel.swift          the one controller
├── Stopwatch.swift         the timer engine
├── Session.swift           the stored model
├── SessionStore.swift      read, write, prune, export
├── Preferences.swift       the settings
├── HotKeys.swift           the global shortcut names
├── SystemEvents.swift      sleep, wake, screensaver, lock
├── Notifier.swift          banners
├── LoginItem.swift         start at login
├── TimeFormatter.swift     MM:SS and HH:MM:SS
├── Views/                  the menu, the settings, the tag prompt
└── Scripting/              AppleScript commands and App Intents
```

Every command has one code path. The menu, a hot key, an AppleScript command and
a Shortcuts action all call the same method on `AppModel`.

A few details worth knowing:

- The elapsed time comes from a monotonic clock, so a change of the system clock
  cannot corrupt a running session.
- The menu bar clock keeps counting while the menu is open.
- A running session is stored when you quit.
- The digits are monospaced, so the menu bar item does not jump every second.

</details>

## Credits

`thyme-ng` is a rewrite of [Thyme](https://github.com/joaomoreno/thyme) by João
Moreno, which stopped building on a current Mac. The behaviour is the same, the
implementation is new, and the AppleScript command names still match, so an old
script keeps working. The old Thyme database is not read.

Third-party material is listed in [NOTICE.md](NOTICE.md).

## Licence

MIT. See [LICENSE](LICENSE).
