# HomebrewApp

HomebrewApp is a native macOS SwiftUI app for browsing, installing, and maintaining Homebrew formulae and casks.

![HomebrewApp package browser showing installed packages, package actions, and the console dock.](app/HomebrewApp/HomebrewApp/HomebrewApp.docc/package-browser.png)

## Features

### Browse installed packages

- Load cached package information immediately, then refresh it from Homebrew.
- Search formulae and casks by name or description.
- Filter by package type, multiple installed versions, or the latest upgrade result.
- Sort by name, installed size, or update date.
- Inspect summaries, homepage links, installation dates, identifiers, and installed versions.

### Discover and install packages

- Search the public Homebrew formula registry together with formulae and casks from installed taps.
- Inspect package metadata, aliases, versions, and dependencies before installation.
- Install formulae and casks with type-qualified Homebrew commands.
- Preserve fully qualified names for third-party tap packages to avoid selecting an identically named package from another source.
- Add, refresh, and remove Homebrew taps without leaving the app.

### Maintain Homebrew

- Upgrade, reinstall, force reinstall, or delete a selected package.
- Make an installed version active, upgrade it, or remove it.
- Run `brew update` followed by `brew upgrade --no-ask` for every outdated, unpinned package.
- Optionally run `brew cleanup` after a successful bulk upgrade; cleanup is enabled by default.
- Review per-package success and failure badges and filter the package list by the latest result.
- Follow ordered command progress, warnings, and errors in a color-coded console through the final output line.

### Customize and export

- Choose the system appearance, light or dark mode, or one of several color themes.
- Enable or disable the Homebrew provider while keeping cached package data.
- Export the current package inventory as formatted JSON.
- Keep tap trust checks enabled by default, with an explicit advanced override in Settings.

## Requirements

- macOS 26.5 or later
- A working [Homebrew](https://brew.sh/) installation
- Xcode 27 beta 3 or later to build from source

Homebrew must be available to the user's login shell. HomebrewApp launches commands through `/bin/zsh -lc`, allowing the usual `.zprofile` Homebrew setup to load.

## Build from source

1. Clone this repository.
2. Open `app/HomebrewApp/HomebrewApp.xcodeproj` in Xcode 27 or later.
3. Select the **HomebrewApp** scheme and run it on **My Mac**.

To build from the command line:

```sh
xcodebuild build \
  -project app/HomebrewApp/HomebrewApp.xcodeproj \
  -scheme HomebrewApp \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

## Security

Some cask operations need administrator access. HomebrewApp creates a temporary user-only `SUDO_ASKPASS` helper that displays a native hidden-password dialog. The password is passed directly to `sudo`, is never stored in app state or logs, and the helper is removed when the command exits.

The **Disable tap trust checks** setting is off by default. Prefer fully qualified package names and enable the broader override only when you understand and trust the affected third-party taps.

## Documentation

Read the complete user guide at [hap.rewheels.xyz](https://hap.rewheels.xyz/), including package browsing, discovery, tap management, maintenance workflows, settings, and export.
