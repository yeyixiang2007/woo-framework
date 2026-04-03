# Architecture (English)

WooFramework uses a "module registration + runtime service container + command/query split" architecture to keep features extensible while runtime behavior remains predictable.

## 1. Layered structure

```text
Bootstrap layer
  WooBootstrap
    -> create/reuse WooApp
    -> boot modules
    -> mount startup scene

Runtime layer (WooApp)
  modules: ModuleRegistry
  models: ModelStore
  events: EventBus
  commands: CommandBus
  queries: QueryService
  systems: SystemRegistry
  runtime_state: Dictionary

Module layer
  ModuleDefinition + ModuleRegistrar + ModuleContext

Presentation layer
  View / Presenter / Controller (base classes available)
```

## 2. Boot flow

Standard sequence in `WooBootstrap._ready()`:

1. `_ensure_app()`: create `WooApp` if not present.
2. `app.boot(self)`: initialize runtime registries.
3. `app.modules.boot_from_roots(module_root_paths)`: discover and boot modules.
4. `_mount_startup_scene()`: instantiate and mount startup scene.
5. `_mount_debug_panel()`: optionally mount debug panel.

## 3. Module lifecycle

Inside `ModuleRegistry.boot_from_module_scripts()`:

1. `discover`: collect module script paths (`<root>/<module>/module.gd`).
2. `instantiate`: instantiate `ModuleDefinition`.
3. `sort`: topological sort by `get_dependencies()`.
4. `register`: call `module.register(registrar)`.
5. `initialize`: call `module.initialize(context)`.
6. `ready`: call `module.ready(context)`.

Shutdown runs `module.shutdown(context)` in reverse order.

## 4. Runtime data flow

### Command flow (side effects)

`View/Controller -> CommandBus.execute() -> Command.execute(context, payload) -> Model/State/Event`

Typical side effects:
- mutate models in `ModelStore`
- update `WooApp.runtime_state`
- emit events through `EventBus`

### Query flow (read-only)

`View/Controller -> QueryService.query() -> Query.execute(context, payload) -> state snapshot`

### Event flow (decoupled notification)

`emit_event(event_id, args)` triggers:
- subscribed callbacks (`on/once`)
- `event_emitted` signal (for logs/debug tools)

## 5. System extension points

`SystemRegistry` supports lazy instantiation of system objects. On first `get_system()`, the instance is created and app is auto-injected (`set_app(app)` first, then fallback to writable `app` property).

Built-in systems:
- `SceneSystem`: scene switching and hooks
- `SaveSystem`: model persistence into `user://saves`
- `ConfigSystem`: resource config registry and lazy loading
- `LogSystem`: event/command log aggregation

## 6. Observability and failure model

- Services call `push_error` and emit failure signals when validation fails.
- `ModuleRegistry` stores `boot_error` and syncs failure state into `WooApp.runtime_state`.
- `WooDebugPanel` can display module status, model snapshots, and recent command/event logs in runtime.

## 7. Design recommendations

- Keep writes in commands and reads in queries.
- Declare module dependencies by module IDs, not script paths.
- Expose stable IDs (`StringName`) for public interactions.
- Prefer `EventBus` for cross-module collaboration to reduce hard coupling.
