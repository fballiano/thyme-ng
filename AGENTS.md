# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

`thyme-ng` is a macOS menu bar stopwatch. It is a complete rewrite of
[Thyme](https://github.com/joaomoreno/thyme) by João Moreno. The behaviour is the
same. The implementation is new: Swift 6, SwiftUI, SwiftData.

The application is an agent application (`LSUIElement: true`). It has no dock
icon and no ordinary windows.

## Commands

```bash
make build       # build the Release app into ./build
make debug       # build the Debug app into ./build
make test        # run the unit tests
make run         # build, then launch the app
make install     # copy the app into /Applications
make dmg         # build the Release app and pack it into ./dist/*.dmg
make generate    # rebuild ThymeNG.xcodeproj from project.yml (needs xcodegen)
make clean       # remove ./build and ./dist
```

To run one test suite or one test:

```bash
xcodebuild -project ThymeNG.xcodeproj -scheme ThymeNG -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO \
  -only-testing:ThymeNGTests/StopwatchTests test
```

Add the test function name for one test, for example
`-only-testing:ThymeNGTests/StopwatchTests/counts`.

Parallel testing must stay off. The test bundle loads into the real application,
so a parallel run launches one copy of the application for each test worker.

To redraw the application icon: `swift Tools/make-icon.swift`.

The application icon and the menu bar icon are the same Tabler `stopwatch`
outline at stroke width 2. The path exists twice, because the icon script runs
outside the application and cannot import its code: in
`Sources/ThymeNG/Views/StopwatchGlyph.swift` and in `Tools/make-icon.swift`.
Change the two together.

## Releases

`.github/workflows/release.yml` publishes a release. A tag that starts with `v`
starts it:

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
```

The workflow runs the tests, calls `make dmg`, and attaches the disk image to a
new GitHub release. It passes the version of the tag as `MARKETING_VERSION` and
the run number as `CURRENT_PROJECT_VERSION`, so `project.yml` does not need a
change for each release.

The application is signed ad hoc. There is no Apple Developer ID and no
notarization, so macOS blocks the first launch. The release notes and the README
explain the two ways to open it.

## Project file

`ThymeNG.xcodeproj` is generated from `project.yml` by XcodeGen, but it is
committed. Change `project.yml` and run `make generate` for any change of the
project layout: a new package, a new target, a build setting, or an `Info.plist`
key. Do not edit `project.pbxproj` by hand.

The `Info.plist` at `Support/Info.plist` also receives keys from `project.yml`.

## Architecture

`AppModel` is the one controller, a `@MainActor @Observable` singleton
(`AppModel.shared`). Every way into the application calls the same method on it:

| Entry point | File |
| --- | --- |
| Menu | `Views/MenuContent.swift` |
| Global hot key | `HotKeys.swift`, wired in `AppModel.registerHotKeys()` |
| AppleScript | `Scripting/ScriptCommands.swift` with `Resources/thyme-ng.sdef` |
| Shortcuts and Spotlight | `Scripting/ThymeIntents.swift` |

Keep this rule. A new command needs one method on `AppModel`, then a call from
each entry point. Do not put logic in a view, a script command or an intent.

`Stopwatch` is the timer engine. The elapsed value always comes from a
`ContinuousClock`, a monotonic clock. The repeating timer only copies the exact
value into the observed `elapsed` property. Views read `elapsed`. Code that needs
the exact value reads `currentElapsed`. The timer runs in `RunLoop.Mode.common`,
so it keeps counting while the menu is open.

`SessionStore` holds the SwiftData container and does every read, write, prune
and export. `AppModel` keeps a plain `[Session]` array for the menu and calls
`reloadSessions()` after each change.

`Preferences` wraps `UserDefaults`. Each property writes back in its `didSet`.
`maxStoredSessions` uses a private backing property, because an assignment to an
`@Observable` property inside its own `didSet` recurses until the stack
overflows.

`SystemEvents` watches sleep, wake, screensaver and screen lock. `AppModel`
records whether the stopwatch ran, pauses it, and continues after the event.

### Test host

The tests load into the real application, so the application launches during a
test run. `RuntimeEnvironment.isRunningTests` guards the side effects:

- `AppModel.bootstrap()` does nothing, so no hot keys and no system events.
- `SessionStore` uses an in-memory container, so the live database is safe.
- `Notifier` does not ask for notification permission.
- `LoginItem` does not call `SMAppService`.

Add the same guard to any new code that touches the system or the user data.

### Injection for tests

`Stopwatch(now:)` takes the time source, so a test moves a fake clock by hand.
`SessionStore.makeContainer(inMemory: true)` gives a throw-away store.
`Preferences(defaults:)` takes a `UserDefaults` instance.
`AppModel(store:preferences:)` takes both.

## Conventions

- Swift 6 with `SWIFT_STRICT_CONCURRENCY: complete`. Almost every type is
  `@MainActor`. Callbacks from AppKit and from `KeyboardShortcuts` use
  `MainActor.assumeIsolated`.
- Tests use Swift Testing (`@Suite`, `@Test`, `#expect`), not XCTest.
- Comments explain why, and often name the behaviour of the original app that
  the code keeps or corrects. Keep that style.
- The export JSON shape and the AppleScript command codes match the original.
  Do not change them.
- The bundle identifier is `com.fabrizioballiano.thyme-ng`. The product name is
  `thyme-ng`. The module name is `ThymeNG`.
