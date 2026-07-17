# Discovering Formulae and Managing Taps

Search the public Homebrew catalog together with formulae from taps installed on your Mac.

## Overview

Open the **Formulae** tab to browse the public Homebrew registry. Search matches formula names, fully qualified names, aliases, descriptions, and tap names. Select a result to inspect its available metadata and install it through the same authenticated Homebrew workflow used by the installed-package browser.

HomebrewApp also loads `brew tap-info --installed --json`. The formula names reported by every installed tap are merged into the searchable catalog, so a formula such as `darrylmorley/whatcable/whatcable` appears when searching for either `whatcable` or `darrylmorley/whatcable`.

Tapped formulae are installed with their fully qualified names. This preserves the selected tap when another tap or Homebrew core publishes a formula with the same short name.

## Manage Formula Taps

Choose **Manage Taps** in the Formulae toolbar to open the tap manager. From there you can:

- Add a tap by entering its canonical `user/repository` name, such as `darrylmorley/whatcable`.
- Refresh the list of installed taps and their formula counts.
- Remove a tap after confirming the destructive action.
- Review command progress and Homebrew errors without leaving the sheet.

Adding a tap runs `brew tap user/repository`; removing one runs `brew untap user/repository`. After either command succeeds, `PackageLibrary` reloads installed taps and `FormulaRegistryStore` immediately rebuilds search results.

Tap commands inherit the **Disable tap trust checks** preference from Settings. Keep that override disabled unless you understand and trust the third-party formulae you are adding.

## Related Types

- ``FormulaRegistryView``
- ``FormulaRegistryStore``
- ``TapManagementView``
- ``HomebrewTap``
- ``PackageLibrary``
- ``HomebrewServicing``
