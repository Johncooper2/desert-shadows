extends Control
## Minimal touch layer. Buttons synthesize the same actions used by keyboard input.

var joystick_center := Vector2.ZERO
var joystick_touch := -1
var joystick_vector := Vector2.ZERO
var buttons := {
	"switch_character": Rect2(0, 0, 96, 56),
	"interact": Rect2(0, 0, 96, 56),
	"ability": Rect2(0, 0, 96, 56)
}

func _ready() -> void:
	set_process_input(true)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	joystick_center = Vector2(110, size.y - 115)
	draw_circle(joystick_center, 72, Color(0.08, 0.1, 0.12, 0.52))
	draw_circle(joystick_center + joystick_vector * 42.0, 28, Color(0.8, 0.65, 0.3, 0.8))
	var labels := ["SWITCH", "USE", "ABILITY"]
	var actions := ["switch_character", "interact", "ability"]
	for i in 3:
		var rect := Rect2(size.x - 330 + i * 108, size.y - 100, 96, 56)
		buttons[actions[i]] = rect
		draw_style_box(_button_style(), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 34), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

func _button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.72)
	style.border_color = Color(0.8, 0.65, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(joystick_center) < 90:
			joystick_touch = event.index
		elif event.pressed:
			for action in buttons:
				if buttons[action].has_point(event.position):
					Input.action_press(action)
					Input.action_release(action)
		elif event.index == joystick_touch:
			joystick_touch = -1
			joystick_vector = Vector2.ZERO
			_accept_joystick()
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		joystick_vector = joystick_center.direction_to(event.position) * min(joystick_center.distance_to(event.position) / 72.0, 1.0)
		_accept_joystick()

func _accept_joystick() -> void:
	_set_action_strength("move_left", max(-joystick_vector.x, 0.0))
	_set_action_strength("move_right", max(joystick_vector.x, 0.0))
	_set_action_strength("move_up", max(-joystick_vector.y, 0.0))
	_set_action_strength("move_down", max(joystick_vector.y, 0.0))
	queue_redraw()

func _set_action_strength(action: String, strength: float) -> void:
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)