# Logic Testing System

WooFramework now includes a runtime logic testing layer for this project.

## Purpose

- Drive gameplay tests through `CommandBus` and `QueryService`.
- Run resource-based logic cases from a runtime window.
- Provide a manual command/query console for focused gameplay verification.

## Entry Points

- Runtime console scene: `res://game/scenes/logic_test_console.tscn`
- Case directory: `res://game/tests/logic`
- Runtime scripts: `res://addons/woo_framework/testing`

## Current Scope

- Resource-based logic cases (`WooLogicTestCase`)
- Recursive case discovery (`WooLogicTestRegistry`)
- Step runner with assertions (`WooLogicTestRunner`)
- Interactive runtime console (`WooLogicTestConsole`)

For the detailed design used in this project, see the Chinese document:

- `res://addons/woo_framework/docs/zh-CN/testing-system.md`
