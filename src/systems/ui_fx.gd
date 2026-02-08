class_name UIFx
extends RefCounted
## UI 연출 유틸: 페이드·토스트 등 트윈 통일
## 사용: UIFx.fade_in(owner, fade_rect, 0.4) / UIFx.fade_out(...) / UIFx.toast(owner, label, "텍스트", 1.0)

static func fade_alpha(owner_node: Node, target: CanvasItem, from_a: float, to_a: float, duration: float) -> Tween:
	var c_from := Color(1, 1, 1, from_a)
	var c_to := Color(1, 1, 1, to_a)
	target.modulate = c_from
	var t := owner_node.create_tween()
	t.tween_property(target, "modulate", c_to, duration)
	return t

static func fade_in(owner_node: Node, fade_rect: CanvasItem, duration: float) -> Tween:
	return fade_alpha(owner_node, fade_rect, 1.0, 0.0, duration)

static func fade_out(owner_node: Node, fade_rect: CanvasItem, duration: float) -> Tween:
	return fade_alpha(owner_node, fade_rect, 0.0, 1.0, duration)

static func fade_out_node(owner_node: Node, target: CanvasItem, duration: float) -> Tween:
	return fade_alpha(owner_node, target, target.modulate.a, 0.0, duration)

static func toast(owner_node: Node, label_node: Label, text: String, display_sec: float, fade_duration: float = 0.2) -> Tween:
	label_node.text = text
	label_node.visible = true
	label_node.modulate.a = 1.0
	var t := owner_node.create_tween()
	t.tween_interval(display_sec)
	t.tween_property(label_node, "modulate:a", 0.0, fade_duration)
	t.tween_callback(func() -> void: label_node.visible = false)
	return t
