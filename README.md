# WooFramework

WooFramework is a modular runtime framework for Godot 4. It is designed to let projects scale by feature modules while keeping business logic decoupled, testable, and observable.

## What Is Included

- Runtime container: `WooApp`
- Module system: `ModuleRegistry` + `ModuleDefinition`
- Data/behavior separation: `ModelStore` / `CommandBus` / `QueryService` / `EventBus`
- Pluggable systems: `SystemRegistry` (built-ins: `SceneSystem`, `SaveSystem`, `ConfigSystem`, `LogSystem`)
- Runtime debugging: `WooDebugPanel` (toggle with F3)
- Editor builders: `BaseBuilder` / `UiPanelBuilder`
- Examples and tests: `addons/woo_framework/examples`, `addons/woo_framework/tests`

## Plugin Install (Standard)

1. Copy `addons/woo_framework` into your project `addons` folder.
2. Open `Project Settings -> Plugins`.
3. Enable `WooFramework`.
4. The plugin will automatically ensure the `WooEventBus` autoload exists.
`Woo` is available globally as a script class.
5. Attach `res://addons/woo_framework/core/app/woo_bootstrap.gd` to your main scene root node.

## 5-Min Runtime QuickStart

1. Configure `WooBootstrap.module_root_paths` (for example `res://game/modules`).
2. Create a module folder with `module.gd` (extends `ModuleDefinition`).
3. Register models/commands/queries in `register(registrar)`.
4. Run your project and press `F3` to inspect runtime state.

Full guides:
- [QuickStart (Chinese)](addons/woo_framework/docs/zh-CN/quickstart.md)
- [QuickStart (English)](addons/woo_framework/docs/en/quickstart.md)

## Documentation Entry

- Chinese docs entry: [addons/woo_framework/docs/zh-CN/README.md](addons/woo_framework/docs/zh-CN/README.md)
- English docs entry: [addons/woo_framework/docs/en/README.md](addons/woo_framework/docs/en/README.md)
- Docs index: [addons/woo_framework/docs/README.md](addons/woo_framework/docs/README.md)

Highlighted docs:
- [Architecture (Chinese)](addons/woo_framework/docs/zh-CN/architecture.md)
- [Architecture (English)](addons/woo_framework/docs/en/architecture.md)
- [Core Runtime API (Chinese)](addons/woo_framework/docs/zh-CN/api/core-runtime.md)
- [Core Runtime API (English)](addons/woo_framework/docs/en/api/core-runtime.md)

## Repository Layout

- `addons/woo_framework/core`: framework runtime code
- `addons/woo_framework/editor`: editor builders and templates
- `addons/woo_framework/plugin.cfg`: plugin metadata (Godot plugin entry)
- `addons/woo_framework/plugin.gd`: EditorPlugin bootstrap
- `addons/woo_framework/examples`: official sample modules and scenes
- `addons/woo_framework/tests`: unit/integration test suite
- `addons/woo_framework/docs`: bilingual documentation
- `game`: project/game content (modules, scenes, assets)

## Run Tests

Run from repository root:

```bash
godot --headless --path . --script res://addons/woo_framework/tests/run_all_tests.gd
```

Exit code `0` means all tests passed.

## Current Example Entry

- Addon sample main scene: `res://addons/woo_framework/examples/scenes/counter_main_scene.tscn`
- For the current project startup scene, check [project.godot](project.godot).
