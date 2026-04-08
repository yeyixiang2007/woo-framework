# Core Runtime API（中文）

本文档覆盖 `core/` 下运行时核心类型和常用系统 API。

## 1. App 入口

## `Woo` (`core/app/woo.gd`)

全局静态入口（全局脚本类）。

方法：
- `set_app(instance: WooApp) -> void`
- `clear_app() -> void`
- `get_app() -> WooApp`

---

## `WooApp` (`core/app/woo_app.gd`)

运行时容器，聚合模块、模型、命令、查询、系统等服务。

信号：
- `bootstrapped(app: WooApp)`
- `root_scene_changed(root_scene: Node)`
- `state_changed(key: StringName, value: Variant)`
- `shutting_down()`

静态：
- `get_instance() -> WooApp`

方法：
- `boot(owner: Node) -> void`
- `mount_root_scene(scene: Node) -> void`
- `shutdown() -> void`
- `has_started() -> bool`
- `set_state_value(key: StringName, value: Variant) -> void`
- `get_state_value(key: StringName, default_value: Variant = null) -> Variant`
- `get_runtime_snapshot() -> Dictionary`

关键属性：
- `modules: ModuleRegistry`
- `models: ModelStore`
- `events: EventBus`
- `commands: CommandBus`
- `queries: QueryService`
- `systems: SystemRegistry`
- `runtime_state: Dictionary`

---

## `WooBootstrap` (`core/app/woo_bootstrap.gd`)

用于主场景启动运行时。

信号：
- `startup_scene_loaded(scene: Node)`
- `modules_booted(module_ids)`

导出属性：
- `startup_scene_path: String`
- `auto_boot_modules: bool`
- `module_root_paths: PackedStringArray`
- `enable_debug_panel: bool`
- `debug_panel_script_path: String`

流程：
- `_ready()` 中自动 `boot -> (可选)boot modules -> mount startup scene -> mount debug panel`

## 2. 总线与注册表

## `EventBus` (`core/bus/event_bus.gd`)

基于事件 ID 的订阅与发布。

信号：
- `event_declared(event_id: StringName)`
- `listener_added(event_id: StringName)`
- `listener_removed(event_id: StringName)`
- `event_emitted(event_id: StringName, payload)`

方法：
- `declare_event(event_id: StringName) -> void`
- `has_event(event_id: StringName) -> bool`
- `on(event_id: StringName, listener: Callable) -> void`
- `once(event_id: StringName, listener: Callable) -> void`
- `off(event_id: StringName, listener: Callable) -> void`
- `emit_event(event_id: StringName, args: Array = []) -> void`
- `clear() -> void`

说明：
- `emit_event` 的第二参数是参数数组 `args`，监听函数按 `callv(args)` 调用。

---

## `CommandBus` (`core/command/command_bus.gd`)

命令处理分发（偏副作用）。

信号：
- `command_registered(command_id: StringName)`
- `command_executed(command_id: StringName, payload, result)`
- `command_failed(command_id: StringName, payload, reason: String)`

方法：
- `register_definition(id: StringName, handler_ref: Variant, owner_module_id: StringName = &"") -> bool`
- `execute(command_id: StringName, payload = null, context_override: CommandContext = null)`
- `has_command(id: StringName) -> bool`
- `clear() -> void`

处理器类型：
- `Callable(context, payload)`
- `Script`：实例需有 `execute(context, payload)`
- `Object`：对象需有 `execute(context, payload)`

---

## `QueryService` (`core/query/query_service.gd`)

查询分发（偏只读）。

信号：
- `query_registered(query_id: StringName)`
- `query_executed(query_id: StringName, payload, result)`
- `query_failed(query_id: StringName, payload, reason: String)`

方法：
- `register_definition(id: StringName, handler_ref: Variant, owner_module_id: StringName = &"") -> bool`
- `query(query_id: StringName, payload = null, context_override: QueryContext = null)`
- `has_query(id: StringName) -> bool`
- `clear() -> void`

---

## `ModelStore` (`core/model/model_store.gd`)

模型定义和实例管理（模型类型需为 `Resource`）。

信号：
- `model_registered(id: StringName)`
- `model_built(id: StringName, instance: Resource)`
- `model_replaced(id: StringName, instance: Resource)`

方法：
- `register_definition(id: StringName, script_ref: Variant, default_resource: Variant = null, owner_module_id: StringName = &"") -> bool`
- `has_model(id: StringName) -> bool`
- `get_model_ids() -> Array`
- `get_model(id: StringName) -> Resource`
- `set_model(id: StringName, instance: Resource) -> bool`
- `get_definition(id: StringName) -> Dictionary`
- `clear() -> void`

