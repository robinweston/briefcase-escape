extends Node3D

const WORLD_X_HALF := 15.0
const WORLD_Z_HALF := 10.0
const TILE_SIZE := 0.5
const DIVIDER_THICKNESS := 0.16
const WORKSTATION_TILES := Vector3i(5, 2, 2)
const FILING_CABINET_TILES := Vector3i(3, 3, 2)
const FILING_CABINET_STACK_STRIDE := TILE_SIZE
const OFFICE_PLANT_TILES := Vector3i(3, 3, 2)
const OFFICE_PRINTER_TILES := Vector3i(3, 3, 2)
const VENDING_MACHINE_TILES := Vector3i(3, 4, 2)
const BATHROOM_SINKS_TILES := Vector3i(5, 3, 2)
const BATHROOM_TOILET_TILES := Vector3i(2, 2, 2)
const MOVE_SPEED := 4.2
const WORKER_SPEED := 1.35
const VISION_RANGE := 3.8
const VISION_HALF_ANGLE := deg_to_rad(30.0)
const VISION_RAY_COUNT := 17
const START_POSITION := Vector3(-13.5, 0.0, 8.3)
const EXIT_POSITION := Vector3(13.5, 0.0, -8.3)
const CAMERA_OFFSET := Vector3(0.0, 12.0, 10.0)
const CAMERA_FOCUS_X_LIMIT := 3.9
const CAMERA_FOCUS_MIN_Z := -5.5
const CAMERA_FOCUS_MAX_Z := 1.85
const WorkerFrames = preload("res://scripts/worker_sprite_frames.gd")
const TitleScreen = preload("res://scripts/title_screen.gd")
const PauseController = preload("res://scripts/pause_controller.gd")
const ResultScreen = preload("res://scripts/result_screen.gd")
const BRIEFCASE_ATLAS := preload("res://assets/briefcase_walk.svg")
const HIDDEN_BRIEFCASE_TEXTURE := preload("res://assets/briefcase_hidden.svg")
const FLOOR_CARPET_BLUE_GREY := preload("res://assets/flooring/office-carpet-blue-grey.png")
const FLOOR_CARPET_TEAL := preload("res://assets/flooring/office-carpet-teal-accent.png")
const FLOOR_VINYL_CHARCOAL := preload("res://assets/flooring/office-vinyl-charcoal.svg")
const FLOOR_WOOD := preload("res://assets/flooring/office-wood-dark.png")
const FLOOR_TINT := Color("#929b9c")
const WORKSTATION_TEXTURE := preload("res://assets/scenery/generated/workstation.png")
const DIVIDER_TEXTURE := preload("res://assets/scenery/generated/divider.png")
const FILING_CABINET_TEXTURE := preload("res://assets/scenery/generated/filing-cabinet.png")
const OFFICE_PLANT_TEXTURE := preload("res://assets/scenery/generated/office-plant.png")
const EXIT_SIGN_TEXTURE := preload("res://assets/scenery/generated/exit-sign.png")
const DISGUISE_POTION_TEXTURE := preload("res://assets/scenery/generated/disguise-potion.png")
const OFFICE_PRINTER_TEXTURE := preload("res://assets/scenery/generated/office-printer.png")
const VENDING_MACHINE_TEXTURE := preload("res://assets/scenery/generated/vending-machine.png")
const BATHROOM_SINKS_TEXTURE := preload("res://assets/scenery/generated/bathroom-sinks.png")
const BATHROOM_TOILET_TEXTURE := preload("res://assets/scenery/generated/bathroom-toilet.png")
const LEVEL_MUSIC := preload("res://assets/audio/stealth_in_the_woods.mp3")
const OFFICE_AMBIENCE := preload("res://assets/audio/busy_office_ambience.mp3")
const SFX_GAME_START := preload("res://assets/audio/sfx/game_start_1.wav")
const SFX_DISGUISE_ON := preload("res://assets/audio/sfx/disguise_on_1.wav")
const SFX_DISGUISE_OFF := preload("res://assets/audio/sfx/disguise_off_1.wav")
const SFX_POTION_PICKUP := preload("res://assets/audio/sfx/potion_pickup_1.wav")
const SFX_WORKER_ALERT := preload("res://assets/audio/sfx/worker_alert_1.wav")
const SFX_BRIEFCASE_PICKUP := preload("res://assets/audio/sfx/briefcase_pickup_1.wav")
const SFX_BRIEFCASE_DROP := preload("res://assets/audio/sfx/briefcase_drop_1.wav")
const SFX_CAUGHT := preload("res://assets/audio/sfx/caught_1.wav")
const SFX_LEVEL_COMPLETE := preload("res://assets/audio/sfx/level_complete_1.wav")
const WORKER_ATLASES := [
	preload("res://assets/office_workers/animated/a-intern-atlas.svg"),
	preload("res://assets/office_workers/animated/b-anime-atlas.svg"),
	preload("res://assets/office_workers/animated/c-manager-atlas.svg"),
	preload("res://assets/office_workers/animated/d-analyst-atlas.svg"),
	preload("res://assets/office_workers/animated/e-supervisor-atlas.svg"),
	preload("res://assets/office_workers/animated/f-creative-atlas.svg"),
	preload("res://assets/office_workers/animated/g-coordinator-atlas.svg"),
	preload("res://assets/office_workers/animated/h-specialist-atlas.svg"),
]
const BRIEFCASE_DIRECTIONS := [&"s", &"e", &"n", &"w"]
const BRIEFCASE_FRAME_SIZE := Vector2(256.0, 256.0)
const BRIEFCASE_SPRITE_PIXEL_SIZE := 0.0041
const BRIEFCASE_WALK_FPS := 9.0
const HIDDEN_TIME_MAX := 5.0
const POTION_REFILL := 1.0
const DROP_DISGUISE_GRACE_TIME := 3.0
const CARRY_SPEED := 2.7
const WORKER_PATH_RADIUS := 0.36
const CARRIED_BRIEFCASE_HEIGHT := 0.62
const CARRIED_BRIEFCASE_OCCLUSION_DEPTH := 0.58
const TRANSFORM_TIME := 0.28
const OPENING_DISGUISE_DELAY := 1.0
const PROP_INK := Color("#26344a")
const WORKER_SPRITE_PIXEL_SIZE := 0.0093
enum StaticPropFacing { SOUTH, EAST, NORTH, WEST }
const BATHROOM_POTION_POSITION := Vector3(-12.75, 0.0, -8.35)
const POTION_POSITIONS := [
	BATHROOM_POTION_POSITION,
	Vector3(-11.0, 0.0, 0.2),
	Vector3(-6.0, 0.0, 4.8),
	Vector3(0.0, 0.0, 7.6),
	Vector3(0.0, 0.0, -7.6),
	Vector3(6.0, 0.0, 4.8),
	Vector3(11.0, 0.0, -0.2),
	Vector3(11.8, 0.0, 7.0),
]

var worker_routes: Array[PackedVector3Array] = [
	# Long patrols use the partition doorways to move between rooms. The red
	# worker starts by walking away from the briefcase and spends most of each
	# circuit outside the starting room, giving the opening route room to breathe.
	PackedVector3Array([
		Vector3(-10.8, 0.0, 7.6), Vector3(6.0, 0.0, 7.6),
		Vector3(6.0, 0.0, 9.2), Vector3(4.5, 0.0, 9.2),
		Vector3(4.5, 0.0, 7.6),
	]),
	PackedVector3Array([
		Vector3(-11.3, 0.0, 2.5), Vector3(-6.0, 0.0, 2.5),
		Vector3(-6.0, 0.0, 7.6), Vector3(-4.2, 0.0, 7.6),
		Vector3(-6.0, 0.0, 7.6), Vector3(-6.0, 0.0, -2.5),
		Vector3(-11.3, 0.0, -2.5),
	]),
	PackedVector3Array([
		Vector3(6.0, 0.0, -2.5), Vector3(11.4, 0.0, -2.5),
		Vector3(11.4, 0.0, 2.5), Vector3(6.0, 0.0, 2.5),
		Vector3(6.0, 0.0, -7.8), Vector3(3.8, 0.0, -7.8),
		Vector3(6.0, 0.0, -7.8),
	]),
	PackedVector3Array([
		Vector3(3.8, 0.0, -7.8), Vector3(-6.5, 0.0, -7.8),
		Vector3(-6.5, 0.0, -8.8), Vector3(-2.8, 0.0, -8.8),
		Vector3(-2.8, 0.0, -7.8),
	]),
	PackedVector3Array([
		Vector3(-6.0, 0.0, 6.8), Vector3(-6.0, 0.0, 2.5),
		Vector3(-11.3, 0.0, 2.5), Vector3(-11.3, 0.0, -2.5),
		Vector3(-6.0, 0.0, -2.5),
	]),
	PackedVector3Array([
		Vector3(0.8, 0.0, 1.8), Vector3(0.8, 0.0, -2.5),
		Vector3(-11.3, 0.0, -2.5), Vector3(-11.3, 0.0, 2.5),
		Vector3(0.8, 0.0, 2.5),
	]),
	PackedVector3Array([
		Vector3(-9.5, 0.0, -7.8), Vector3(11.5, 0.0, -7.8),
		Vector3(11.5, 0.0, -9.0), Vector3(3.8, 0.0, -9.0),
		Vector3(3.8, 0.0, -7.8),
	]),
	PackedVector3Array([
		Vector3(4.8, 0.0, 7.5), Vector3(6.0, 0.0, 7.5),
		Vector3(6.0, 0.0, 2.5), Vector3(11.4, 0.0, 2.5),
		Vector3(11.4, 0.0, -2.5), Vector3(6.0, 0.0, -2.5),
		Vector3(6.0, 0.0, 7.5),
	]),
]

