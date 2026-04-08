# Module API (English)

This document covers module definition, registration, context, and lifecycle APIs.

## 1. `ModuleDefinition`

File: `core/module/module_definition.gd`

Every module must extend `ModuleDefinition` and at least override `get_module_id()`.

Base methods:
- `get_module_id() -> StringName` (must override)
- `get_module_name() -> String`
- `get_module_version() -> String`
- `get_description() -> String`
- `get_dependencies() -> PackedStringArray`
- `is_enabled_by_default() -> bool`
- `register(_registrar) -> void`
- `initialize(_context) -> void`
- `ready(_context) -> void`
- `shutdown(_context) -> void`

Lifecycle meaning:
- `register`: declare models/commands/queries/systems/metadata.
- `initialize`: setup after runtime services are available.
- `ready`: module is fully interactive.
- `shutdown`: reverse-order cleanup.

## 2. `ModuleRegistrar`

File: `core/module/module_registrar.gd`

Provided by `ModuleRegistry` during `register` phase.

Methods:
- `register_model(id: StringName, script_ref: Variant, default_resource: Variant = null) -> bool`
- `register_command(id: StringName, script_ref: Variant) -> bool`
- `register_query(id: StringName, script_ref: Variant) -> bool`
- `register_system(id: StringName, script_ref: Variant) -> bool`
- `register_metadata(key: StringName, value: Variant) -> bool`

## 3. `ModuleContext`

File: `core/module/module_context.gd`

Passed into `initialize/ready/shutdown`.

Properties:
- `app`
- `registry`
- `module: ModuleDefinition`
- `module_id: StringName`
- `phase: String`

Methods:
- `set_phase(value: String) -> void`
- `set_state(key: StringName, value: Variant) -> void`
- `get_state(key: StringName, default_value: Variant = null) -> Variant`
- `get_registered_entries() -> Dictionary`
- `get_dependency_ids() -> PackedStringArray`

## 4. `ModuleRegistry`

File: `core/module/module_registry.gd`

Module discovery, dependency sorting, and lifecycle orchestrator.

Signals:
- `discovery_completed(module_paths)`
- `module_discovered(module_id: StringName, script_path: String)`
- `modules_sorted(sorted_module_ids)`
- `module_registered(module_id: StringName)`
- `module_initialized(module_id: StringName)`
- `module_readied(module_id: StringName)`
- `module_shutdown(module_id: StringName)`
- `boot_completed(sorted_module_ids)`
- `boot_failed(reason: String)`

Core methods:
- `discover_module_paths(root_paths: PackedStringArray) -> PackedStringArray`
- `boot_from_roots(root_paths: PackedStringArray) -> bool`
- `boot_from_module_scripts(module_paths: PackedStringArray) -> bool`
- `shutdown_modules() -> void`
- `get_module(module_id: StringName) -> ModuleDefinition`
- `get_module_ids() -> Array`
- `get_registrations_for_module(module_id: StringName) -> Dictionary`
- `get_boot_error() -> String`

Definition registration methods (used by registrar):
- `register_model_definition(...) -> bool`
- `register_command_definition(...) -> bool`
- `register_query_definition(...) -> bool`
- `register_system_definition(...) -> bool`
- `register_module_metadata(...) -> bool`

Key behavior:
- dependency cycles fail boot.
- missing dependencies fail boot.
- successful boot syncs module status into `WooApp.runtime_state`.

## 5. Module directory convention

Discovery behavior:
- For each path in `module_root_paths`, registry scans first-level child folders for `module.gd`.
- Example: `res://game/modules/<module_name>/module.gd`

Recommended layout:

```text
<module_root>/<module_name>/
  module.gd
  models/
  commands/
  queries/
  systems/
  scenes/
  views/
```

## 6. Minimal module skeleton

```gdscript
extends ModuleDefinition
class_name DemoModule

const MODULE_ID := &"demo"

func get_module_id() -> StringName:
	return MODULE_ID

func get_dependencies() -> PackedStringArray:
	return PackedStringArray([&"base_module"])

func register(registrar) -> void:
	registrar.register_model(&"demo_model", preload("res://.../models/demo_model.gd"))
	registrar.register_command(&"demo_command", preload("res://.../commands/demo_command.gd"))
	registrar.register_query(&"demo_query", preload("res://.../queries/demo_query.gd"))

func initialize(context) -> void:
	context.set_state(&"demo_initialized", true)
```
