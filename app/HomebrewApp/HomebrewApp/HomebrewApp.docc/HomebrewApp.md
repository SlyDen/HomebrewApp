# ``HomebrewApp``

Manage installed Homebrew packages from a native SwiftUI app.

@Metadata {
    @DisplayName("HomebrewApp")
}

## Overview

HomebrewApp is a macOS package browser for Homebrew installations. It loads cached package data from SwiftData for quick startup, refreshes live package information through the Homebrew command-line tool, and exposes package maintenance actions from a split-view interface.

![HomebrewApp package browser showing Upgrade All, installed packages, package details, and the console dock.](package-browser.png)

Use HomebrewApp to:

- Browse installed formulae and casks with searchable names, summaries, version counts, and package categories.
- Search the public formula registry together with formulae and casks from installed taps.
- Install type-qualified tapped packages, including fully qualified third-party casks.
- List, add, refresh, and remove Homebrew taps from the Discover toolbar.
- Inspect package details including homepage links, install dates, identifiers, and installed versions.
- Run package actions such as upgrade, reinstall, force reinstall, delete, make active, and version-specific delete.
- Upgrade every outdated, unpinned package at once, with optional cleanup enabled by default.
- Watch refreshes and package operations in a color-coded console panel.
- Resize the main window without transient command output changing its minimum size.
- Export the current package inventory as formatted JSON.
- Tune app appearance and active package providers from the macOS Settings window.

## Topics

### App Experience

- <doc:BrowsingPackages>
- <doc:DiscoveringFormulae>
- <doc:ManagingPackages>
- <doc:SettingsAndExport>

### Core App Types

- ``HomebrewAppApp``
- ``ContentView``
- ``PackageListView``
- ``PackageDetailView``
- ``FormulaRegistryView``
- ``TapManagementView``
- ``AppSettingsView``

### Package State

- ``PackageLibrary``
- ``FormulaRegistryStore``
- ``HomebrewTap``
- ``InstalledPackageDTO``
- ``InstalledVersionDTO``
- ``ManagedPackageKind``
- ``PackageLogEntry``
- ``PackageLogLevel``

### Services and Persistence

- ``HomebrewServicing``
- ``HomebrewServiceFactory``
- ``HomebrewCLIService``
- ``MockHomebrewService``
- ``BrewPackage``
- ``BrewVersion``
- ``PackageExportDocument``
