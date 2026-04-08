@tool
class_name UiPanelBuilder
extends "res://addons/woo_framework/editor/builders/base_builder.gd"

@export var title_text := "Generated Panel"
@export var body_text := "This panel was built by UiPanelBuilder."
@export var button_text := "Confirm"
@export var panel_margin := Vector2(120.0, 120.0)


func build() -> void:
	var root := ensure_node(self, "UiPanelRoot", "Control") as Control
	if root == null:
		return
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := ensure_node(root, "Panel", "PanelContainer") as PanelContainer
	if panel == null:
		return
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = panel_margin.x
	panel.offset_top = panel_margin.y
	panel.offset_right = -panel_margin.x
	panel.offset_bottom = -panel_margin.y

	var vbox := ensure_node(panel, "VBox", "VBoxContainer") as VBoxContainer
	if vbox == null:
		return
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 24.0
	vbox.offset_top = 24.0
	vbox.offset_right = -24.0
	vbox.offset_bottom = -24.0

	var title_label := ensure_node(vbox, "TitleLabel", "Label") as Label
	if title_label != null:
		title_label.text = title_text
		title_label.add_theme_font_size_override("font_size", 24)

	var body_label := ensure_node(vbox, "BodyLabel", "Label") as Label
	if body_label != null:
		body_label.text = body_text

	var button := ensure_node(vbox, "ActionButton", "Button") as Button
	if button != null:
		button.text = button_text
