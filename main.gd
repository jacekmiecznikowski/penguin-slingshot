extends Node3D

const LAUNCH_ORIGIN := Vector3(0.0, 2.0, 0.0)
const MAX_DRAG_PX := 240.0
const MIN_LAUNCH_POWER := 7.0
const MAX_LAUNCH_POWER := 24.0
const WORLD_LENGTH := 420.0
const SAVE_PATH := "user://progress.json"
const STARTING_COINS := 150
const UPGRADE_MAX_LEVEL := 20
const BASE_UPGRADE_COSTS := {
    "slingshot": 90,
    "sled": 120,
    "income": 140,
}
const PENGUIN_MODEL_PATHS := [
    "res://assets/penguin/penguin.glb",
    "res://assets/penguin/penguin.blend",
]
const HOLIDAY_DIR := "res://assets/kenney_holiday/"
const NATURE_DIR := "res://assets/kenney_nature/"

var penguin: RigidBody3D
var camera: Camera3D
var scenery_root: Node3D
var distance_label: Label
var coin_label: Label
var power_label: Label
var hint_label: Label
var result_panel: PanelContainer
var result_label: Label
var drag_line: Line2D
var upgrade_panel: PanelContainer
var upgrade_buttons: Dictionary = {}
var upgrade_level_labels: Dictionary = {}
var upgrade_effect_labels: Dictionary = {}
var upgrade_cost_labels: Dictionary = {}

var dragging := false
var drag_start := Vector2.ZERO
var drag_current := Vector2.ZERO
var launched := false
var flight_time := 0.0
var max_distance := 0.0
var run_finished := false
var last_reward := 0
var coins := STARTING_COINS
var upgrades := {
    "slingshot": 0,
    "sled": 0,
    "income": 0,
}

func _ready() -> void:
    _load_progress()
    _build_world()
    _build_penguin()
    _build_camera()
    _build_ui()
    _reset_run()

