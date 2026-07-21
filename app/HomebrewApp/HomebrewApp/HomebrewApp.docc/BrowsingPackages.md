# Browsing Packages

Find installed Homebrew formulae and casks quickly.

## Overview

The package browser opens as a two-column SwiftUI split view. The sidebar lists installed packages, while the detail column keeps the selected package visible for inspection and actions.

![Package browser with Upgrade All, cached Homebrew packages, selected package details, and console status.](package-browser.png)

`PackageListView` shows cached packages immediately when SwiftData has a previous refresh available. If the cache is empty and the Homebrew provider is enabled, `PackageLibrary` starts a live refresh with `brew info --json=v2 --installed`.

The main window opens at a comfortable ideal size, supports a smaller tested minimum size, and remains freely resizable above that minimum. Long command-progress messages truncate in the console dock instead of increasing the window's minimum width.

![Filter menu showing package type and multiple-version choices.](package-filter.png)

The browser supports:

- Search across package names and summaries.
- A visible Filters menu with an active-filter count and one-click reset.
- Filtering by formula or cask.
- A multiple-versions filter for packages that need cleanup or version review.
- Latest-upgrade filters for successfully upgraded packages and package errors.
- Selection repair when filters or refreshes change the visible package list.
- Provider-aware empty states when Homebrew is disabled.

Bulk-upgrade results remain attached to their package rows for the current app session. Successful packages show a green status, while failures show a red status and preserve Homebrew's package-specific message. If stdout and stderr arrive close together, an error that names a package is assigned to that package instead of whichever package most recently reported progress.

## Data Flow

`PackageLibrary` owns the observable list state and publishes `filteredPackages` to the view. Live refreshes flow through `HomebrewServicing`, then the resulting `InstalledPackageDTO` snapshots are persisted as `BrewPackage` and `BrewVersion` records for fast startup on the next launch.

## Related Types

- ``PackageListView``
- ``PackageLibrary``
- ``InstalledPackageDTO``
- ``ManagedPackageKind``
- ``BrewPackage``
- ``BrewVersion``