行为要点：
- 首次 `get_model()` 时按 definition 惰性构建实例。
- 若配置了默认资源，构建时会 `duplicate(true)`。

---

## `SystemRegistry` (`core/system/system_registry.gd`)

系统定义与实例管理（惰性实例化）。

信号：
- `system_registered(system_id: StringName)`
- `system_built(system_id: StringName, instance: Object)`
- `system_replaced(system_id: StringName, instance: Object)`

方法：
- `register_definition(id: StringName, script_ref: Variant, owner_module_id: StringName = &"") -> bool`
- `has_system(id: StringName) -> bool`
- `get_system(id: StringName) -> Object`
- `set_system(id: StringName, instance: Object) -> bool`
- `clear() -> void`

注入规则：
- 若实例有 `set_app()`，优先调用。
- 否则如果有 `app` 属性，会自动赋值。

## 3. Context 对象

## `CommandContext` (`core/command/command_context.gd`)

命令执行上下文。

属性：
- `app`
- `models: ModelStore`
- `events: EventBus`
- `queries: QueryService`
- `command_id: StringName`
- `payload`
- `metadata: Dictionary`

方法：
- `get_model(id: StringName) -> Resource`
- `set_state(key: StringName, value: Variant) -> void`
- `get_state(key: StringName, default_value: Variant = null) -> Variant`
- `emit_event(event_id: StringName, args: Array = []) -> void`

---

## `QueryContext` (`core/query/query_context.gd`)

查询执行上下文。

属性：
- `app`
- `models: ModelStore`
- `query_id: StringName`
- `payload`

方法：
- `get_model(id: StringName) -> Resource`
- `get_state(key: StringName, default_value: Variant = null) -> Variant`

## 4. Presentation Base

## `ControllerBase` (`core/presentation/controller_base.gd`)

方法：
- `on_app_ready(_app: WooApp) -> void`
- `bind() -> void`
- `unbind() -> void`
- `execute_command(command_id: StringName, payload = null)`
- `query_state(query_id: StringName, payload = null)`
- `emit_event(event_id: StringName, args: Array = []) -> void`

---

## `PresenterBase` (`core/presentation/presenter_base.gd`)

方法：
- `set_view(view_node: Node) -> void`
- `on_app_ready(_app: WooApp) -> void`
- `on_view_ready(_view: Node) -> void`
- `bind() -> void`
- `unbind() -> void`

---

## `ViewBase` (`core/presentation/view_base.gd`)

方法：
- `set_presenter(presenter_instance: Node) -> void`
- `on_view_ready() -> void`

## 5. 内置系统

## `TaskSystem` (`core/system/task_system.gd`)

信号：
- `task_created(task: WooTask)`
- `task_finished(task: WooTask)`

方法：
- `set_app(owner_app) -> void`
- `create_source() -> WooTaskCompletionSource`
- `completed(result = null) -> WooTask`
- `failed(error = null) -> WooTask`
- `canceled(reason := "") -> WooTask`
- `create_cancellation_source() -> WooCancellationSource`
- `as_task(value) -> WooTask`
- `delay(seconds: float, cancel_token: WooCancellationToken = null, process_in_physics := false, process_always := true, ignore_time_scale := false) -> WooTask`
- `next_frame(cancel_token: WooCancellationToken = null) -> WooTask`
- `next_physics_frame(cancel_token: WooCancellationToken = null) -> WooTask`
- `from_signal(signal_ref, cancel_token: WooCancellationToken = null, capture_first_arg := false) -> WooTask`
- `wait_until(predicate: Callable, cancel_token: WooCancellationToken = null, use_physics_frame := false, timeout_seconds := -1.0) -> WooTask`
- `when_all(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask`
- `when_any(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask`
- `race(tasks: Array, cancel_token: WooCancellationToken = null) -> WooTask`
- `join(task_value)`

辅助类型：
- `WooTask`
- `WooTaskCompletionSource`
- `WooCancellationSource`
- `WooCancellationToken`

使用要点：
- 推荐 `await task.finished` 后检查 `task.is_succeeded()` / `task.is_failed()` / `task.is_canceled()`。
- `join()` 返回成功结果；失败或取消时会 `push_error` 并返回 `null`。

---

## `TweenSystem` (`core/system/tween_system.gd`)

信号：
- `playback_started(playback: WooTweenPlayback)`
- `playback_finished(playback: WooTweenPlayback)`

