# 逻辑测试系统

本文档描述 WooFramework 在本项目中的运行时逻辑测试方案。目标不是替代现有 `addons/woo_framework/tests` 下的脚本级单元测试，而是在此基础上补齐一套面向游戏逻辑联调的命令驱动测试台。

## 目标

- 直接复用 `WooApp / CommandBus / QueryService / SystemRegistry`，避免重复造一套测试运行时。
- 用声明式步骤描述逻辑用例，让策划链路可以被稳定复现。
- 同时支持两种使用方式：
  - 资源化用例批量回归。
  - 在运行时窗口中手动输入命令或查询，做定向逻辑验证。
- 测试对象聚焦“模块联动后的游戏行为”，例如回合推进、入侵结算、管理员加成、生存/无尽模式差异等。

## 目录结构

```text
res://addons/woo_framework/testing/
  logic_test_case.gd
  logic_test_registry.gd
  logic_test_runner.gd
  ui/
    woo_logic_test_console.gd

res://game/tests/logic/
  *.tres

res://game/scenes/logic_test_console.tscn
```

## 架构分层

### 1. 用例资源层

`WooLogicTestCase` 负责描述一个完整测试用例，核心字段如下：

- `case_id`
- `suite_id`
- `title`
- `description`
- `tags`
- `module_root_paths`
- `reset_runtime_before_run`
- `steps`

每个 `steps` 项是一个 `Dictionary`，当前支持的步骤类型：

- `command`
- `query`
- `assert`
- `capture`
- `wait_frames`
- `log`

### 2. 用例发现层

`WooLogicTestRegistry` 负责递归扫描目录中的 `.tres/.res` 资源，加载为 `WooLogicTestCase`，并按 `suite_id + case_id` 排序。

### 3. 执行层

`WooLogicTestRunner` 负责单条用例执行。它会：

1. 接收一个已经 boot 完成的 `WooApp`。
2. 按顺序执行步骤。
3. 在步骤中调用 `app.commands.execute(...)` 或 `app.queries.query(...)`。
4. 记录每一步结果、断言结果、日志和最终报告。

当前断言能力覆盖常用逻辑校验：

- `equals`
- `not_equals`
- `greater_than`
- `greater_or_equal`
- `size_equals`
- `size_greater_or_equal`
- `contains`
- `not_contains`
- `exists`

### 4. 运行时窗口层

`WooLogicTestConsole` 是一个 `CanvasLayer` 测试台，提供：

- 左侧用例列表和步骤预览。
- 右侧运行日志。
- `Reload Cases / Reset Runtime / Run Selected / Run All / Stop / Copy Log` 操作。
- 手动命令/查询执行区，可输入命令 ID 和 JSON payload，直接观察结果。

入口场景：

- `res://game/scenes/logic_test_console.tscn`

## 步骤 DSL

### command

```gdscript
{
  "type": "command",
  "id": "game.start_run",
  "payload": {
    "mode_id": "campaign",
    "difficulty_id": "campaign_standard"
  },
  "store_as": "start_run",
  "asserts": [
    {"path": "ok", "equals": true},
    {"path": "snapshot.turn_index", "equals": 1}
  ]
}
```

### query

```gdscript
{
  "type": "query",
  "id": "game.get_active_invasions",
  "store_as": "active_invasions",
  "asserts": [
    {"path": "invasions", "size_greater_or_equal": 1}
  ]
}
```

### 变量引用

在 payload 或断言中可用 `$ref` 引用前面保存的结果：

```gdscript
{
  "target_structure_id": {
    "$ref": "vars.board_state.structures.0.runtime_id"
  }
}
```

支持的常用引用根：

- `vars.<name>...`
- `last_result...`
- `app_state...`
- `model:<model_id>|<path>`
- `case...`

## 执行模型

### 单用例

适合精确复现某条策划链路。窗口会根据 `reset_runtime_before_run` 决定是否先重建一个全新的 `WooApp`。

### 全量回归

窗口按当前发现顺序依次执行全部用例，并汇总通过/失败数量。适合在修完逻辑后做一次快速回归。

## 当前接入方式

项目中的逻辑测试台默认：

- 模块根目录：`res://game/modules`
- 用例目录：`res://game/tests/logic`

因此窗口会直接启动游戏模块，然后运行资源化逻辑用例。

## 与原有测试体系的关系

- `addons/woo_framework/tests`
  - 仍然承担框架级单元测试、基础集成测试。
- `addons/woo_framework/testing`
  - 补齐运行时逻辑联调、策划案回归和命令驱动测试台。

两者是互补关系，不应互相替代。

## 推荐使用流程

1. 运行 `res://game/scenes/logic_test_console.tscn`。
2. 先点 `Run Selected` 验证正在修改的链路。
3. 修改完成后点 `Run All` 做逻辑回归。
4. 如果某条链路需要临时探查，用右侧手动命令区直接执行命令或查询。

## 后续可扩展项

- 增加 `save/load`、`random_event`、`protocol_adjust` 的更完整自动化回归集。
- 增加条件断言、动态键路径、快照对比等高级断言能力。
- 增加 headless 入口，把资源化逻辑用例接入批处理或 CI。
