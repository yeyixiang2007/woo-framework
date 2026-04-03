extends Node

const MODULE_ROOTS := ["res://addons/woo_framework/examples/modules"]
const STARTUP_SCENE := "res://addons/woo_framework/examples/modules/counter/scenes/counter_scene.tscn"
const TEST_SAVE_ROOT := "user://woo_framework_tests/integration_saves"
const TEST_SLOT_ID := &"example_modules_flow"

@export var auto_run_when_main := false


func _ready() -> void:
	if not auto_run_when_main:
		return
	var runner = preload("res://addons/woo_framework/tests/framework/test_runner.gd").new()
	runner.start_suite("Integration")
	runner.start_case("Example Modules Startup + Interaction + Save")
	run_case(runner)
	runner.print_summary()


func run_case(runner) -> void:
	var bootstrap := WooBootstrap.new()
	bootstrap.auto_boot_modules = true
	bootstrap.module_root_paths = PackedStringArray(MODULE_ROOTS)
	bootstrap.startup_scene_path = STARTUP_SCENE
	bootstrap._ready()

	var app := bootstrap.app
	runner.expect_not_null(app, "WooBootstrap should create WooApp.")
	if app == null:
		return

	runner.expect_true(app.has_started(), "WooApp should be started after bootstrap ready.")
	runner.expect_not_null(app.root_scene, "WooBootstrap should mount startup scene.")
	runner.expect_true(
		app.modules != null and app.modules.is_bootstrapped,
		"ModuleRegistry should finish module boot."
	)

	app.commands.execute(&"increment_counter", {"amount": 2})
	var counter_state = app.queries.query(&"counter_state")
	runner.expect_true(counter_state is Dictionary, "Counter query should return dictionary.")
	if counter_state is Dictionary:
		runner.expect_equal(int(counter_state.get("count", 0)), 2, "Counter command + query flow should work.")

	app.commands.execute(&"grant_coins", {"amount": 20})
	app.commands.execute(&"purchase_item", {"item_id": "potion", "amount": 2, "cost": 5})
	var inventory_state = app.queries.query(&"inventory_state")
	runner.expect_true(inventory_state is Dictionary, "Inventory query should return dictionary.")
	if inventory_state is Dictionary:
		runner.expect_equal(int(inventory_state.get("coins", 0)), 10, "Purchase should deduct coins.")
		var items = inventory_state.get("items", {})
		runner.expect_true(items is Dictionary, "Inventory items should be a dictionary.")
		if items is Dictionary:
			runner.expect_equal(int(items.get("potion", 0)), 2, "Purchase should add item count.")

	var save_system := SaveSystem.new(app)
	save_system.save_root = TEST_SAVE_ROOT
	save_system.delete_slot(TEST_SLOT_ID)

	var save_ok := save_system.save_slot(
		TEST_SLOT_ID,
		{
			"model_ids": PackedStringArray(["counter", "inventory", "currency"]),
		}
	)
	runner.expect_true(save_ok, "SaveSystem should persist module models to slot.")

	app.commands.execute(&"reset_counter")
	app.commands.execute(&"remove_item", {"item_id": "potion", "amount": 2})
	var currency_model = app.models.get_model(&"currency")
	if currency_model != null:
		currency_model.set("coins", 0)

	var load_ok := save_system.load_slot(TEST_SLOT_ID)
	runner.expect_true(load_ok, "SaveSystem should restore slot models.")

	var restored_counter = app.queries.query(&"counter_state")
	if restored_counter is Dictionary:
		runner.expect_equal(int(restored_counter.get("count", 0)), 2, "Counter state should restore from slot.")

	var restored_inventory = app.queries.query(&"inventory_state")
	if restored_inventory is Dictionary:
		runner.expect_equal(int(restored_inventory.get("coins", 0)), 10, "Coins should restore from slot.")
		var restored_items = restored_inventory.get("items", {})
		if restored_items is Dictionary:
			runner.expect_equal(int(restored_items.get("potion", 0)), 2, "Inventory should restore from slot.")

	runner.expect_true(save_system.delete_slot(TEST_SLOT_ID), "SaveSystem should delete test slot.")
	app.shutdown()
	bootstrap.queue_free()
