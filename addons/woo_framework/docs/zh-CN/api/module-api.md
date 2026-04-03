# Module API（中文）

本文档描述模块定义、注册、上下文和生命周期 API。

## 1. `ModuleDefinition`

文件：`core/module/module_definition.gd`

模块必须继承 `ModuleDefinition` 并至少重写 `get_module_id()`。

基础方法：
- `get_module_id() -> StringName`（必须重写）
- `get_module_name() -> String`
- `get_module_version() -> String`
- `get_description() -> String`
- `get_dependencies() -> PackedStringArray`
- `is_enabled_by_default() -> bool`
- `register(_registrar) -> void`
- `initialize(_context) -> void`
- `ready(_context) -> void`
- `shutdown(_context) -> void`

生命周期含义：
- `register`：声明模型/命令/查询/系统/元数据。
- `initialize`：做依赖服务可用后的初始化。
- `ready`：模块全部初始化后进入可交互状态。
- `shutdown`：反向关闭阶段，释放模块资源。

## 2. `ModuleRegistrar`

文件：`core/module/module_registrar.gd`

由 `ModuleRegistry` 在 `register` 阶段传给模块。

方法：
- `register_model(id: StringName, script_ref: Variant, default_resource: Variant = null) -> bool`
- `register_command(id: StringName, script_ref: Variant) -> bool`
- `register_query(id: StringName, script_ref: Variant) -> bool`
- `register_system(id: StringName, script_ref: Variant) -> bool`
- `register_metadata(key: StringName, value: Variant) -> bool`

说明：
- 返回 `false` 代表注册失败；可配合日志快速定位。

## 3. `ModuleContext`

文件：`core/module/module_context.gd`

在 `initialize/ready/shutdown` 阶段传入。

属性：
- `app`
- `registry`
- `module: ModuleDefinition`
- `module_id: StringName`
- `phase: String`

方法：
- `set_phase(value: String) -> void`
- `set_state(key: StringName, value: Variant) -> void`
- `get_state(key: StringName, default_value: Variant = null) -> Variant`
- `get_registered_entries() -> Dictionary`
- `get_dependency_ids() -> PackedStringArray`

## 4. `ModuleRegistry`

文件：`core/module/module_registry.gd`

模块发现、依赖排序、生命周期驱动中心。

信号：
- `discovery_completed(module_paths)`
- `module_discovered(module_id: StringName, script_path: String)`
- `modules_sorted(sorted_module_ids)`
- `module_registered(module_id: StringName)`
- `module_initialized(module_id: StringName)`
- `module_readied(module_id: StringName)`
- `module_shutdown(module_id: StringName)`
- `boot_completed(sorted_module_ids)`
- `boot_failed(reason: String)`

关键方法：
- `discover_module_paths(root_paths: PackedStringArray) -> PackedStringArray`
- `boot_from_roots(root_paths: PackedStringArray) -> bool`
- `boot_from_module_scripts(module_paths: PackedStringArray) -> bool`
- `shutdown_modules() -> void`
- `get_module(module_id: StringName) -> ModuleDefinition`
- `get_module_ids() -> Array`
- `get_registrations_for_module(module_id: StringName) -> Dictionary`
- `get_boot_error() -> String`

对注册器暴露的定义注册方法：
- `register_model_definition(...) -> bool`
- `register_command_definition(...) -> bool`
- `register_query_definition(...) -> bool`
- `register_system_definition(...) -> bool`
- `register_module_metadata(...) -> bool`

行为要点：
- 依赖环会直接 `boot_failed`。
- 缺失依赖会直接 `boot_failed`。
- 启动成功后会把模块状态同步到 `WooApp.runtime_state`。

## 5. 模块目录规范

扫描规则：
- 对 `module_root_paths` 的每个根目录，扫描一级子目录中的 `module.gd`。
- 示例：`res://game/modules/<module_name>/module.gd`

推荐结构：

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

## 6. 最小模块模板

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