func _physics_process(delta: float) -> void:
    if launched and not run_finished:
        flight_time += delta
        _apply_sled_glide()
        max_distance = max(max_distance, penguin.global_position.x - LAUNCH_ORIGIN.x)
        distance_label.text = "%d m" % int(max(0.0, max_distance))
        _update_camera(delta)

        var nearly_stopped := penguin.linear_velocity.length() < 0.7
        var low_enough := penguin.global_position.y < 1.05
        if flight_time > 1.8 and (nearly_stopped and low_enough):
            _finish_run()
        elif flight_time > 22.0 or penguin.global_position.y < -10.0:
            _finish_run()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("restart"):
        _reset_run()
        return

    if run_finished:
        if event is InputEventMouseButton and event.pressed:
            _reset_run()
        elif event is InputEventScreenTouch and event.pressed:
            _reset_run()
        return

    if launched:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _start_drag(event.position)
        else:
            _release_drag(event.position)
    elif event is InputEventScreenDrag:
        if dragging:
            _update_drag(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _start_drag(event.position)
        else:
            _release_drag(event.position)
    elif event is InputEventMouseMotion and dragging:
        _update_drag(event.position)

func _start_drag(pos: Vector2) -> void:
    dragging = true
    drag_start = pos
    drag_current = pos
    hint_label.text = "Przeciągnij w dół i w lewo, potem puść"
    _refresh_drag_visual()

func _update_drag(pos: Vector2) -> void:
    drag_current = pos
    _refresh_drag_visual()

func _release_drag(pos: Vector2) -> void:
    if not dragging:
        return
    drag_current = pos
    dragging = false
    drag_line.visible = false

    var pull := drag_current - drag_start
    if pull.length() < 28.0:
        hint_label.text = "Mocniej naciągnij procę"
        power_label.text = "MOC 0%"
        return

    var normalized_pull := min(pull.length(), MAX_DRAG_PX) / MAX_DRAG_PX
    var power := lerp(MIN_LAUNCH_POWER, MAX_LAUNCH_POWER, normalized_pull)
    power *= _slingshot_multiplier()

    # Gesture direction is inverted: dragging back launches forward/up.
    var horizontal := clamp(-pull.x / MAX_DRAG_PX, 0.35, 1.0)
    var vertical := clamp(pull.y / MAX_DRAG_PX, 0.25, 1.0)
    var direction := Vector3(horizontal * 1.25, vertical * 0.85 + 0.22, 0.0).normalized()
    _launch(direction * power)

func _launch(impulse: Vector3) -> void:
    launched = true
    flight_time = 0.0
    last_reward = 0
    hint_label.text = "LEĆ, PINGWINIE!"
    power_label.text = ""
    upgrade_panel.visible = false
    _apply_upgrade_physics()
    penguin.freeze = false
    penguin.sleeping = false
    penguin.apply_central_impulse(impulse)
    penguin.apply_torque_impulse(Vector3(0.0, 0.0, -1.8))

func _apply_sled_glide() -> void:
    var level := int(upgrades.get("sled", 0))
    if level <= 0 or flight_time < 0.35:
        return

    var velocity := penguin.linear_velocity
    if velocity.x < 1.5:
        return

    # The sled/glide upgrade gently preserves forward speed and softens descents.
    # Forces are capped so the upgrade extends a launch without turning it into powered flight.
    var forward_force := min(4.0, 0.16 * float(level))
    var lift_force := 0.0
    if velocity.y < 0.0:
        lift_force = min(5.2, -velocity.y * 0.11 * float(level))
    penguin.apply_central_force(Vector3(forward_force, lift_force, 0.0))

func _finish_run() -> void:
    if run_finished:
        return
    run_finished = true
    penguin.freeze = true
    last_reward = _calculate_reward(max_distance)
    coins += last_reward
    _save_progress()
    _refresh_upgrade_ui()
    upgrade_panel.visible = true
    result_label.text = "DYSTANS: %d m\n+%d MONET\n\nRAZEM: %d\n\nDotknij poza kartami, aby lecieć ponownie" % [int(max(0.0, max_distance)), last_reward, coins]
    result_panel.visible = true
    hint_label.text = "ULEPSZ SPRZĘT ALBO LEĆ JESZCZE RAZ"

func _reset_run() -> void:
    launched = false
    run_finished = false
    dragging = false
    flight_time = 0.0
    max_distance = 0.0
    last_reward = 0
    drag_line.visible = false
    result_panel.visible = false
    upgrade_panel.visible = true
    distance_label.text = "0 m"
    power_label.text = "MOC 0%"
    hint_label.text = "DOTKNIJ I NACIĄGNIJ PROCĘ"
    _refresh_upgrade_ui()

    penguin.freeze = true
    penguin.linear_velocity = Vector3.ZERO
    penguin.angular_velocity = Vector3.ZERO
    _apply_upgrade_physics()
    penguin.global_position = LAUNCH_ORIGIN
    penguin.rotation = Vector3.ZERO
    camera.global_position = Vector3(-8.0, 7.0, 14.0)
    camera.look_at(Vector3(4.0, 2.2, 0.0), Vector3.UP)

func _refresh_drag_visual() -> void:
    var pull := drag_current - drag_start
    var ratio := min(pull.length(), MAX_DRAG_PX) / MAX_DRAG_PX
    power_label.text = "MOC %d%%" % int(ratio * 100.0)
    drag_line.clear_points()
    drag_line.add_point(drag_start)
    drag_line.add_point(drag_current)
    drag_line.visible = true

func _update_camera(delta: float) -> void:
    var target_x := max(4.0, penguin.global_position.x + 4.0)
    var desired := Vector3(target_x - 10.0, max(6.5, penguin.global_position.y + 3.0), 15.0)
    camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-3.2 * delta))
    camera.look_at(Vector3(target_x, max(1.5, penguin.global_position.y), 0.0), Vector3.UP)

func _slingshot_multiplier() -> float:
    return 1.0 + 0.075 * float(upgrades.get("slingshot", 0))

func _income_multiplier() -> float:
    return 1.0 + 0.25 * float(upgrades.get("income", 0))

func _sled_gravity_scale() -> float:
    return max(0.56, 1.0 - 0.022 * float(upgrades.get("sled", 0)))

func _apply_upgrade_physics() -> void:
    if penguin == null:
        return
    penguin.gravity_scale = _sled_gravity_scale()
    penguin.linear_damp = max(0.02, 0.08 - 0.002 * float(upgrades.get("sled", 0)))

