# API 总览（中文）

本目录按职责拆分 API 参考：

- [Core Runtime API](core-runtime.md)
- [Module API](module-api.md)
- [Builder API](builder-api.md)

## 建议阅读顺序

1. `core-runtime.md`：先理解运行时容器和总线。
2. `module-api.md`：再理解模块注册与生命周期。
3. `builder-api.md`：最后了解编辑器构建器扩展。

## 约定

- 大多数 ID 使用 `StringName`（建议常量化，示例：`&"counter"`）。
- `Command`/`Query` 处理器可用三种形式注册：
  - `Callable`
  - `Script`（实例需实现 `execute(context, payload)`）
  - `Object`（对象需实现 `execute(context, payload)`）
