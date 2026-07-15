# Managing Packages

Run Homebrew maintenance tasks from the selected package detail view.

## Overview

The detail pane surfaces the selected package's metadata, installed versions, and available package operations. Actions are delegated back to `PackageLibrary`, which logs the command, calls the active package service, and refreshes package state when the command completes.

![Package detail screen with package actions, installed versions, and metadata.](package-browser.png)

Package-level actions include:

- Upgrade
- Reinstall
- Force Reinstall
- Delete

Version-level actions include:

- Make Active
- Upgrade Package
- Delete Version

Every command appends structured log entries before and after execution. The console dock remains visible at the bottom of the window, and the expanded log panel shows timestamps, severity, command details, warnings, and failures.

![Expanded log panel with state, success, and warning entries.](package-logs.png)

## Command Mapping

On macOS, `HomebrewCLIService` maps app actions to Homebrew commands. The service launches Homebrew through `/bin/zsh -lc` so common login-shell Homebrew setup is available, applies noninteractive Homebrew environment flags, drains stdout and stderr continuously, and terminates commands that exceed the timeout.

## Related Types

- ``PackageDetailView``
- ``PackageAction``
- ``PackageVersionAction``
- ``PackageLibrary``
- ``HomebrewCLIService``
- ``PackageLogEntry``