func _calculate_reward(distance: float) -> int:
    var base_reward := max(5.0, floor(max(0.0, distance) * 1.15))
    return int(round(base_reward * _income_multiplier()))

func _upgrade_cost(key: String) -> int:
    var level := int(upgrades.get(key, 0))
    var base := float(BASE_UPGRADE_COSTS.get(key, 100))
    var raw := base * pow(1.48, float(level))
    return int(round(raw / 5.0) * 5.0)

func _on_upgrade_pressed(key: String) -> void:
    if launched and not run_finished:
        return

    var level := int(upgrades.get(key, 0))
    if level >= UPGRADE_MAX_LEVEL:
        hint_label.text = "To ulepszenie ma już maksymalny poziom"
        return

    var cost := _upgrade_cost(key)
    if coins < cost:
        hint_label.text = "Brakuje %d monet" % (cost - coins)
        return

    coins -= cost
    upgrades[key] = level + 1
    _apply_upgrade_physics()
    _save_progress()
    _refresh_upgrade_ui()
    hint_label.text = "%s → POZIOM %d" % [_upgrade_title(key), int(upgrades[key])]

func _upgrade_title(key: String) -> String:
    match key:
        "slingshot":
            return "PROCA"
        "sled":
            return "SANKI"
        "income":
            return "DOCHÓD"
    return key.to_upper()

func _upgrade_effect_text(key: String) -> String:
    var level := int(upgrades.get(key, 0))
    match key:
        "slingshot":
            return "Moc x%.2f" % _slingshot_multiplier()
        "sled":
            return "Grawitacja %.0f%%" % (_sled_gravity_scale() * 100.0)
        "income":
            return "Monety x%.2f" % _income_multiplier()
    return "Poziom %d" % level

func _refresh_upgrade_ui() -> void:
    if coin_label == null:
        return
    coin_label.text = "MONETY  %d" % coins

    for key in ["slingshot", "sled", "income"]:
        var level := int(upgrades.get(key, 0))
        var level_label := upgrade_level_labels.get(key) as Label
        var effect_label := upgrade_effect_labels.get(key) as Label
        var cost_label := upgrade_cost_labels.get(key) as Label
        var button := upgrade_buttons.get(key) as Button
        if level_label != null:
            level_label.text = "POZIOM %d/%d" % [level, UPGRADE_MAX_LEVEL]
        if effect_label != null:
            effect_label.text = _upgrade_effect_text(key)
        if cost_label != null:
            cost_label.text = "MAKSIMUM" if level >= UPGRADE_MAX_LEVEL else "%d MONET" % _upgrade_cost(key)
        if button != null:
            button.disabled = level >= UPGRADE_MAX_LEVEL
            button.text = "MAKS." if level >= UPGRADE_MAX_LEVEL else "ULEPSZ"

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return

    var data := parsed as Dictionary
    coins = max(0, int(data.get("coins", STARTING_COINS)))
    var saved_upgrades = data.get("upgrades", {})
    if saved_upgrades is Dictionary:
        var upgrade_data := saved_upgrades as Dictionary
        for key in upgrades.keys():
            upgrades[key] = clampi(int(upgrade_data.get(key, 0)), 0, UPGRADE_MAX_LEVEL)

func _save_progress() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    var data := {
        "version": 1,
        "coins": coins,
        "upgrades": upgrades.duplicate(true),
    }
    file.store_string(JSON.stringify(data))

func _build_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("a9dcf5")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("d9ecff")
    env.ambient_light_energy = 0.9
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    _add_box(Vector3(WORLD_LENGTH, 0.5, 22.0), Vector3(WORLD_LENGTH * 0.5 - 18.0, -0.35, 0.0), Color("e8f8ff"), true)

    scenery_root = Node3D.new()
    scenery_root.name = "CC0Scenery"
    add_child(scenery_root)
    _populate_cc0_scenery()
    _build_slingshot()

