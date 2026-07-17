# Discovering Formulae, Casks, and Managing Taps

Search the public Homebrew formula catalog together with formulae and casks from taps installed on your Mac.

## Overview

Open the **Discover** tab to browse the public Homebrew formula registry and packages contributed by installed taps. Search matches package names, fully qualified names, aliases, descriptions, and tap names. Formulae use a package icon, while casks use an application-window icon. Select a result to inspect its available metadata and install it through the same authenticated Homebrew workflow used by the installed-package browser.

HomebrewApp also loads `brew tap-info --installed --json`. The `formula_names` and `cask_tokens` reported by every installed tap are merged into the searchable catalog. Package identity includes both the fully qualified name and its type, so a formula and cask with the same token remain distinct.

Tapped packages are installed with their fully qualified names. Formula actions run `brew install --formula user/repository/formula`, while cask actions run `brew install --cask user/repository/cask`. This preserves the selected tap when another source publishes a package with the same short name and lets Homebrew trust only the explicitly selected item.

For example, to install the WhatCable app entirely through HomebrewApp:

1. Open **Discover**, choose **Manage Taps**, and add `darrylmorley/whatcable`.
2. Search for `whatcable` and select the result marked as a cask.
3. Choose **Install**. HomebrewApp runs `brew install --cask darrylmorley/whatcable/whatcable`, handles any administrator prompt, and refreshes the installed package list afterward.

## Manage Homebrew Taps

Choose **Manage Taps** in the Discover toolbar to open the tap manager. From there you can:

- Add a tap by entering its canonical `user/repository` name, such as `darrylmorley/whatcable`.
- Refresh the list of installed taps and their formula and cask counts.
- Remove a tap after confirming the destructive action.
- Review command progress and Homebrew errors without leaving the sheet.

Adding a tap runs `brew tap user/repository`; removing one runs `brew untap user/repository`. After either command succeeds, `PackageLibrary` reloads installed taps and `FormulaRegistryStore` immediately rebuilds package search results.

Tap commands inherit the **Disable tap trust checks** preference from Settings. Keep that override disabled unless you understand and trust all third-party packages being loaded. A fully qualified install can trust the selected formula or cask without enabling the broader override.

## Related Types

- ``FormulaRegistryView``
- ``FormulaRegistryStore``
- ``TapManagementView``
- ``HomebrewTap``
- ``PackageLibrary``
- ``HomebrewServicing``