方法：
- `set_app(owner_app) -> void`
- `sequence() -> WooTweenSequence`
- `to(target: Object, property_path, target_value, duration: float) -> WooTweenStep`
- `value(target_callable: Callable, from_value, to_value, duration: float) -> WooTweenStep`
- `callback(target_callable: Callable) -> WooTweenStep`
- `interval(duration: float) -> WooTweenStep`
- `play(sequence_or_step) -> WooTweenPlayback`
- `get_task_system() -> TaskSystem`
- `get_active_playbacks() -> Array`
- `kill_all() -> void`

辅助类型：
- `WooTweenStep`
- `WooTweenSequence`
- `WooTweenPlayback`

链式能力：
- `WooTweenStep` 支持 `set_delay()` / `set_trans()` / `set_ease()` / `from_step()` / `from_current()` / `as_relative()`
- `WooTweenSequence` 支持 `append()` / `join()` / `insert()` / `append_interval()` / `append_callback()` / `append_sequence()`
- `WooTweenSequence` 支持 `bind_node()` / `set_default_trans()` / `set_default_ease()` / `set_loops()` / `set_infinite_loops()`

使用要点：
- `WooTweenPlayback.task` 是 `WooTask`，可与 `TaskSystem` 组合。
- 推荐 `await playback.finished`，或通过 `await task_system.join(playback.task)` 获取成功结果。

---

## `SceneSystem` (`core/system/scene_system.gd`)

信号：
- `transition_started(scene_path: String, payload)`
- `transition_finished(scene_path: String, scene: Node, payload)`
- `scene_preloaded(scene_path: String)`
- `scene_cache_cleared()`

方法：
- `preload_scene(scene_path: String, cache := true) -> PackedScene`
- `has_cached_scene(scene_path: String) -> bool`
- `get_cached_scene(scene_path: String) -> PackedScene`
- `clear_cache() -> void`
- `add_before_change_hook(hook: Callable) -> void`
- `remove_before_change_hook(hook: Callable) -> void`
- `add_after_change_hook(hook: Callable) -> void`
- `remove_after_change_hook(hook: Callable) -> void`
- `change_scene(scene_path: String, payload = null, options: Dictionary = {}) -> Node`
- `change_scene_packed(scene: PackedScene, scene_path: String = "", payload = null, options: Dictionary = {}) -> Node`

---

## `SaveSystem` (`core/system/save_system.gd`)

信号：
- `slot_saved(slot_id: StringName, metadata: Dictionary)`
- `slot_loaded(slot_id: StringName, metadata: Dictionary)`
- `slot_deleted(slot_id: StringName)`
- `save_failed(slot_id: StringName, reason: String)`
- `load_failed(slot_id: StringName, reason: String)`

方法：
- `set_app(owner_app) -> void`
- `list_slots() -> PackedStringArray`
- `slot_exists(slot_id: StringName) -> bool`
- `save_slot(slot_id: StringName, options: Dictionary = {}) -> bool`
- `load_slot(slot_id: StringName, options: Dictionary = {}) -> bool`
- `delete_slot(slot_id: StringName) -> bool`
- `get_slot_metadata(slot_id: StringName) -> Dictionary`

默认路径：
- `save_root = "user://saves"`

---

## `ConfigSystem` (`core/system/config_system.gd`)

信号：
- `config_registered(config_id: StringName)`
- `config_loaded(config_id: StringName, resource: Resource)`
- `config_cleared(config_id: StringName)`

方法：
- `set_app(owner_app) -> void`
- `register_config(config_id: StringName, config_ref: Variant) -> bool`
- `preload_config(config_id: StringName, config_path: String) -> Resource`
- `get_config(config_id: StringName) -> Resource`
- `has_config(config_id: StringName) -> bool`
- `clear_config(config_id: StringName) -> void`
- `clear_all() -> void`

---

## `LogSystem` (`core/system/log_system.gd`)

信号：
- `log_added(entry: Dictionary)`
- `log_cleared()`

方法：
- `set_app(owner_app) -> void`
- `bind() -> void`
- `unbind() -> void`
- `log_info(message: String, payload = null) -> void`
- `log_error(message: String, payload = null) -> void`
- `clear() -> void`
- `get_entries() -> Array`

## 6. 调试面板

## `WooDebugPanel` (`core/debug/woo_debug_panel.gd`)

类型：
- `CanvasLayer`

特点：
- `F3` 显示/隐藏
- 展示模块状态、模型快照、近期命令和事件
- 可通过 `attach_app(owner_app)` 注入运行时 app