func _populate_cc0_scenery() -> void:
    # Lightweight decoration pass. Visual-only assets deliberately have no colliders.
    # This keeps the physics predictable and the scene cheap enough for Android.
    var starter_sled := _spawn_scenery(HOLIDAY_DIR + "sled.glb", Vector3(-3.4, 0.05, 4.0), 1.1, 18.0)
    if starter_sled == null:
        _add_pine(Vector3(-3.4, 0.0, 4.0), 1.0)
    _spawn_scenery(HOLIDAY_DIR + "snowman.glb", Vector3(4.0, 0.0, -4.7), 1.1, -12.0)
    _spawn_scenery(HOLIDAY_DIR + "bench.glb", Vector3(8.0, 0.0, 4.8), 1.0, -18.0)

    var holiday_trees := ["tree-snow-a.glb", "tree-snow-b.glb", "tree-snow-c.glb"]
    var holiday_rocks := ["rocks-small.glb", "rocks-medium.glb", "rocks-large.glb"]
    var nature_rocks := ["rock_largeA.glb", "rock_largeB.glb", "rock_largeC.glb"]

    for i in range(1, 24):
        var x := float(i) * 18.0
        var side := -1.0 if i % 2 == 0 else 1.0
        var tree_path := HOLIDAY_DIR + holiday_trees[i % holiday_trees.size()]
        var tree := _spawn_scenery(tree_path, Vector3(x + 2.5, 0.0, side * 5.1), 1.0 + float(i % 4) * 0.12, float((i * 37) % 360))
        if tree == null:
            _add_pine(Vector3(x + 2.5, 0.0, side * 5.1), 1.0 + float(i % 4) * 0.12)

        if i % 3 == 0:
            _spawn_scenery(HOLIDAY_DIR + holiday_rocks[i % holiday_rocks.size()], Vector3(x - 2.5, 0.0, -side * 4.8), 0.9 + float(i % 2) * 0.2, float((i * 19) % 360))
        elif i % 3 == 1:
            _spawn_scenery(NATURE_DIR + nature_rocks[i % nature_rocks.size()], Vector3(x - 2.0, 0.0, -side * 4.9), 1.0 + float(i % 3) * 0.15, float((i * 29) % 360))

        if i % 5 == 0:
            _spawn_scenery(HOLIDAY_DIR + "snow-pile.glb", Vector3(x + 5.0, 0.0, side * 3.7), 1.1, float((i * 11) % 360))

        # Distance marker remains a primitive so it is always visible even if assets fail to import.
        var marker_height := 0.9 + float(i % 4) * 0.3
        _add_box(Vector3(0.14, marker_height, 0.14), Vector3(x, marker_height * 0.5, -4.2), Color("7c9bb1"), false)

func _spawn_scenery(path: String, pos: Vector3, scale_factor: float = 1.0, rotation_y_degrees: float = 0.0) -> Node3D:
    if not ResourceLoader.exists(path):
        return null

    var resource := load(path)
    if not (resource is PackedScene):
        return null

    var instance := (resource as PackedScene).instantiate()
    if not (instance is Node3D):
        instance.queue_free()
        return null

    var node := instance as Node3D
    node.position = pos
    node.scale = node.scale * scale_factor
    node.rotation_degrees.y = rotation_y_degrees
    scenery_root.add_child(node)
    return node

func _build_slingshot() -> void:
    _add_box(Vector3(0.42, 2.7, 0.55), Vector3(-1.0, 1.3, 0.0), Color("8b4d2d"), false)
    _add_box(Vector3(0.42, 2.7, 0.55), Vector3(1.0, 1.3, 0.0), Color("8b4d2d"), false)
    _add_box(Vector3(2.3, 0.35, 0.35), Vector3(0.0, 2.35, 0.0), Color("5d301d"), false)

func _add_pine(pos: Vector3, scale_factor: float) -> void:
    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.12 * scale_factor
    trunk_mesh.bottom_radius = 0.16 * scale_factor
    trunk_mesh.height = 1.4 * scale_factor
    trunk.mesh = trunk_mesh
    trunk.position = pos + Vector3(0, 0.7 * scale_factor, 0)
    trunk.material_override = _mat(Color("6d4229"))
    add_child(trunk)

    for j in range(3):
        var leaves := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0.0
        cone.bottom_radius = (0.85 - j * 0.12) * scale_factor
        cone.height = 1.45 * scale_factor
        leaves.mesh = cone
        leaves.position = pos + Vector3(0, (1.25 + j * 0.62) * scale_factor, 0)
        leaves.material_override = _mat(Color("315b4a"))
        add_child(leaves)

