@tool
class_name BaseBuilder
extends Node

@export var build_in_editor := true
@export var build_in_game := false

var _rebuild_trigger := false
@export var rebuild_trigger: bool:
	set(value):
		_rebuild_trigger = value
		if value:
			rebuild()
			_rebuild_trigger = false
	get:
		return _rebuild_trigger


func _ready() -> void:
	if Engine.is_editor_hint():
		if build_in_editor:
			rebuild()
	else:
		if build_in_game:
			rebuild()


func rebuild() -> void:
	if not is_inside_tree():
		return
	build()
	_apply_owner_recursive(self)


func build() -> void:
	pass


func ensure_node(parent: Node, name: String, node_class: String) -> Node:
	if parent == null:
		return null

	var existing := parent.get_node_or_null(name)
	if existing != null:
		if not existing.is_class(node_class):
			push_warning(
				"BaseBuilder: node '%s' exists but is not %s." % [name, node_class]
			)
		_apply_owner_recursive(existing)
		return existing

	var created := ClassDB.instantiate(node_class)
	if created == null or not (created is Node):
		push_error("BaseBuilder: failed to create node of type %s." % node_class)
		return null

	created.name = name
	parent.add_child(created)
	_apply_owner_recursive(created)
	return created


func ensure_path(parent: Node, path: NodePath, node_class: String) -> Node:
	var path_string := String(path).strip_edges()
	if path_string == "":
		return null

	var segments := path_string.split("/")
	var current: Node = parent
	for index in range(segments.size()):
		var segment := segments[index]
		if segment == "":
			continue
		var is_last := index == segments.size() - 1
		var next_type := node_class if is_last else "Node"
		current = ensure_node(current, segment, next_type)
		if current == null:
			return null

	return current


func clear_children(parent: Node, keep_names: PackedStringArray = PackedStringArray()) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		if not (child is Node):
			continue
		if keep_names.has(child.name):
			continue
		child.queue_free()


func _apply_owner_recursive(node: Node) -> void:
	var owner := _resolve_scene_owner()
	if owner == null:
		return
	_set_owner_recursive(node, owner)


func _set_owner_recursive(node: Node, owner: Node) -> void:
	if node != owner and node.owner != owner:
		node.owner = owner
	for child in node.get_children():
		if child is Node:
			_set_owner_recursive(child, owner)


func _resolve_scene_owner() -> Node:
	if get_tree() == null:
		return null
	if Engine.is_editor_hint():
		var edited := get_tree().edited_scene_root
		if edited != null:
			return edited
	return get_tree().current_scene
