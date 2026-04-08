# Builder API (English)

This document covers editor builder APIs under `editor/builders`.

## 1. `BaseBuilder`

File: `editor/builders/base_builder.gd`

Type:
- `@tool`
- `extends Node`

Purpose:
- Build or rebuild scene node trees in editor/runtime.
- Provide reusable helper APIs for node creation and owner propagation.

Exported fields:
- `build_in_editor: bool = true`
- `build_in_game: bool = false`
- `rebuild_trigger: bool` (setting `true` triggers `rebuild()`)

Primary methods:
- `_ready() -> void`
- `rebuild() -> void`
- `build() -> void` (override in subclasses)
- `ensure_node(parent: Node, name: String, node_class: String) -> Node`
- `ensure_path(parent: Node, path: NodePath, node_class: String) -> Node`
- `clear_children(parent: Node, keep_names: PackedStringArray = PackedStringArray()) -> void`

Behavior:
- After building, owner is recursively applied so generated nodes are serialized with the edited scene.

## 2. `UiPanelBuilder`

File: `editor/builders/ui_panel_builder.gd`

Type:
- `@tool`
- `extends BaseBuilder`

Purpose:
- Generate a standard panel UI (title/body/button) quickly.

Exported fields:
- `title_text: String`
- `body_text: String`
- `button_text: String`
- `panel_margin: Vector2`

Overridden method:
- `build() -> void`

Generated structure:

```text
UiPanelRoot (Control)
  Panel (PanelContainer)
    VBox (VBoxContainer)
      TitleLabel (Label)
      BodyLabel (Label)
      ActionButton (Button)
```

## 3. Usage example

Attach the builder node into a scene:

```gdscript
@tool
extends UiPanelBuilder

func _ready() -> void:
	super._ready()
```

Or in editor:
- keep `build_in_editor` enabled
- toggle `rebuild_trigger` to `true` for one-shot rebuild

## 4. Recommended practices

- Keep `build()` idempotent (reuse existing nodes by name).
- Use `ensure_node/ensure_path` to keep hierarchy stable.
- Use `clear_children(..., keep_names)` with explicit keep list for safe cleanup.