func _build_penguin() -> void:
    penguin = RigidBody3D.new()
    penguin.name = "Penguin"
    penguin.mass = 1.15
    penguin.linear_damp = 0.08
    penguin.angular_damp = 0.5
    penguin.gravity_scale = 1.0
    penguin.continuous_cd = true
    penguin.contact_monitor = true
    penguin.max_contacts_reported = 4
    add_child(penguin)

    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.52
    capsule.height = 1.55
    collider.shape = capsule
    penguin.add_child(collider)

    if _try_add_penguin_model():
        return

    _add_penguin_placeholder()

func _try_add_penguin_model() -> bool:
    # GLB is preferred because Godot imports it natively. The supplied source model is .blend,
    # which Godot can import when Blender is installed/configured in the editor.
    for path in PENGUIN_MODEL_PATHS:
        if not ResourceLoader.exists(path):
            continue
        var resource := load(path)
        if not (resource is PackedScene):
            continue
        var instance := (resource as PackedScene).instantiate()
        if not (instance is Node3D):
            instance.queue_free()
            continue
        var model := instance as Node3D
        model.name = "PenguinModelCC0"
        model.scale = model.scale * 0.8
        model.rotation_degrees = Vector3(0.0, 90.0, 0.0)
        penguin.add_child(model)
        return true
    return false