var player: CharacterBody3D
var player_sprite: AnimatedSprite3D
var hidden_sprite: Sprite3D
var player_collision: CollisionShape3D
var player_facing := &"s"
var camera: Camera3D
var workers: Array[Dictionary] = []
var cubicle_drop_points: Array[Vector3] = []
var potions: Array[Node3D] = []
var status_label: Label
var hidden_time_bar: ProgressBar
var hidden_time_label: Label
var hidden_time_seconds_label: Label
var disguise_panel_style: StyleBoxFlat
var hidden_time_bar_background: StyleBoxFlat
var hidden_time_bar_fill: StyleBoxFlat
var resetting := false
var level_complete := false
var hidden_mode := true
var hidden_time := HIDDEN_TIME_MAX
var starting_disguise := true
var is_transforming := false
var opening_animation_active := false
var pickup_worker: Dictionary = {}
var carrying_worker: Dictionary = {}
var carry_target := Vector3.ZERO
var pickup_route := PackedVector3Array()
var pickup_route_index := 0
var carry_route := PackedVector3Array()
var carry_route_index := 0
var excursion_route := PackedVector3Array()
var interrupted_patrol_index := 0
var pickup_cooldown := 0.0
var drop_disguise_grace_time := 0.0
var transformation_tween: Tween
var gameplay_hud: CanvasLayer
var title_screen: CanvasLayer
var result_screen: CanvasLayer
var pause_controller
var title_screen_active := false
var floor_number := 1
var music_player: AudioStreamPlayer
var office_ambience_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	_build_world()
	_build_player()
	_build_workers()
	_build_camera()
	_build_hud()
	_build_audio()
	_update_hidden_time_hud()
	if not _should_skip_title_screen():
		_show_title_screen()
	else:
		office_ambience_player.play()
		_begin_opening_animation()


func _unhandled_input(event: InputEvent) -> void:
	if title_screen_active:
		if _is_start_event(event):
			_start_first_level()
			get_viewport().set_input_as_handled()
		return
	if result_screen.is_report_visible():
		if _is_start_event(event):
			_continue_from_result()
			get_viewport().set_input_as_handled()
		return
	if opening_animation_active:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_disguise") and not resetting and not level_complete:
		if pickup_worker.is_empty() and carrying_worker.is_empty() and not is_transforming:
			_set_hidden_mode(not hidden_mode)


func _physics_process(delta: float) -> void:
	if title_screen_active:
		player.velocity = Vector3.ZERO
		_set_player_animation(Vector2.ZERO)
		return
	if resetting or level_complete or opening_animation_active:
		player.velocity = Vector3.ZERO
		_set_player_animation(Vector2.ZERO)
		return

	pickup_cooldown = maxf(0.0, pickup_cooldown - delta)
	var had_drop_disguise_grace := drop_disguise_grace_time > 0.0
	drop_disguise_grace_time = maxf(0.0, drop_disguise_grace_time - delta)
	if had_drop_disguise_grace and drop_disguise_grace_time <= 0.0:
		_update_hidden_time_hud()
	_update_workers(delta)
	if carrying_worker.is_empty() and pickup_worker.is_empty() and not hidden_mode:
		_update_player()
		_collect_nearby_potion()
	else:
		player.velocity = Vector3.ZERO
		_set_player_animation(Vector2.ZERO)
	_update_camera(delta)

	if not carrying_worker.is_empty():
		return
	if not pickup_worker.is_empty():
		if not hidden_mode:
			_caught(pickup_worker)
		return

	var seeing_worker := _worker_that_sees_player()
	if not seeing_worker.is_empty():
		if hidden_mode and pickup_cooldown <= 0.0:
			_begin_carry(seeing_worker)
		elif not hidden_mode:
			_caught(seeing_worker)
		return

	if hidden_mode and not starting_disguise and drop_disguise_grace_time <= 0.0:
		_drain_hidden_time(delta)

	if player.global_position.distance_to(EXIT_POSITION) < 0.8:
		_complete_level()


func _drain_hidden_time(delta: float) -> void:
	hidden_time = maxf(0.0, hidden_time - delta)
	_update_hidden_time_hud()
	if hidden_time <= 0.0:
		_set_hidden_mode(false)


func _update_player() -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input_vector = _cardinal_input(input_vector)
	_set_player_animation(input_vector)
	var desired := Vector3.ZERO
	if input_vector.length() > 0.05:
		# The camera is aligned to the world axes, so screen and world directions match.
		desired = Vector3(input_vector.x, 0.0, input_vector.y)

	player.velocity = desired * MOVE_SPEED
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -WORLD_X_HALF, WORLD_X_HALF)
	player.position.z = clampf(player.position.z, -WORLD_Z_HALF, WORLD_Z_HALF)


func _cardinal_input(input_vector: Vector2) -> Vector2:
	if absf(input_vector.x) > absf(input_vector.y):
		return Vector2(signf(input_vector.x), 0.0)
	if absf(input_vector.y) > 0.05:
		return Vector2(0.0, signf(input_vector.y))
	return Vector2.ZERO


func _set_player_animation(input_vector: Vector2) -> void:
	var animation_name: StringName
	if input_vector.length() > 0.05:
		player_facing = _screen_direction_name(input_vector)
		animation_name = StringName("walk_%s" % player_facing)
	else:
		animation_name = StringName("idle_%s" % player_facing)

	if player_sprite.animation != animation_name or not player_sprite.is_playing():
		player_sprite.play(animation_name)


func _screen_direction_name(input_vector: Vector2) -> StringName:
	if absf(input_vector.x) > absf(input_vector.y):
		return &"e" if input_vector.x > 0.0 else &"w"
	return &"s" if input_vector.y > 0.0 else &"n"


func _update_workers(_delta: float) -> void:
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		if not carrying_worker.is_empty() and body == carrying_worker["body"]:
			_update_carrying_worker(worker)
			_update_vision_cone(worker)
			continue
		if worker["returning"]:
			_update_returning_worker(worker)
			_update_vision_cone(worker)
			continue
		if not pickup_worker.is_empty() and body == pickup_worker["body"]:
			_update_pickup_worker(worker)
			_update_vision_cone(worker)
			continue
		var route: PackedVector3Array = worker["route"]
		var target: Vector3 = route[worker["index"]]
		var offset := target - body.position
		offset.y = 0.0

		if offset.length() < 0.12:
			worker["index"] = (worker["index"] + 1) % route.size()
			target = route[worker["index"]]
			offset = target - body.position
			offset.y = 0.0

		var direction := _cardinal_world_direction(offset)
		body.velocity = direction * WORKER_SPEED
		body.rotation.y = atan2(-direction.x, -direction.z)
		_set_worker_animation(worker, &"walk", direction)
		body.move_and_slide()
		_update_vision_cone(worker)


