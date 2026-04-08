# Builder API（中文）

本文档覆盖编辑器构建器 API（`editor/builders`）。

## 1. `BaseBuilder`

文件：`editor/builders/base_builder.gd`

类型：
- `@tool`
- `extends Node`

用途：
- 在编辑器或运行时自动构建节点树。
- 统一处理节点创建、路径构建、owner 继承。

导出属性：
- `build_in_editor: bool = true`
- `build_in_game: bool = false`
- `rebuild_trigger: bool`（设置为 `true` 会立即触发 `rebuild()`）

主要方法：
- `_ready() -> void`
- `rebuild() -> void`
- `build() -> void`（子类重写）
- `ensure_node(parent: Node, name: String, node_class: String) -> Node`
- `ensure_path(parent: Node, path: NodePath, node_class: String) -> Node`
- `clear_children(parent: Node, keep_names: PackedStringArray = PackedStringArray()) -> void`

辅助行为：
- 构建后会递归设置 owner，保证编辑器保存场景时节点可序列化。

## 2. `UiPanelBuilder`

文件：`editor/builders/ui_panel_builder.gd`

类型：
- `@tool`
- `extends BaseBuilder`

用途：
- 自动生成一套标准面板 UI（标题、正文、按钮）。

导出属性：
- `title_text: String`
- `body_text: String`
- `button_text: String`
- `panel_margin: Vector2`

重写方法：
- `build() -> void`

生成节点结构：

```text
UiPanelRoot (Control)
  Panel (PanelContainer)
    VBox (VBoxContainer)
      TitleLabel (Label)
      BodyLabel (Label)
      ActionButton (Button)
```

## 3. 用法示例

把构建器节点挂到场景中：

```gdscript
@tool
extends UiPanelBuilder

func _ready() -> void:
	super._ready()
```

或直接在编辑器中：
- 勾选 `build_in_editor`
- 切换 `rebuild_trigger` 为 `true` 触发重建

## 4. 实践建议

- `build()` 保持幂等：同名节点复用，不重复创建。
- 通过 `ensure_node/ensure_path` 保证结构稳定。
- 对需要保留的节点，调用 `clear_children(..., keep_names)` 时明确白名单。
