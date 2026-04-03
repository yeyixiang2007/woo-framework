# WooFramework Addon

WooFramework runtime, editor builders, examples, and tests live in this addon folder.

## Plugin Entry

- `plugin.cfg`: Godot plugin metadata
- `plugin.gd`: EditorPlugin script
- `plugin_icon.svg`: plugin icon

Enable from `Project Settings -> Plugins -> WooFramework`.
When enabled, the plugin ensures `Woo` and `WooEventBus` autoloads are available.

## Layout

- `core/`: runtime framework code
- `editor/`: editor-only builders and templates
- `examples/`: sample modules and scenes
- `tests/`: framework-level automated tests
- `docs/`: full documentation (Chinese + English)

## Documentation

- Docs entry: [docs/README.md](docs/README.md)
- Chinese index: [docs/zh-CN/README.md](docs/zh-CN/README.md)
- English index: [docs/en/README.md](docs/en/README.md)
