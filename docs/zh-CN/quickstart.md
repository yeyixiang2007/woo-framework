# QuickStart（中文）

本指南会用最短路径把 WooFramework 跑起来，并注册一个最小模块。

## 1. 启用插件

在 Godot 编辑器中：

1. 打开 `Project Settings -> Plugins`。
2. 启用 `WooFramework`。
3. 插件会自动确保 `Woo`、`WooEventBus` 两个 autoload。

## 2. 创建启动场景（Bootstrap Scene）

新建一个主场景（根节点建议 `Node`），挂载脚本：

- `res://addons/woo_framework/core/app/woo_bootstrap.gd`

关键导出参数：
- `startup_scene_path`：启动后挂载的根 UI/游戏场景。
- `auto_boot_modules`：是否自动扫描并启动模块。
- `module_root_paths`：模块根目录列表（扫描每个一级子目录下的 `module.gd`）。
- `enable_debug_panel`：是否挂载 F3 调试面板。

手动兜底方式：
- 如果你不通过插件管理器启用，也可以在 `project.godot` 手动配置 `Woo` 与 `WooEventBus` autoload。

## 3. 创建模块目录

示例结构（与框架扫描规则一致）：

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

并把模块根目录加入 `WooBootstrap.module_root_paths`，例如：
- `res://game/modules`

## 4. 编写最小模块定义

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

## 5. 在视图里调用命令和查询

```gdscript
var app := Woo.get_app()
app.commands.execute(&"do_something", {"value": 1})
var state = app.queries.query(&"my_state")
```

## 6. 运行后自检

建议检查：
- 按 `F3` 是否能打开调试面板（如果启用）。
- `Woo.get_app()` 非空。
- `Woo.get_app().modules.get_module_ids()` 包含你的模块 ID。
- 命令和查询可正常执行。

## 7. 运行测试（可选）

项目根目录执行：

```bash
godot --headless --path . --script res://addons/woo_framework/tests/run_all_tests.gd
```

通过时返回码为 `0`。
