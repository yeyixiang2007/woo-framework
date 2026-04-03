# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

### Added
- Added `docs/vibe-coding-guide.md` to standardize AI collaboration templates and review checklists.
- Added `docs/tutorial-build-module.md` as an end-to-end module setup tutorial.
- Added `docs/release-process.md` to define versioning policy and release-note workflow.
- Added standard Godot plugin entry files under `addons/woo_framework/`: `plugin.cfg`, `plugin.gd`, and `plugin_icon.svg`.

### Changed
- Updated document references from `docs/vibe-coding-prompt.md` to `docs/vibe-coding-guide.md`.
- Updated root and addon documentation to a plugin-first installation flow and fixed non-portable absolute links.

## [0.1.0] - 2026-04-01

### Added
- Bootstrapped WooFramework runtime core: `WooApp`, `WooBootstrap`, `ModuleRegistry`, `ModelStore`, `EventBus`, `CommandBus`, `QueryService`, and `SystemRegistry`.
- Added built-in systems for scene, save, log, and config workflows.
- Added official example modules: `counter` and `inventory`.
- Added module and presentation templates under `addons/woo_framework/editor/templates`.
- Added test baseline with unit and integration runner under `addons/woo_framework/tests`.
- Added architecture, protocol, naming, API, and planning docs under `docs/`.