func _add_penguin_placeholder() -> void:
    var body := MeshInstance3D.new()
    var body_mesh := SphereMesh.new()
    body_mesh.radius = 0.62
    body_mesh.height = 1.6
    body.mesh = body_mesh
    body.scale = Vector3(0.9, 1.15, 0.85)
    body.material_override = _mat(Color("16191d"))
    penguin.add_child(body)

    var belly := MeshInstance3D.new()
    var belly_mesh := SphereMesh.new()
    belly_mesh.radius = 0.48
    belly_mesh.height = 1.15
    belly.mesh = belly_mesh
    belly.position = Vector3(0.28, -0.05, 0.0)
    belly.scale = Vector3(0.55, 0.9, 0.72)
    belly.material_override = _mat(Color("f4f4ed"))
    penguin.add_child(belly)

    var beak := MeshInstance3D.new()
    var beak_mesh := PrismMesh.new()
    beak_mesh.size = Vector3(0.38, 0.22, 0.26)
    beak.mesh = beak_mesh
    beak.position = Vector3(0.57, 0.42, 0.0)
    beak.rotation_degrees = Vector3(0, 0, -90)
    beak.material_override = _mat(Color("f4a340"))
    penguin.add_child(beak)

    for side in [-1.0, 1.0]:
        var eye := MeshInstance3D.new()
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = 0.075
        eye_mesh.height = 0.15
        eye.mesh = eye_mesh
        eye.position = Vector3(0.52, 0.58, 0.18 * side)
        eye.material_override = _mat(Color("dff5ff"))
        penguin.add_child(eye)

        var pupil := MeshInstance3D.new()
        var pupil_mesh := SphereMesh.new()
        pupil_mesh.radius = 0.035
        pupil_mesh.height = 0.07
        pupil.mesh = pupil_mesh
        pupil.position = Vector3(0.585, 0.58, 0.18 * side)
        pupil.material_override = _mat(Color("151515"))
        penguin.add_child(pupil)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.fov = 46.0
    camera.current = true
    add_child(camera)

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var top := VBoxContainer.new()
    top.position = Vector2(24, 30)
    top.size = Vector2(672, 150)
    canvas.add_child(top)

    distance_label = Label.new()
    distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    distance_label.add_theme_font_size_override("font_size", 42)
    top.add_child(distance_label)

    power_label = Label.new()
    power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    power_label.add_theme_font_size_override("font_size", 22)
    top.add_child(power_label)

    coin_label = Label.new()
    coin_label.position = Vector2(470, 28)
    coin_label.size = Vector2(220, 56)
    coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    coin_label.add_theme_font_size_override("font_size", 22)
    coin_label.add_theme_color_override("font_color", Color("5f4512"))
    coin_label.add_theme_stylebox_override("normal", _ui_box(Color("ffd66b"), 18))
    canvas.add_child(coin_label)

    hint_label = Label.new()
    hint_label.position = Vector2(40, 840)
    hint_label.size = Vector2(640, 78)
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.add_theme_font_size_override("font_size", 23)
    hint_label.add_theme_color_override("font_color", Color("233547"))
    canvas.add_child(hint_label)

    drag_line = Line2D.new()
    drag_line.width = 8.0
    drag_line.default_color = Color(0.85, 0.18, 0.18, 0.85)
    drag_line.visible = false
    canvas.add_child(drag_line)

    result_panel = PanelContainer.new()
    result_panel.position = Vector2(95, 360)
    result_panel.size = Vector2(530, 300)
    result_panel.add_theme_stylebox_override("panel", _ui_box(Color(0.93, 0.98, 1.0, 0.96), 24))
    canvas.add_child(result_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    result_panel.add_child(margin)

    result_label = Label.new()
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_label.add_theme_font_size_override("font_size", 25)
    result_label.add_theme_color_override("font_color", Color("183042"))
    margin.add_child(result_label)

    _build_upgrade_panel(canvas)

func _build_upgrade_panel(canvas: CanvasLayer) -> void:
    upgrade_panel = PanelContainer.new()
    upgrade_panel.position = Vector2(24, 930)
    upgrade_panel.size = Vector2(672, 326)
    upgrade_panel.add_theme_stylebox_override("panel", _ui_box(Color(0.45, 0.64, 0.76, 0.93), 24))
    canvas.add_child(upgrade_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    upgrade_panel.add_child(margin)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(grid)

    _create_upgrade_card(grid, "slingshot", "PROCA", "Mocniejszy start", Color("e95f72"))
    _create_upgrade_card(grid, "sled", "SANKI", "Dłuższe szybowanie", Color("40b9df"))
    _create_upgrade_card(grid, "income", "DOCHÓD", "Więcej monet", Color("f4c252"))

func _create_upgrade_card(parent: GridContainer, key: String, title: String, description: String, accent: Color) -> void:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(210, 292)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel", _ui_box(Color(0.88, 0.95, 0.98, 0.96), 18))
    parent.add_child(card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 10)
    card.add_child(margin)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 5)
    margin.add_child(box)

    var title_label := Label.new()
    title_label.text = title
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 22)
    title_label.add_theme_color_override("font_color", Color("213646"))
    box.add_child(title_label)

    var description_label := Label.new()
    description_label.text = description
    description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description_label.add_theme_font_size_override("font_size", 14)
    description_label.add_theme_color_override("font_color", Color("546d7c"))
    box.add_child(description_label)

    var level_label := Label.new()
    level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    level_label.add_theme_font_size_override("font_size", 16)
    level_label.add_theme_color_override("font_color", accent.darkened(0.28))
    box.add_child(level_label)
    upgrade_level_labels[key] = level_label

    var effect_label := Label.new()
    effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    effect_label.add_theme_font_size_override("font_size", 16)
    effect_label.add_theme_color_override("font_color", Color("29495e"))
    box.add_child(effect_label)
    upgrade_effect_labels[key] = effect_label

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(1, 22)
    box.add_child(spacer)

    var cost_label := Label.new()
    cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cost_label.add_theme_font_size_override("font_size", 16)
    cost_label.add_theme_color_override("font_color", Color("735316"))
    box.add_child(cost_label)
    upgrade_cost_labels[key] = cost_label

    var button := Button.new()
    button.custom_minimum_size = Vector2(180, 58)
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", Color("ffffff"))
    button.add_theme_stylebox_override("normal", _ui_box(accent, 14))
    button.add_theme_stylebox_override("hover", _ui_box(accent.lightened(0.08), 14))
    button.add_theme_stylebox_override("pressed", _ui_box(accent.darkened(0.12), 14))
    button.pressed.connect(_on_upgrade_pressed.bind(key))
    box.add_child(button)
    upgrade_buttons[key] = button

func _ui_box(color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 8.0
    style.content_margin_right = 8.0
    style.content_margin_top = 6.0
    style.content_margin_bottom = 6.0
    return style

func _add_box(size: Vector3, pos: Vector3, color: Color, collider: bool) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.material_override = _mat(color)
    add_child(mesh_instance)

    if collider:
        var static_body := StaticBody3D.new()
        static_body.position = pos
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        static_body.add_child(shape_node)
        add_child(static_body)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.82
    return material
