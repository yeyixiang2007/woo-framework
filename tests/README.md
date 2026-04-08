# WooFramework Tests

## Scope

This folder contains the initial test baseline for P5-01 and P5-02:

1. Unit tests for runtime core (ModelStore, EventBus, CommandBus, QueryService).
2. Integration test for sample modules startup, command/query interaction, and save/load flow.

## Run All Tests (Headless)

Use Godot CLI from project root:

```bash
godot --headless --path . --script res://addons/woo_framework/tests/run_all_tests.gd
```

The script exits with status code `0` when all tests pass, or `1` when any test fails.

## Integration Test Scene

Scene path:

`res://addons/woo_framework/tests/integration/scenes/example_modules_integration_test.tscn`

To run it manually in the editor:

1. Open the scene.
2. Enable `auto_run_when_main` on root node.
3. Run current scene.