func _update_pickup_worker(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var target := pickup_route[pickup_route_index]
	var offset := target - body.position
	offset.y = 0.0
	var is_final_leg := pickup_route_index == pickup_route.size() - 1
	var arrival_distance := 0.68 if is_final_leg else 0.08
	if offset.length() < arrival_distance:
		if is_final_leg:
			_lift_player(worker)
			return
		body.position = target
		excursion_route.append(target)
		pickup_route_index += 1
		target = pickup_route[pickup_route_index]
		offset = target - body.position
		offset.y = 0.0

	var direction := _cardinal_world_direction(offset)
	body.velocity = direction * CARRY_SPEED
	body.rotation.y = atan2(-direction.x, -direction.z)
	_set_worker_animation(worker, &"carry_cross", direction)
	body.move_and_slide()


func _update_carrying_worker(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var target := carry_route[carry_route_index]
	var offset := target - body.position
	offset.y = 0.0
	var is_final_leg := carry_route_index == carry_route.size() - 1
	var arrival_distance := 0.16 if is_final_leg else 0.08
	if offset.length() < arrival_distance:
		if is_final_leg:
			_finish_carry(worker)
			return
		body.position = target
		excursion_route.append(target)
		carry_route_index += 1
		target = carry_route[carry_route_index]
		offset = target - body.position
		offset.y = 0.0

	var direction := _cardinal_world_direction(offset)
	body.velocity = direction * CARRY_SPEED
	body.rotation.y = atan2(-direction.x, -direction.z)
	_set_worker_animation(worker, &"carry_cross", direction)
	body.move_and_slide()
	_position_carried_player(worker)


func _update_returning_worker(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var route: PackedVector3Array = worker["return_route"]
	var route_index: int = worker["return_route_index"]
	var target := route[route_index]
	var offset := target - body.position
	offset.y = 0.0
	if offset.length() < 0.08:
		body.position = target
		if route_index == route.size() - 1:
			_finish_return(worker)
			return
		route_index += 1
		worker["return_route_index"] = route_index
		target = route[route_index]
		offset = target - body.position
		offset.y = 0.0

	var direction := _cardinal_world_direction(offset)
	body.velocity = direction * WORKER_SPEED
	body.rotation.y = atan2(-direction.x, -direction.z)
	_set_worker_animation(worker, &"walk", direction)
	body.move_and_slide()


func _cardinal_world_direction(offset: Vector3) -> Vector3:
	if absf(offset.x) > absf(offset.z):
		return Vector3(signf(offset.x), 0.0, 0.0)
	return Vector3(0.0, 0.0, signf(offset.z))


func _cardinal_route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var route := PackedVector3Array()
	var offset := to - from
	# Finish the longer axis first. This gives the worker long, readable straight
	# runs instead of reconsidering the dominant axis on every physics frame.
	if absf(offset.x) > absf(offset.z):
		if not is_zero_approx(offset.z):
			route.append(Vector3(to.x, from.y, from.z))
	elif not is_zero_approx(offset.x):
		route.append(Vector3(from.x, from.y, to.z))
	route.append(to)
	return route


func _collision_safe_cardinal_route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := _world_to_path_cell(from)
	var goal := _world_to_path_cell(to)
	var frontier: Array[Vector2i] = [start]
	var frontier_index := 0
	var parents := {start: start}
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP,
	]

	while frontier_index < frontier.size() and not parents.has(goal):
		var current := frontier[frontier_index]
		frontier_index += 1
		for direction in directions:
			var next := current + direction
			if parents.has(next) or not _path_cell_is_in_bounds(next):
				continue
			var current_point := _path_cell_to_world(current, from.y)
			var next_point := _path_cell_to_world(next, from.y)
			if not _worker_path_point_is_clear(next_point):
				continue
			if not _worker_path_point_is_clear((current_point + next_point) * 0.5):
				continue
			parents[next] = current
			frontier.append(next)

	if not parents.has(goal):
		return PackedVector3Array()

	var reversed_cells: Array[Vector2i] = []
	var cell := goal
	while cell != start:
		reversed_cells.append(cell)
		cell = parents[cell]
	reversed_cells.reverse()

	var route := PackedVector3Array()
	for path_cell in reversed_cells:
		var point := _path_cell_to_world(path_cell, from.y)
		if route.size() < 2:
			route.append(point)
			continue
		var previous_direction := route[-1] - route[-2]
		var next_direction := point - route[-1]
		if _cardinal_world_direction(previous_direction) == _cardinal_world_direction(next_direction):
			route[-1] = point
		else:
			route.append(point)

	if route.is_empty() or route[-1].distance_squared_to(to) > 0.0001:
		route.append(to)
	return route


func _world_to_path_cell(point: Vector3) -> Vector2i:
	return Vector2i(roundi(point.x / TILE_SIZE), roundi(point.z / TILE_SIZE))


func _path_cell_to_world(cell: Vector2i, height: float) -> Vector3:
	return Vector3(cell.x * TILE_SIZE, height, cell.y * TILE_SIZE)


func _path_cell_is_in_bounds(cell: Vector2i) -> bool:
	var point := _path_cell_to_world(cell, 0.0)
	return (
		absf(point.x) <= WORLD_X_HALF - WORKER_PATH_RADIUS
		and absf(point.z) <= WORLD_Z_HALF - WORKER_PATH_RADIUS
	)


func _worker_path_point_is_clear(point: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = WORKER_PATH_RADIUS
	shape.height = 1.55
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0.0, 0.8, 0.0))
	query.collision_mask = 2
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _position_carried_player(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var carry_offset := Vector3(0.0, CARRIED_BRIEFCASE_HEIGHT, 0.0)
	if worker["facing"] != &"s":
		# Move along the pitched camera ray: this changes only draw depth, leaving
		# the briefcase in the same apparent place in the worker's arms.
		carry_offset += -camera.global_transform.basis.z * CARRIED_BRIEFCASE_OCCLUSION_DEPTH
	player.global_position = body.global_position + carry_offset


func _worker_that_sees_player() -> Dictionary:
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		if not worker["vision_enabled"]:
			continue
		var origin := body.global_position + Vector3(0.0, 0.52, 0.0)
		var target := player.global_position + Vector3(0.0, 0.45, 0.0)
		var to_player := target - origin
		var flat_to_player := Vector3(to_player.x, 0.0, to_player.z)

		if flat_to_player.length() > VISION_RANGE:
			continue

		var forward := -body.global_transform.basis.z
		forward.y = 0.0
		if forward.normalized().dot(flat_to_player.normalized()) < cos(VISION_HALF_ANGLE):
			continue

		# Layer 2 contains sight-blocking office furniture and walls.
		var query := PhysicsRayQueryParameters3D.create(origin, target, 2)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return worker

	return {}


func _begin_carry(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var route := _collision_safe_cardinal_route(body.position, player.position)
	if route.is_empty():
		return
	_play_sfx(SFX_WORKER_ALERT)
	pickup_worker = worker
	_set_worker_vision_enabled(worker, false)
	_update_hidden_time_hud()
	interrupted_patrol_index = worker["index"]
	excursion_route.clear()
	excursion_route.append(body.position)
	pickup_route = route
	pickup_route_index = 0
	player.velocity = Vector3.ZERO
	var approach_direction := pickup_route[0] - body.position
	_set_worker_animation(worker, &"carry_cross", approach_direction.normalized())
	status_label.text = "WORKER COMING"
	status_label.add_theme_color_override("font_color", Color("#ffd166"))


func _lift_player(worker: Dictionary) -> void:
	_play_sfx(SFX_BRIEFCASE_PICKUP)
	var body: CharacterBody3D = worker["body"]
	pickup_worker = {}
	carrying_worker = worker
	if excursion_route[-1].distance_squared_to(body.position) > 0.0001:
		excursion_route.append(body.position)
	var drop := _nearest_reachable_cubicle_drop(body.position, player.global_position)
	if drop.is_empty():
		_caught(worker)
		return
	carry_target = drop["target"]
	carry_route = drop["route"]
	carry_route_index = 0
	player_collision.disabled = true
	var carry_direction := carry_route[0] - body.position
	_set_worker_animation(worker, &"carry_cross", carry_direction.normalized())
	_position_carried_player(worker)
	status_label.text = "PICKED UP"


func _finish_carry(worker: Dictionary) -> void:
	_play_sfx(SFX_BRIEFCASE_DROP)
	var body: CharacterBody3D = worker["body"]
	body.position = carry_target
	body.velocity = Vector3.ZERO
	player.position = carry_target
	player_collision.disabled = false
	excursion_route.append(carry_target)
	var return_route := PackedVector3Array()
	for i in range(excursion_route.size() - 2, -1, -1):
		return_route.append(excursion_route[i])
	worker["return_route"] = return_route
	worker["return_route_index"] = 0
	worker["resume_index"] = interrupted_patrol_index
	worker["returning"] = true
	var return_direction := return_route[0] - body.position
	_set_worker_animation(worker, &"walk", return_direction.normalized())
	carrying_worker = {}
	pickup_route.clear()
	carry_route.clear()
	pickup_cooldown = 1.0
	drop_disguise_grace_time = DROP_DISGUISE_GRACE_TIME
	_update_hidden_time_hud()
	status_label.text = ""


func _finish_return(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	body.velocity = Vector3.ZERO
	body.collision_mask = 2
	worker["index"] = worker["resume_index"]
	var route: PackedVector3Array = worker["route"]
	var patrol_direction := route[worker["index"]] - body.position
	_set_worker_animation(worker, &"walk", patrol_direction.normalized())
	worker["returning"] = false
	worker["return_route"] = PackedVector3Array()
	worker["return_route_index"] = 0
	_set_worker_vision_enabled(worker, true)


func _set_worker_vision_enabled(worker: Dictionary, enabled: bool) -> void:
	worker["vision_enabled"] = enabled
	var cone: MeshInstance3D = worker["cone"]
	cone.visible = enabled


func _nearest_reachable_cubicle_drop(worker_position: Vector3, from: Vector3) -> Dictionary:
	var nearest := Vector3.ZERO
	var nearest_route := PackedVector3Array()
	var nearest_distance := INF
	for point in cubicle_drop_points:
		var route := _collision_safe_cardinal_route(worker_position, point)
		if route.is_empty():
			continue
		var distance := from.distance_squared_to(point)
		if distance < nearest_distance:
			nearest = point
			nearest_route = route
			nearest_distance = distance
	if nearest_route.is_empty():
		return {}
	return {"target": nearest, "route": nearest_route}


func _caught(catching_worker: Dictionary) -> void:
	if resetting:
		return
	_play_sfx(SFX_CAUGHT)
	resetting = true
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		body.velocity = Vector3.ZERO
		if not catching_worker.is_empty() and body == catching_worker["body"]:
			_set_worker_animation(worker, &"surprised")
		else:
			_set_worker_animation(worker, &"idle")
	status_label.text = ""
	await get_tree().create_timer(0.9).timeout
	result_screen.show_report(false, floor_number)


func _reset_level() -> void:
	if transformation_tween and transformation_tween.is_valid():
		transformation_tween.kill()
	transformation_tween = null
	hidden_mode = true
	is_transforming = false
	hidden_time = HIDDEN_TIME_MAX
	starting_disguise = true
	pickup_worker = {}
	carrying_worker = {}
	pickup_route.clear()
	carry_route.clear()
	excursion_route.clear()
	pickup_cooldown = 0.0
	drop_disguise_grace_time = 0.0
	player.position = START_POSITION
	player.velocity = Vector3.ZERO
	player_collision.disabled = false
	player_facing = &"s"
	player_sprite.visible = false
	player_sprite.modulate = Color.WHITE
	player_sprite.scale = Vector3.ONE
	hidden_sprite.visible = true
	hidden_sprite.modulate = Color.WHITE
	hidden_sprite.scale = Vector3.ONE
	_set_player_animation(Vector2.ZERO)
	for worker in workers:
		var body: CharacterBody3D = worker["body"]
		var route: PackedVector3Array = worker["route"]
		body.position = route[0]
		worker["index"] = 1
		worker["returning"] = false
		_set_worker_vision_enabled(worker, true)
		worker["return_route"] = PackedVector3Array()
		worker["return_route_index"] = 0
		var direction := (route[1] - route[0]).normalized()
		body.rotation.y = atan2(-direction.x, -direction.z)
		body.velocity = Vector3.ZERO
		body.collision_mask = 2
		_set_worker_animation(worker, &"walk", direction)
	for potion in potions:
		potion.visible = true
		potion.set_meta("collected", false)
	status_label.text = ""
	resetting = false
	_update_hidden_time_hud()
	_snap_camera_to_player()


func _complete_level() -> void:
	if level_complete:
		return
	_play_sfx(SFX_LEVEL_COMPLETE)
	level_complete = true
	player.velocity = Vector3.ZERO
	status_label.text = ""
	result_screen.show_report(true, floor_number)


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#152034")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e5efff")
	env.ambient_light_energy = 0.72
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -35.0, 0.0)
	sun.light_color = Color("#fff4dc")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(WORLD_X_HALF * 2.08, WORLD_Z_HALF * 2.08)
	ground.mesh = ground_mesh
	ground.material_override = _material(Color("#59666b"), 0.96)
	add_child(ground)

	_add_room_flooring()
	_add_room_partitions()
	_add_office_furniture()
	_add_exit()
	_build_potions()


func _add_room_flooring() -> void:
	# Narrow gaps expose the neutral base floor as thresholds between six office
	# rooms. The room partitions follow these same cubicle-aligned boundaries.
	var room_width := 14.93
	var outer_room_depth := 6.6
	var middle_room_depth := 6.52
	var left_x := -7.535
	var right_x := 7.535
	var outer_z := 6.7

	# Repeated materials sit diagonally rather than sharing an edge.
	_add_floor_zone(
		Vector3(left_x, 0.0, outer_z),
		Vector2(room_width, outer_room_depth),
		FLOOR_VINYL_CHARCOAL,
		3.2
	)
	_add_floor_zone(
		Vector3(right_x, 0.0, outer_z),
		Vector2(room_width, outer_room_depth),
		FLOOR_CARPET_BLUE_GREY,
		4.0
	)
	_add_floor_zone(Vector3(left_x, 0.0, 0.0), Vector2(room_width, middle_room_depth), FLOOR_WOOD)
	_add_floor_zone(
		Vector3(right_x, 0.0, 0.0),
		Vector2(room_width, middle_room_depth),
		FLOOR_CARPET_TEAL,
		4.0
	)
	_add_floor_zone(
		Vector3(left_x, 0.0, -outer_z),
		Vector2(room_width, outer_room_depth),
		FLOOR_CARPET_BLUE_GREY,
		4.0
	)
	_add_floor_zone(Vector3(right_x, 0.0, -outer_z), Vector2(room_width, outer_room_depth), FLOOR_WOOD)


func _add_floor_zone(
	at: Vector3,
	size: Vector2,
	texture: Texture2D,
	texture_world_size := 8.0,
	surface_y := 0.008
) -> void:
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = size
	floor.mesh = floor_mesh
	floor.position = at + Vector3(0.0, surface_y, 0.0)

	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = texture
	# Keep the illustrated flooring subordinate to characters and yellow sight
	# cones. The neutral tint also ties the different room materials together.
	floor_material.albedo_color = FLOOR_TINT
	floor_material.roughness = 0.95
	# One texture repeat should be furniture-scale, not room-scale. Vinyl uses
	# smaller slabs, carpet uses medium modules, and wood keeps longer boards.
	floor_material.uv1_scale = Vector3(
		size.x / texture_world_size, size.y / texture_world_size, 1.0
	)
	floor.material_override = floor_material
	add_child(floor)


func _add_room_partitions() -> void:
	# Low top-down walls keep the scene visually flat. Their plain openings line
	# up with the workers' patrol lanes so every route remains unobstructed.
	_add_room_wall_along_z(0.0, 3.4, 10.0, [7.8])
	_add_room_wall_along_z(0.0, -3.26, 3.26, [-2.5, 2.5])
	_add_room_wall_along_z(0.0, -10.0, -3.4, [-7.8])
	_add_room_wall_along_x(3.33, -15.0, 0.0, [-6.0])
	_add_room_wall_along_x(3.33, 0.0, 15.0, [6.0])
	_add_room_wall_along_x(-3.33, -15.0, 0.0, [-6.0])
	_add_room_wall_along_x(-3.33, 0.0, 15.0, [6.0])


func _add_room_wall_along_x(z: float, from_x: float, to_x: float, door_centers: Array) -> void:
	var segment_start := from_x
	for door_center_value in door_centers:
		var door_center := float(door_center_value)
		var opening_start := maxf(segment_start, door_center - 0.9)
		_add_room_wall_segment_x(z, segment_start, opening_start)
		segment_start = minf(to_x, door_center + 0.9)
	_add_room_wall_segment_x(z, segment_start, to_x)


func _add_room_wall_along_z(x: float, from_z: float, to_z: float, door_centers: Array) -> void:
	var segment_start := from_z
	for door_center_value in door_centers:
		var door_center := float(door_center_value)
		var opening_start := maxf(segment_start, door_center - 0.9)
		_add_room_wall_segment_z(x, segment_start, opening_start)
		segment_start = minf(to_z, door_center + 0.9)
	_add_room_wall_segment_z(x, segment_start, to_z)


func _add_room_wall_segment_x(z: float, from_x: float, to_x: float) -> void:
	var length := to_x - from_x
	if length > 0.08:
		_add_low_room_wall(Vector3((from_x + to_x) * 0.5, 0.0, z), Vector3(length, 0.5, 0.18))


func _add_room_wall_segment_z(x: float, from_z: float, to_z: float) -> void:
	var length := to_z - from_z
	if length > 0.08:
		_add_low_room_wall(Vector3(x, 0.0, (from_z + to_z) * 0.5), Vector3(0.18, 0.5, length))


func _add_low_room_wall(at: Vector3, size: Vector3) -> void:
	var footprint_tiles := Vector2i(
		maxi(1, roundi(size.x / TILE_SIZE)),
		maxi(1, roundi(size.z / TILE_SIZE))
	)
	# Room-wall endpoints are authored around doorways, then their spans are
	# quantized here so every resulting divider covers a whole number of tiles.
	size = Vector3(
		footprint_tiles.x * TILE_SIZE if footprint_tiles.x > 1 else DIVIDER_THICKNESS,
		TILE_SIZE,
		footprint_tiles.y * TILE_SIZE if footprint_tiles.y > 1 else DIVIDER_THICKNESS
	)
	var body := StaticBody3D.new()
	body.position = at
	body.set_meta("tile_footprint", footprint_tiles)
	body.set_meta("tile_height", 1)
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)

	# A dark shallow side and slim warm cap provide depth without introducing a
	# front-facing wall sprite or changing the established near-2D viewpoint.
	_add_box_mesh(body, size, Vector3(0.0, size.y * 0.5, 0.0), Color("#6f514d"))
	var cap_size := Vector3(size.x + 0.04, 0.06, size.z + 0.04)
	_add_box_mesh(body, cap_size, Vector3(0.0, size.y + 0.01, 0.0), Color("#d6a47e"))


func _add_office_furniture() -> void:
	# Alternating U-shaped cubicles create corridors, blind corners, and cover.
	var columns := [-9.0, -3.0, 3.0, 9.0]
	var rows := [5.0, 0.0, -5.0]
	for row_index in rows.size():
		for column_index in columns.size():
			# Outer-row entrances must face away from the adjacent room wall or the
			# divider seals the cubicle. Only the unobstructed middle row alternates.
			var opens_positive_z := row_index == 0
			if row_index > 0 and row_index < rows.size() - 1:
				opens_positive_z = (row_index + column_index) % 2 == 0
			_add_cubicle(Vector3(columns[column_index], 0.0, rows[row_index]), opens_positive_z)

	_add_partition_tiles(Vector3(-12.0, 0.0, 4.0), Vector2i(1, 8), 3)
	_add_partition_tiles(Vector3(12.0, 0.0, -4.0), Vector2i(1, 8), 3)
	_add_partition_tiles(Vector3(-8.5, 0.0, -8.5), Vector2i(6, 1), 3)
	_add_partition_tiles(Vector3(9.0, 0.0, 8.5), Vector2i(8, 1), 3)

	# Depth-stacked banks use a one-tile contact stride. The foreground cabinet
	# is drawn last so it hides the bodies behind it, leaving a readable run of
	# cabinet tops instead of four complete side silhouettes.
	_add_cabinet_stack(-14.5, -0.75, 4, StaticPropFacing.EAST)
	_add_cabinet_stack(14.5, -0.5, 3, StaticPropFacing.WEST)

	# A front-facing pair backs directly onto the central room boundary, with
	# enough clearance from the nearby cubicle and vending-machine footprint.
	for cabinet_x in [12.0, 13.5]:
		_add_cabinet(Vector3(cabinet_x, 0.0, 3.9), StaticPropFacing.SOUTH)
	# Decorative plants that were already in perimeter bays sit flush by their
	# base footprint instead of floating a partial tile away from the wall.
	_add_plant(Vector3(13.0, 0.0, 9.5))
	_add_plant(Vector3(-1.0, 0.0, -9.5))
	_add_plant(Vector3(-1.0, 0.0, 9.5))

	# Extra office amenities sit against perimeter walls, preserving the central
	# routes and the screen-aligned movement lanes.
	# The bottom-left printer backs onto that room's north wall and faces down
	# (south) into the room. The upper-right printer is flush to the east wall.
	_add_printer(Vector3(-13.5, 0.0, 3.9), StaticPropFacing.SOUTH)
	_add_printer(Vector3(14.5, 0.0, -5.0), StaticPropFacing.WEST)
	_add_vending_machine(
		Vector3(14.5, 0.0, 5.5), Color.WHITE, StaticPropFacing.WEST
	)
	_add_vending_machine(
		Vector3(13.75, 0.0, -2.8), Color.WHITE, StaticPropFacing.SOUTH
	)
	_add_bathroom()

	_add_partition_tiles(Vector3(0.0, 0.0, -10.05), Vector2i(60, 1), 1, Color("#d7e0e8"))
	_add_partition_tiles(Vector3(0.0, 0.0, 10.05), Vector2i(60, 1), 1, Color("#d7e0e8"))
	_add_partition_tiles(Vector3(-15.05, 0.0, 0.0), Vector2i(1, 40), 1, Color("#d7e0e8"))
	_add_partition_tiles(Vector3(15.05, 0.0, 0.0), Vector2i(1, 40), 1, Color("#d7e0e8"))


func _add_cubicle(at: Vector3, opens_positive_z: bool) -> void:
	var opening_sign := 1.0 if opens_positive_z else -1.0
	var back_z := at.z - opening_sign * 1.5
	_add_partition_tiles(Vector3(at.x, 0.0, back_z), Vector2i(6, 1), 3, Color("#78909c"))
	_add_partition_tiles(Vector3(at.x - 1.5, 0.0, at.z), Vector2i(1, 6), 3, Color("#78909c"))
	_add_partition_tiles(Vector3(at.x + 1.5, 0.0, at.z), Vector2i(1, 6), 3, Color("#78909c"))
	var desk_facing := StaticPropFacing.SOUTH if opens_positive_z else StaticPropFacing.NORTH
	_add_desk(Vector3(at.x, 0.0, at.z - opening_sign * TILE_SIZE), desk_facing)
	cubicle_drop_points.append(at + Vector3(0.0, 0.0, opening_sign * TILE_SIZE * 2.0))


func _build_potions() -> void:
	for potion_position in POTION_POSITIONS:
		var potion := Node3D.new()
		potion.position = potion_position
		potion.set_meta("collected", false)
		add_child(potion)

		var glow := MeshInstance3D.new()
		var glow_mesh := CylinderMesh.new()
		glow_mesh.top_radius = 0.36
		glow_mesh.bottom_radius = 0.36
		glow_mesh.height = 0.025
		glow.mesh = glow_mesh
		glow.position.y = 0.025
		glow.material_override = _material(Color(0.35, 0.95, 1.0, 0.38), 1.0)
		potion.add_child(glow)

		_add_prop_sprite(
			potion,
			DISGUISE_POTION_TEXTURE,
			Vector3(0.0, 0.43, 0.0),
			Vector2(0.72, 0.86)
		)
		potions.append(potion)


func _collect_nearby_potion() -> void:
	for potion in potions:
		if not potion.get_meta("collected", false) \
				and player.global_position.distance_to(potion.global_position) < 0.7:
			potion.visible = false
			potion.set_meta("collected", true)
			hidden_time = minf(HIDDEN_TIME_MAX, hidden_time + POTION_REFILL)
			_play_sfx(SFX_POTION_PICKUP)
			_update_hidden_time_hud()
			return


func _add_desk(at: Vector3, facing: StaticPropFacing) -> void:
	_add_oriented_static_prop(
		at, WORKSTATION_TILES, WORKSTATION_TEXTURE, "workstation", facing
	)


func _add_partition_tiles(
	at: Vector3,
	footprint_tiles: Vector2i,
	height_tiles: int,
	color := Color("#607d8b")
) -> void:
	assert(footprint_tiles.x == 1 or footprint_tiles.y == 1)
	assert(height_tiles > 0)
	var size := Vector3(
		footprint_tiles.x * TILE_SIZE if footprint_tiles.x > 1 else DIVIDER_THICKNESS,
		height_tiles * TILE_SIZE,
		footprint_tiles.y * TILE_SIZE if footprint_tiles.y > 1 else DIVIDER_THICKNESS
	)
	var body := StaticBody3D.new()
	body.position = at
	body.set_meta("tile_footprint", footprint_tiles)
	body.set_meta("tile_height", height_tiles)
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	body.add_child(collision)
	var long_on_x := size.x > size.z
	if size.y > 0.75:
		# Preserve the original axis-aware cubicle geometry. A billboarded divider
		# makes every wall face the camera and visually destroys north/south runs.
		_add_box_mesh(body, size, Vector3(0.0, size.y * 0.5, 0.0), color)
		if long_on_x:
			_add_divider_face(body, size)
	else:
		_add_box_mesh(body, size, Vector3(0.0, size.y * 0.5, 0.0), color)


func _add_divider_face(body: StaticBody3D, size: Vector3) -> void:
	var face := Sprite3D.new()
	face.texture = DIVIDER_TEXTURE
	face.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	face.double_sided = true
	face.position = Vector3(0.0, size.y * 0.5, size.z * 0.5 + 0.006)
	face.pixel_size = 0.001
	face.scale = Vector3(
		size.x / (float(DIVIDER_TEXTURE.get_width()) * face.pixel_size),
		size.y / (float(DIVIDER_TEXTURE.get_height()) * face.pixel_size),
		1.0
	)
	body.add_child(face)


func _add_cabinet(
	at: Vector3, facing: StaticPropFacing, render_priority := 0
) -> void:
	var body := _add_oriented_static_prop(
		at, FILING_CABINET_TILES, FILING_CABINET_TEXTURE, "filing-cabinet", facing
	)
	var sprite := body.get_child(body.get_child_count() - 1) as Sprite3D
	sprite.render_priority = render_priority


func _add_cabinet_stack(
	x: float, center_z: float, count: int, facing: StaticPropFacing
) -> void:
	assert(count > 0)
	var first_z := center_z - FILING_CABINET_STACK_STRIDE * float(count - 1) * 0.5
	for index in count:
		var cabinet_z := first_z + FILING_CABINET_STACK_STRIDE * index
		# The camera sits on positive Z, so increasing Z is foreground. Explicit
		# priority keeps that occlusion deterministic for transparent billboards.
		_add_cabinet(Vector3(x, 0.0, cabinet_z), facing, index)


func _add_plant(at: Vector3) -> void:
	_add_static_prop(at, OFFICE_PLANT_TILES, OFFICE_PLANT_TEXTURE)


func _add_printer(at: Vector3, facing: StaticPropFacing) -> void:
	_add_oriented_static_prop(
		at, OFFICE_PRINTER_TILES, OFFICE_PRINTER_TEXTURE, "office-printer", facing
	)


func _add_vending_machine(
	at: Vector3, tint: Color, facing: StaticPropFacing
) -> void:
	var body := _add_oriented_static_prop(
		at, VENDING_MACHINE_TILES, VENDING_MACHINE_TEXTURE, "vending-machine", facing
	)
	var sprite := body.get_child(body.get_child_count() - 1) as Sprite3D
	sprite.modulate = tint


func _add_bathroom() -> void:
	# The bathroom gets washable vinyl over the room carpet. It sits slightly
	# above the room flooring so the two planes do not flicker in the browser.
	_add_floor_zone(
		Vector3(-12.75, 0.0, -8.25),
		Vector2(4.5, 3.5),
		FLOOR_VINYL_CHARCOAL,
		2.0,
		0.014
	)

	# The outer level walls form the north and west edges. A centred east-side
	# doorway opens into the aisle between the sink and three toilet stalls.
	_add_partition_tiles(Vector3(-12.75, 0.0, -6.5), Vector2i(9, 1), 3, Color("#86a9ac"))
	_add_partition_tiles(Vector3(-10.5, 0.0, -9.5), Vector2i(1, 2), 3, Color("#86a9ac"))
	_add_partition_tiles(Vector3(-10.5, 0.0, -7.0), Vector2i(1, 2), 3, Color("#86a9ac"))

	# Keep the vanity parallel to, and just clear of, the north perimeter wall.
	_add_oriented_static_prop(
		Vector3(-12.75, 0.0, -9.3),
		BATHROOM_SINKS_TILES,
		BATHROOM_SINKS_TEXTURE,
		"bathroom-sinks",
		StaticPropFacing.SOUTH
	)

	# Full-depth side panels separate the three stalls; their open fronts face
	# the aisle so each fixture and the nearby potion remain readable.
	_add_partition_tiles(Vector3(-13.5, 0.0, -7.25), Vector2i(1, 3), 3, Color("#9ab9bb"))
	_add_partition_tiles(Vector3(-12.0, 0.0, -7.25), Vector2i(1, 3), 3, Color("#9ab9bb"))
	for toilet_x in [-14.25, -12.75, -11.25]:
		_add_oriented_static_prop(
			Vector3(toilet_x, 0.0, -7.1),
			BATHROOM_TOILET_TILES,
			BATHROOM_TOILET_TEXTURE,
			"bathroom-toilet",
			StaticPropFacing.NORTH
		)


func _add_static_prop(
	at: Vector3,
	size_tiles: Vector3i,
	texture: Texture2D,
	rotate_footprint := false
) -> StaticBody3D:
	assert(size_tiles.x > 0 and size_tiles.y > 0 and size_tiles.z > 0)
	var footprint_tiles := _prop_footprint_tiles(size_tiles, rotate_footprint)
	var collision_size := _prop_collision_size(footprint_tiles, size_tiles.y)
	var visible_size := _projected_prop_size(size_tiles)
	var body := StaticBody3D.new()
	body.position = at
	body.set_meta("tile_size", size_tiles)
	# Layout and adjacency use only the contact area on the floor. The illustrated
	# height remains free to overlap the transparent upper area of nearby props.
	body.set_meta("tile_footprint", footprint_tiles)
	body.set_meta("tile_height", size_tiles.y)
	body.set_meta("footprint_rotated", rotate_footprint)
	body.collision_layer = 2
	body.collision_mask = 0
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.shape = shape
	collision.position.y = collision_size.y * 0.5
	body.add_child(collision)
	_add_prop_sprite(body, texture, Vector3(0.0, visible_size.y * 0.5, 0.0), visible_size)
	return body


func _add_directional_static_prop(
	at: Vector3,
	size_tiles: Vector3i,
	directional_textures: Array[Texture2D],
	facing: StaticPropFacing
) -> StaticBody3D:
	# Billboard yaw is camera-controlled, so cardinal facing comes from artwork
	# drawn for that view. Texture order matches SOUTH, EAST, NORTH, WEST above.
	assert(directional_textures.size() == 4)
	var quarter_turns := int(facing)
	var oriented_tiles := size_tiles
	if quarter_turns % 2 == 1:
		oriented_tiles = Vector3i(size_tiles.z, size_tiles.y, size_tiles.x)
	var body := _add_static_prop(
		at,
		oriented_tiles,
		directional_textures[quarter_turns]
	)
	body.set_meta("source_tile_size", size_tiles)
	body.set_meta("prop_facing", quarter_turns)
	return body


func _add_oriented_static_prop(
	at: Vector3,
	size_tiles: Vector3i,
	south_texture: Texture2D,
	asset_name: String,
	facing: StaticPropFacing
) -> StaticBody3D:
	var directional_textures := _load_directional_prop_textures(asset_name, south_texture)
	if directional_textures.size() == 4:
		return _add_directional_static_prop(at, size_tiles, directional_textures, facing)
	# Preserve the legacy footprint and undistorted south-facing art until the
	# complete generated rotation set has been installed.
	return _add_static_prop(
		at,
		size_tiles,
		south_texture,
		int(facing) % 2 == 1
	)


func _load_directional_prop_textures(
	asset_name: String, south_texture: Texture2D
) -> Array[Texture2D]:
	var textures: Array[Texture2D] = [south_texture]
	for direction in ["east", "north", "west"]:
		var path := "res://assets/scenery/generated/%s-%s.png" % [asset_name, direction]
		if not ResourceLoader.exists(path):
			return []
		var texture := load(path) as Texture2D
		if texture == null:
			return []
		textures.append(texture)
	return textures


func _prop_footprint_tiles(size_tiles: Vector3i, rotate_footprint: bool) -> Vector2i:
	var footprint := Vector2i(size_tiles.x, size_tiles.z)
	if rotate_footprint:
		footprint = Vector2i(footprint.y, footprint.x)
	return footprint


func _prop_collision_size(footprint_tiles: Vector2i, height_tiles: int) -> Vector3:
	# Collision rises from the base footprint, but its height never contributes to
	# row spacing. This keeps tall cabinets and machines tileable by their feet.
	return Vector3(
		footprint_tiles.x * TILE_SIZE,
		height_tiles * TILE_SIZE,
		footprint_tiles.y * TILE_SIZE
	)


func _projected_prop_size(size_tiles: Vector3i) -> Vector2:
	# Map physical height and depth into the billboard plane using the exact
	# camera pitch. This keeps a deep toilet, shallow cabinet, and tall vending
	# machine on one consistent orthographic projection instead of eye-sized art.
	var pitch_length := Vector2(CAMERA_OFFSET.y, CAMERA_OFFSET.z).length()
	var projected_height := (
		size_tiles.y * TILE_SIZE * CAMERA_OFFSET.z / pitch_length
		+ size_tiles.z * TILE_SIZE * CAMERA_OFFSET.y / pitch_length
	)
	return Vector2(size_tiles.x * TILE_SIZE, projected_height)


func _add_exit() -> void:
	_add_floor_marker(EXIT_POSITION, Color(0.2, 1.0, 0.48, 0.48))
	_add_exit_sign(EXIT_POSITION)


func _add_exit_sign(at: Vector3) -> void:
	var exit_post := Node3D.new()
	exit_post.position = at + Vector3(0.0, 0.0, -0.35)
	add_child(exit_post)
	_add_prop_sprite(
		exit_post, EXIT_SIGN_TEXTURE, Vector3(0.0, 0.82, 0.0), Vector2(1.8, 1.65)
	)


func _add_floor_marker(at: Vector3, color: Color) -> void:
	var outline := MeshInstance3D.new()
	var outline_mesh := CylinderMesh.new()
	outline_mesh.top_radius = 0.79
	outline_mesh.bottom_radius = 0.79
	outline_mesh.height = 0.018
	outline_mesh.radial_segments = 20
	outline.mesh = outline_mesh
	outline.position = at + Vector3(0.0, 0.015, 0.0)
	outline.material_override = _material(PROP_INK, 1.0)
	add_child(outline)
	var marker := MeshInstance3D.new()
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.72
	marker_mesh.bottom_radius = 0.72
	marker_mesh.height = 0.025
	marker_mesh.radial_segments = 20
	marker.mesh = marker_mesh
	marker.position = at + Vector3(0.0, 0.02, 0.0)
	marker.material_override = _material(color, 1.0)
	add_child(marker)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Briefcase"
	player.position = START_POSITION
	player.collision_layer = 1
	player.collision_mask = 3
	add_child(player)

	player_collision = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 0.82
	player_collision.shape = shape
	player_collision.position.y = 0.42
	player.add_child(player_collision)

	player_sprite = AnimatedSprite3D.new()
	player_sprite.name = "AnimatedBriefcase"
	player_sprite.sprite_frames = _create_briefcase_sprite_frames()
	player_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player_sprite.position.y = 0.69
	player_sprite.pixel_size = BRIEFCASE_SPRITE_PIXEL_SIZE
	player_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	player.add_child(player_sprite)
	player_sprite.play(&"idle_s")
	player_sprite.visible = false

	hidden_sprite = Sprite3D.new()
	hidden_sprite.name = "HiddenBriefcase"
	hidden_sprite.texture = HIDDEN_BRIEFCASE_TEXTURE
	hidden_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hidden_sprite.position.y = 0.69
	hidden_sprite.pixel_size = BRIEFCASE_SPRITE_PIXEL_SIZE
	hidden_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	hidden_sprite.visible = true
	player.add_child(hidden_sprite)


func _set_hidden_mode(to_hidden: bool) -> void:
	if to_hidden and hidden_time <= 0.0:
		return
	if hidden_mode == to_hidden:
		return
	if not to_hidden:
		starting_disguise = false

	_play_sfx(SFX_DISGUISE_ON if to_hidden else SFX_DISGUISE_OFF)
	hidden_mode = to_hidden
	_update_hidden_time_hud()
	is_transforming = true
	if transformation_tween and transformation_tween.is_valid():
		transformation_tween.kill()

	player_sprite.visible = true
	hidden_sprite.visible = true
	if to_hidden:
		hidden_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
		hidden_sprite.scale = Vector3(1.15, 0.72, 1.0)
	else:
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
		player_sprite.scale = Vector3(1.15, 0.72, 1.0)

	transformation_tween = create_tween().set_parallel(true)
	transformation_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	transformation_tween.tween_property(player_sprite, "modulate:a", 0.0 if to_hidden else 1.0, TRANSFORM_TIME)
	transformation_tween.tween_property(player_sprite, "scale", Vector3.ONE, TRANSFORM_TIME)
	transformation_tween.tween_property(hidden_sprite, "modulate:a", 1.0 if to_hidden else 0.0, TRANSFORM_TIME)
	transformation_tween.tween_property(hidden_sprite, "scale", Vector3.ONE, TRANSFORM_TIME)
	transformation_tween.finished.connect(_finish_transform_animation.bind(to_hidden))


func _finish_transform_animation(to_hidden: bool) -> void:
	player_sprite.visible = not to_hidden
	hidden_sprite.visible = to_hidden
	player_sprite.modulate = Color.WHITE
	hidden_sprite.modulate = Color.WHITE
	player_sprite.scale = Vector3.ONE
	hidden_sprite.scale = Vector3.ONE
	is_transforming = false
	if opening_animation_active and not to_hidden:
		opening_animation_active = false
		pause_controller.input_enabled = true


func _create_briefcase_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for row in BRIEFCASE_DIRECTIONS.size():
		var direction: StringName = BRIEFCASE_DIRECTIONS[row]
		var idle_name := StringName("idle_%s" % direction)
		var walk_name := StringName("walk_%s" % direction)
		frames.add_animation(idle_name)
		frames.set_animation_loop(idle_name, false)
		frames.add_animation(walk_name)
		frames.set_animation_loop(walk_name, true)
		frames.set_animation_speed(walk_name, BRIEFCASE_WALK_FPS)

		for column in 5:
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = BRIEFCASE_ATLAS
			atlas_frame.region = Rect2(
				Vector2(column, row) * BRIEFCASE_FRAME_SIZE,
				BRIEFCASE_FRAME_SIZE
			)
			if column == 0:
				frames.add_frame(idle_name, atlas_frame)
			else:
				frames.add_frame(walk_name, atlas_frame)

	return frames


func _build_workers() -> void:
	_validate_worker_room_coverage()
	for i in worker_routes.size():
		_add_worker(worker_routes[i], WORKER_ATLASES[i])


func _validate_worker_room_coverage() -> void:
	assert(worker_routes.size() == WORKER_ATLASES.size())
	var staffed_rooms := {}
	for route in worker_routes:
		assert(route.size() >= 2)
		var route_length := 0.0
		for point_index in route.size():
			var point := route[point_index]
			var next_point := route[(point_index + 1) % route.size()]
			var segment := next_point - point
			assert(
				is_zero_approx(segment.x) or is_zero_approx(segment.z),
				"Worker patrol legs must remain cardinal."
			)
			route_length += segment.length()
			staffed_rooms[_room_for_position(point)] = true
		assert(route_length >= 20.0, "Worker patrol routes must use long loops.")
	assert(staffed_rooms.size() == 6, "Worker patrols must visit every office room.")


func _room_for_position(position: Vector3) -> Vector2i:
	var column := 0 if position.x < 0.0 else 1
	var row := 0
	if position.z > 3.33:
		row = 2
	elif position.z >= -3.33:
		row = 1
	return Vector2i(column, row)


func _add_worker(route: PackedVector3Array, atlas: Texture2D) -> void:
	var body := CharacterBody3D.new()
	body.position = route[0]
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.55
	collision.shape = shape
	collision.position.y = 0.8
	body.add_child(collision)

	var sprite := AnimatedSprite3D.new()
	sprite.name = "AnimatedWorker"
	sprite.sprite_frames = WorkerFrames.create(atlas)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# The cartoon workers have broad, oversized heads, so a slightly smaller
	# footprint keeps them from overpowering the office furniture. The source
	# frames are almost fully occupied; this offset keeps their shadow grounded.
	sprite.position.y = 0.75
	sprite.pixel_size = WORKER_SPRITE_PIXEL_SIZE
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	body.add_child(sprite)

	var cone := _create_vision_cone()
	body.add_child(cone)
	var direction := (route[1] - route[0]).normalized()
	body.rotation.y = atan2(-direction.x, -direction.z)
	var worker := {
		"body": body,
		"route": route,
		"index": 1,
		"cone": cone,
		"vision_enabled": true,
		"sprite": sprite,
		"facing": _worker_direction_name(direction),
		"state": &"walk",
		"returning": false,
		"return_route": PackedVector3Array(),
		"return_route_index": 0,
		"resume_index": 1,
	}
	workers.append(worker)
	_set_worker_animation(worker, &"walk", direction)


func _set_worker_animation(worker: Dictionary, state: StringName, direction := Vector3.ZERO) -> void:
	if direction.length_squared() > 0.001:
		worker["facing"] = _worker_direction_name(direction)
	worker["state"] = state
	var sprite: AnimatedSprite3D = worker["sprite"]
	var animation_name := StringName("%s_%s" % [state, worker["facing"]])
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func _worker_direction_name(direction: Vector3) -> StringName:
	if absf(direction.x) > absf(direction.z):
		return &"e" if direction.x > 0.0 else &"w"
	return &"s" if direction.z > 0.0 else &"n"


func _create_vision_cone() -> MeshInstance3D:
	var cone := MeshInstance3D.new()
	cone.mesh = ArrayMesh.new()
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cone_material := _material(Color(1.0, 0.78, 0.18, 0.27), 1.0)
	cone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = cone_material
	var distances := PackedFloat32Array()
	distances.resize(VISION_RAY_COUNT)
	distances.fill(VISION_RANGE)
	_write_vision_cone_mesh(cone, distances)
	return cone


func _update_vision_cone(worker: Dictionary) -> void:
	var body: CharacterBody3D = worker["body"]
	var cone: MeshInstance3D = worker["cone"]
	var origin := body.global_position + Vector3(0.0, 0.45, 0.0)
	var distances := PackedFloat32Array()
	distances.resize(VISION_RAY_COUNT)

	for i in VISION_RAY_COUNT:
		var ratio := float(i) / float(VISION_RAY_COUNT - 1)
		var angle := lerpf(-VISION_HALF_ANGLE, VISION_HALF_ANGLE, ratio)
		var local_direction := Vector3(sin(angle), 0.0, -cos(angle))
		var world_direction := body.global_transform.basis * local_direction
		var query := PhysicsRayQueryParameters3D.create(origin, origin + world_direction * VISION_RANGE, 2)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		distances[i] = VISION_RANGE if hit.is_empty() else origin.distance_to(hit["position"])

	_write_vision_cone_mesh(cone, distances)


func _write_vision_cone_mesh(cone: MeshInstance3D, distances: PackedFloat32Array) -> void:
	var vertices := PackedVector3Array([Vector3(0.0, 0.035, -0.16)])
	for i in VISION_RAY_COUNT:
		var ratio := float(i) / float(VISION_RAY_COUNT - 1)
		var angle := lerpf(-VISION_HALF_ANGLE, VISION_HALF_ANGLE, ratio)
		vertices.append(Vector3(sin(angle) * distances[i], 0.035, -cos(angle) * distances[i]))

	var indices := PackedInt32Array()
	for i in range(1, VISION_RAY_COUNT):
		indices.append_array(PackedInt32Array([0, i, i + 1]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var cone_mesh: ArrayMesh = cone.mesh
	cone_mesh.clear_surfaces()
	cone_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "TopDownCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	add_child(camera)
	camera.current = true
	_snap_camera_to_player()


func _update_camera(delta: float) -> void:
	var desired_focus := _camera_focus()
	var current_focus := camera.position - CAMERA_OFFSET
	var focus_offset := desired_focus - current_focus
	var smoothing := 1.0 - exp(-6.0 * delta)
	if focus_offset.length_squared() > 0.0001:
		# Smooth the complete offset so the camera eases cleanly through turns.
		current_focus += focus_offset * smoothing
	else:
		current_focus = desired_focus

	camera.position = current_focus + CAMERA_OFFSET
	# Always look along CAMERA_OFFSET. Looking directly at the unsmoothed player
	# focus while the camera position was still easing caused the view to wobble.
	camera.look_at(current_focus, Vector3.UP)


func _snap_camera_to_player() -> void:
	var focus := _camera_focus()
	camera.position = focus + CAMERA_OFFSET
	camera.look_at(focus, Vector3.UP)


func _camera_focus() -> Vector3:
	var focus := player.position
	if not carrying_worker.is_empty():
		var carrying_body: CharacterBody3D = carrying_worker["body"]
		focus = carrying_body.position
	# Carrying raises the briefcase visually, but the camera should continue to
	# track its floor position so pickup and drop-off do not bump the view.
	focus.y = 0.0
	# Keep the camera near the floor bounds while allowing the briefcase to move
	# toward the edge of the viewport at the start and exit. The pitched view
	# needs extra travel toward negative Z so the tops of north-wall scenery stay
	# below the top HUD instead of being clipped or covered there.
	focus.x = clampf(focus.x, -CAMERA_FOCUS_X_LIMIT, CAMERA_FOCUS_X_LIMIT)
	focus.z = clampf(focus.z, CAMERA_FOCUS_MIN_Z, CAMERA_FOCUS_MAX_Z)
	return focus


func _build_hud() -> void:
	gameplay_hud = CanvasLayer.new()
	add_child(gameplay_hud)
	pause_controller = PauseController.new()
	add_child(pause_controller)
	result_screen = ResultScreen.new()
	add_child(result_screen)

	var disguise_panel := PanelContainer.new()
	disguise_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	disguise_panel.position = Vector2(-180.0, 18.0)
	disguise_panel.size = Vector2(360.0, 62.0)
	disguise_panel_style = StyleBoxFlat.new()
	disguise_panel_style.bg_color = Color("#18262e")
	disguise_panel_style.border_color = Color("#6f8089")
	disguise_panel_style.set_border_width_all(3)
	disguise_panel_style.corner_radius_top_left = 8
	disguise_panel_style.corner_radius_top_right = 8
	disguise_panel_style.corner_radius_bottom_left = 8
	disguise_panel_style.corner_radius_bottom_right = 8
	disguise_panel_style.content_margin_left = 10.0
	disguise_panel_style.content_margin_right = 10.0
	disguise_panel_style.content_margin_top = 6.0
	disguise_panel_style.content_margin_bottom = 8.0
	disguise_panel.add_theme_stylebox_override("panel", disguise_panel_style)
	gameplay_hud.add_child(disguise_panel)

	var disguise_copy := VBoxContainer.new()
	disguise_copy.add_theme_constant_override("separation", 4)
	disguise_panel.add_child(disguise_copy)
	var disguise_header := HBoxContainer.new()
	disguise_header.add_theme_constant_override("separation", 8)
	disguise_copy.add_child(disguise_header)
	hidden_time_label = Label.new()
	hidden_time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hidden_time_label.add_theme_font_size_override("font_size", 13)
	hidden_time_label.add_theme_color_override("font_color", Color("#dce7e3"))
	disguise_header.add_child(hidden_time_label)
	hidden_time_seconds_label = Label.new()
	hidden_time_seconds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hidden_time_seconds_label.add_theme_font_size_override("font_size", 13)
	hidden_time_seconds_label.add_theme_color_override("font_color", Color("#dce7e3"))
	disguise_header.add_child(hidden_time_seconds_label)
	hidden_time_bar = ProgressBar.new()
	hidden_time_bar.min_value = 0.0
	hidden_time_bar.max_value = HIDDEN_TIME_MAX
	hidden_time_bar.show_percentage = false
	hidden_time_bar.custom_minimum_size = Vector2(334.0, 15.0)
	hidden_time_bar_background = StyleBoxFlat.new()
	hidden_time_bar_background.bg_color = Color("#354650")
	hidden_time_bar_background.border_color = Color("#0c151a")
	hidden_time_bar_background.set_border_width_all(2)
	hidden_time_bar_background.corner_radius_top_left = 3
	hidden_time_bar_background.corner_radius_top_right = 3
	hidden_time_bar_background.corner_radius_bottom_left = 3
	hidden_time_bar_background.corner_radius_bottom_right = 3
	hidden_time_bar_fill = StyleBoxFlat.new()
	hidden_time_bar_fill.bg_color = Color("#d9b65e")
	hidden_time_bar_fill.corner_radius_top_left = 2
	hidden_time_bar_fill.corner_radius_top_right = 2
	hidden_time_bar_fill.corner_radius_bottom_left = 2
	hidden_time_bar_fill.corner_radius_bottom_right = 2
	hidden_time_bar.add_theme_stylebox_override("background", hidden_time_bar_background)
	hidden_time_bar.add_theme_stylebox_override("fill", hidden_time_bar_fill)
	disguise_copy.add_child(hidden_time_bar)
	for segment_index in range(1, 10):
		var divider := ColorRect.new()
		var segment_anchor := float(segment_index) / 10.0
		divider.set_anchor(SIDE_LEFT, segment_anchor)
		divider.set_anchor(SIDE_TOP, 0.0)
		divider.set_anchor(SIDE_RIGHT, segment_anchor)
		divider.set_anchor(SIDE_BOTTOM, 1.0)
		divider.offset_left = -1.0
		divider.offset_top = 2.0
		divider.offset_right = 1.0
		divider.offset_bottom = -2.0
		divider.color = Color(0.04, 0.08, 0.09, 0.45)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hidden_time_bar.add_child(divider)

	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.position = Vector2(-150.0, 82.0)
	status_label.size = Vector2(300.0, 55.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 34)
	gameplay_hud.add_child(status_label)


func _build_audio() -> void:
	var looping_music := LEVEL_MUSIC.duplicate() as AudioStreamMP3
	looping_music.loop = true
	music_player = AudioStreamPlayer.new()
	music_player.name = "LevelMusic"
	music_player.stream = looping_music
	music_player.volume_db = -8.0
	add_child(music_player)

	var looping_office := OFFICE_AMBIENCE.duplicate() as AudioStreamMP3
	looping_office.loop = true
	office_ambience_player = AudioStreamPlayer.new()
	office_ambience_player.name = "OfficeAmbience"
	office_ambience_player.stream = looping_office
	# The field recording has substantially more headroom than the mastered
	# music. This boost keeps chatter, phones and typing present in the mix.
	office_ambience_player.volume_db = 5.0
	add_child(office_ambience_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "GameSoundEffect"
	sfx_player.volume_db = -3.0
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)

	music_player.play()


func _play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()


func _should_skip_title_screen() -> bool:
	if "--skip-title" in OS.get_cmdline_user_args():
		return true
	return OS.get_environment("BRIEFCASE_SKIP_TITLE").to_lower() in ["1", "true", "yes"]


func _show_title_screen() -> void:
	title_screen_active = true
	gameplay_hud.visible = false
	title_screen = TitleScreen.new()
	add_child(title_screen)


func _start_first_level() -> void:
	title_screen_active = false
	gameplay_hud.visible = true
	if is_instance_valid(title_screen):
		title_screen.queue_free()
	title_screen = null
	_reset_level()
	office_ambience_player.play()
	_play_sfx(SFX_GAME_START)
	_begin_opening_animation()


func _continue_from_result() -> void:
	var advancing := level_complete
	result_screen.hide_report()
	if advancing:
		floor_number += 1
	level_complete = false
	_reset_level()
	_play_sfx(SFX_GAME_START)
	_begin_opening_animation()


func _begin_opening_animation() -> void:
	opening_animation_active = true
	pause_controller.input_enabled = false
	player.velocity = Vector3.ZERO
	_set_player_animation(Vector2.ZERO)
	await get_tree().create_timer(OPENING_DISGUISE_DELAY).timeout
	if not opening_animation_active or not hidden_mode:
		return
	_set_hidden_mode(false)


func _is_start_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_START
	return false


func _update_hidden_time_hud() -> void:
	if not hidden_time_bar:
		return
	hidden_time_bar.value = hidden_time
	hidden_time_seconds_label.text = "%.1fs" % hidden_time
	hidden_time_bar.modulate = Color.WHITE
	if hidden_time <= 0.0:
		hidden_time_label.text = "DISGUISE EMPTY"
		hidden_time_label.add_theme_color_override("font_color", Color("#aab6b8"))
		hidden_time_seconds_label.add_theme_color_override("font_color", Color("#aab6b8"))
		disguise_panel_style.border_color = Color("#596870")
		hidden_time_bar_background.bg_color = Color("#26343c")
		hidden_time_bar_fill.bg_color = Color("#596870")
	elif hidden_mode:
		if not pickup_worker.is_empty() or not carrying_worker.is_empty():
			hidden_time_label.text = "DISGUISE PAUSED"
		elif drop_disguise_grace_time > 0.0:
			hidden_time_label.text = "DISGUISE FREE"
		else:
			hidden_time_label.text = "DISGUISE ACTIVE"
		hidden_time_label.add_theme_color_override("font_color", Color("#f6d885"))
		hidden_time_seconds_label.add_theme_color_override("font_color", Color("#f7f0dc"))
		disguise_panel_style.border_color = Color("#f0c76b")
		hidden_time_bar_background.bg_color = Color("#354650")
		hidden_time_bar_fill.bg_color = Color("#65d9c5")
	else:
		hidden_time_label.text = "DISGUISE READY"
		hidden_time_label.add_theme_color_override("font_color", Color("#dce7e3"))
		hidden_time_seconds_label.add_theme_color_override("font_color", Color("#dce7e3"))
		disguise_panel_style.border_color = Color("#6f8089")
		hidden_time_bar_background.bg_color = Color("#354650")
		hidden_time_bar_fill.bg_color = Color("#d9b65e")


func _add_box_mesh(parent: Node, size: Vector3, at: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color)
	parent.add_child(instance)


func _add_prop_sprite(
	parent: Node,
	texture: Texture2D,
	at: Vector3,
	visible_size: Vector2
) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position = at
	sprite.pixel_size = 0.001
	sprite.scale = Vector3(
		visible_size.x / (float(texture.get_width()) * sprite.pixel_size),
		visible_size.y / (float(texture.get_height()) * sprite.pixel_size),
		1.0
	)
	parent.add_child(sprite)


func _material(color: Color, roughness := 0.8) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
