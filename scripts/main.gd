extends Node2D
## Original, asset-free prototype for an isometric real-time tactics game.

const TILE := 48.0
var hero := Vector2(620, 390)
var partner := Vector2(540, 430)
var active_character := 0
var enemy := Vector2(880, 270)
var enemy_alert := 0.0
var objective_done := false
var message := "Reach the marked supply crate."
var ability_message := ""

func _ready() -> void:
	_load_game()
	queue_redraw()

func _process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if active_character == 0:
		hero += input * 220.0 * delta
	else:
		partner += input * 220.0 * delta
	if Input.is_action_just_pressed("switch_character"):
		active_character = 1 - active_character
		message = "Controlling " + ("Cooper" if active_character == 0 else "McCoy")
	if Input.is_action_just_pressed("interact") and hero.distance_to(Vector2(720, 250)) < 90:
		objective_done = true
		message = "Objective complete. Press F5 to save."
	if Input.is_action_just_pressed("save_game"):
		_save_game()
	if Input.is_action_just_pressed("ability"):
		_use_ability()
	_enemy_tick(delta)
	queue_redraw()

func _enemy_tick(delta: float) -> void:
	var controlled := hero if active_character == 0 else partner
	if enemy.distance_to(controlled) < 190:
		enemy_alert = min(enemy_alert + delta, 3.0)
	else:
		enemy_alert = max(enemy_alert - delta, 0.0)
	if enemy_alert > 0.0:
		enemy += enemy.direction_to(controlled) * 22.0 * delta

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("18222a"))
	# Hand-drawn diamond grid keeps the prototype entirely asset-free.
	for y in range(-2, 14):
		for x in range(-2, 28):
			var p := Vector2(x * TILE * 2.0 + (y % 2) * TILE, y * TILE)
			var points := PackedVector2Array([p + Vector2(TILE, 0), p + Vector2(TILE * 2, TILE / 2), p + Vector2(TILE, TILE), p + Vector2(0, TILE / 2)])
			draw_colored_polygon(points, Color("31483f") if (x + y) % 2 == 0 else Color("294039"))
	for obstacle in [Rect2(370, 180, 170, 50), Rect2(760, 430, 180, 55), Rect2(950, 150, 70, 170)]:
		draw_rect(obstacle, Color("70513a"), true)
		draw_rect(obstacle, Color("b28a58"), false, 3.0)
	draw_circle(Vector2(720, 250), 24, Color("d5a84f"))
	draw_string(ThemeDB.fallback_font, Vector2(685, 220), "SUPPLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe7a3"))
	_draw_actor(hero, Color("d5a84f"), "COOPER", active_character == 0)
	_draw_actor(partner, Color("6eb6c9"), "MCCOY", active_character == 1)
	_draw_actor(enemy, Color("b94c4c"), "GUARD", false)
	_draw_hud()

func _draw_actor(pos: Vector2, color: Color, label: String, selected: bool) -> void:
	draw_circle(pos + Vector2(0, 8), 17, Color(0, 0, 0, 0.35))
	draw_circle(pos, 14, color)
	draw_arc(pos, 23, -PI / 2, -PI / 2 + PI * 0.72, 24, Color("f4d6a0") if selected else Color(0, 0, 0, 0), 3)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-34, -25), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_hud() -> void:
	draw_rect(Rect2(18, 18, 410, 104), Color(0.04, 0.07, 0.09, 0.88), true)
	draw_string(ThemeDB.fallback_font, Vector2(35, 48), "DESERT SHADOWS  •  TEST MISSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0c674"))
	draw_string(ThemeDB.fallback_font, Vector2(35, 75), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("e8edf0"))
	draw_string(ThemeDB.fallback_font, Vector2(35, 101), "WASD move   SPACE switch   E interact   Q ability   F5 save", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a6b7b8"))
	if ability_message != "":
		draw_string(ThemeDB.fallback_font, Vector2(520, 650), ability_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0c674"))

func _save_game() -> void:
	var file := FileAccess.open("user://checkpoint.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"hero": hero, "partner": partner, "active": active_character, "objective": objective_done}))
	message = "Checkpoint saved."

func _use_ability() -> void:
	if active_character == 0:
		ability_message = "Cooper: silent step active"
		enemy_alert = max(enemy_alert - 1.5, 0.0)
	else:
		ability_message = "McCoy: decoy syringe thrown"
		enemy_alert = 0.0

func _load_game() -> void:
	if not FileAccess.file_exists("user://checkpoint.json"):
		return
	var file := FileAccess.open("user://checkpoint.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		hero = Vector2(data.get("hero", hero))
		partner = Vector2(data.get("partner", partner))
		active_character = int(data.get("active", active_character))
		objective_done = bool(data.get("objective", objective_done))
		message = "Checkpoint loaded."