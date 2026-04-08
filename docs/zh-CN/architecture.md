# 架构说明（中文）

WooFramework 采用“模块注册 + 运行时服务容器 + 命令/查询分离”的结构，目标是让功能以模块为单位扩展，同时保持运行时稳定可观测。

## 1. 分层结构

```text
Bootstrap 层
  WooBootstrap
    -> 创建/获取 WooApp
    -> 启动模块
    -> 挂载启动场景

Runtime 层（WooApp）
  modules: ModuleRegistry
  models: ModelStore
  events: EventBus
  commands: CommandBus
  queries: QueryService
  systems: SystemRegistry
  runtime_state: Dictionary

Module 层
  ModuleDefinition + ModuleRegistrar + ModuleContext

Presentation 层
  View / Presenter / Controller（可用 Base 类）
```

## 2. 启动流程

`WooBootstrap._ready()` 的标准流程：

1. `_ensure_app()`：场景里没有 `WooApp` 就创建。
2. `app.boot(self)`：初始化 runtime registries。
3. `app.modules.boot_from_roots(module_root_paths)`：扫描并启动模块。
4. `_mount_startup_scene()`：实例化 `startup_scene_path` 并挂到 `WooApp.root_scene`。
5. `_mount_debug_panel()`：按配置挂载调试面板。

## 3. 模块生命周期

`ModuleRegistry.boot_from_module_scripts()` 内部按以下阶段执行：

1. `discover`：发现模块脚本路径（`<root>/<module>/module.gd`）。
2. `instantiate`：实例化 `ModuleDefinition`。
3. `sort`：按 `get_dependencies()` 做拓扑排序。
4. `register`：调用 `module.register(registrar)` 注册模型/命令/查询/系统/元数据。
5. `initialize`：调用 `module.initialize(context)`。
6. `ready`：调用 `module.ready(context)`。

关闭时按逆序执行 `module.shutdown(context)`。

## 4. 运行时数据流

### 命令流（有副作用）

`View/Controller -> CommandBus.execute() -> Command.execute(context, payload) -> Model/State/Event`

常见副作用：
- 修改 `ModelStore` 中的模型实例
- 写入 `WooApp.runtime_state`
- 发出事件 `EventBus.emit_event()`

### 查询流（只读）

`View/Controller -> QueryService.query() -> Query.execute(context, payload) -> 返回状态快照`

### 事件流（解耦通知）

`emit_event(event_id, args)` 触发：
- 订阅回调（`on/once`）
- `event_emitted` 信号（用于日志或调试面板）

## 5. 系统扩展点

通过 `SystemRegistry` 可注册惰性构建系统对象。系统首次 `get_system()` 时实例化，并自动注入 app（优先 `set_app(app)`，其次 `app` 属性）。

内置常用系统：
- `SceneSystem`：场景切换与钩子机制
- `SaveSystem`：模型持久化到 `user://saves`
- `ConfigSystem`：配置资源注册与懒加载
- `LogSystem`：事件/命令日志聚合

## 6. 容错和可观测

- 各服务在参数不合法时会 `push_error` 并发射失败信号。
- `ModuleRegistry` 维护 `boot_error`，并同步到 `WooApp.runtime_state`。
- 调试面板（`WooDebugPanel`）可实时展示模块状态、模型快照、最近命令和事件。

## 7. 设计建议

- 命令负责变更，查询负责读，避免把业务读写混在一个处理器中。
- 模块间依赖只声明模块 ID，不直接耦合脚本路径。
- 对外暴露稳定的 ID（`StringName`）而不是节点路径。
- 关键跨模块协作优先使用 `EventBus`，降低硬依赖。
