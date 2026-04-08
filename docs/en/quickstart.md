# QuickStart (English)

This guide gets WooFramework running quickly and shows how to register a minimal module.

## 1. Enable the plugin

In Godot Editor:

1. Open `Project Settings -> Plugins`.
2. Enable `WooFramework`.
3. The plugin ensures the `WooEventBus` autoload automatically, and `Woo` is available as a global script class.

## 2. Create a bootstrap scene

Create a main scene (root node can be `Node`) and attach:

- `res://addons/woo_framework/core/app/woo_bootstrap.gd`

Important exported fields:
- `startup_scene_path`: root gameplay/UI scene mounted after boot.
- `auto_boot_modules`: whether to scan and boot modules automatically.
- `module_root_paths`: module root directories (scans `module.gd` in each first-level child folder).
- `enable_debug_panel`: whether to mount F3 debug panel.

Manual fallback:
- If you do not use the plugin manager, add `WooEventBus` under `project.godot` autoload.
- `Woo` does not need an autoload entry.

## 3. Create module directory layout

Recommended structure:

```text
res://game/modules/my_feature/
  module.gd
  models/
    my_model.gd
    default_my_model.tres
  commands/
    do_something_command.gd
  queries/
    my_state_query.gd
```

Add the module root into `WooBootstrap.module_root_paths`, for example:
- `res://game/modules`

## 4. Write a minimal module definition

```gdscript
extends ModuleDefinition
class_name MyFeatureModule

const MODULE_ID := &"my_feature"

func get_module_id() -> StringName:
	return MODULE_ID

func register(registrar) -> void:
	registrar.register_model(
		&"my_model",
		preload("res://game/modules/my_feature/models/my_model.gd"),
		preload("res://game/modules/my_feature/models/default_my_model.tres")
	)
	registrar.register_command(
		&"do_something",
		preload("res://game/modules/my_feature/commands/do_something_command.gd")
	)
	registrar.register_query(
		&"my_state",
		preload("res://game/modules/my_feature/queries/my_state_query.gd")
	)
```

## 5. Execute commands and queries from view/controller

```gdscript
var app := Woo.get_app()
app.commands.execute(&"do_something", {"value": 1})
var state = app.queries.query(&"my_state")
```

## 6. Runtime sanity checks

After running:
- Press `F3` to open debug panel (if enabled).
- `Woo.get_app()` should not be null.
- `Woo.get_app().modules.get_module_ids()` should include your module ID.
- Commands and queries should execute successfully.

## 7. Run framework tests (optional)

From project root:

```bash
godot --headless --path . --script res://addons/woo_framework/tests/run_all_tests.gd
```

Exit code is `0` when all tests pass.
