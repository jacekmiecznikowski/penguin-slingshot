extends Node3D

const LAUNCH_ORIGIN := Vector3(0, 2, 0)
const MAX_DRAG := 240.0
const HOLIDAY := "res://assets/kenney_holiday/"
const NATURE := "res://assets/kenney_nature/"

var penguin: RigidBody3D
var camera: Camera3D
var scenery: Node3D
var distance_label: Label
var power_label: Label
var hint_label: Label
var result_panel: PanelContainer
var result_label: Label
var drag_line: Line2D
var dragging := false
var launched := false
var finished := false
var drag_start := Vector2.ZERO
var drag_current := Vector2.ZERO
var flight_time := 0.0
var max_distance := 0.0

func _ready() -> void:
    _build_world()
    _build_penguin()
    _build_camera()
    _build_ui()
    _reset_run()

func _physics_process(delta: float) -> void:
    if not launched or finished:
        return
    flight_time += delta
    max_distance = max(max_distance, penguin.global_position.x)
    distance_label.text = "%d m" % int(max_distance)
    _update_camera(delta)
    if flight_time > 1.8 and penguin.linear_velocity.length() < 0.7 and penguin.global_position.y < 1.05:
        _finish_run()
    elif flight_time > 18.0 or penguin.global_position.y < -10.0:
        _finish_run()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("restart"):
        _reset_run()
        return
    if finished:
        if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
            _reset_run()
        return
    if launched:
        return
    if event is InputEventScreenTouch:
        if event.pressed: _start_drag(event.position)
        else: _release_drag(event.position)
    elif event is InputEventScreenDrag and dragging:
        _update_drag(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed: _start_drag(event.position)
        else: _release_drag(event.position)
    elif event is InputEventMouseMotion and dragging:
        _update_drag(event.position)

func _start_drag(pos: Vector2) -> void:
    dragging = true
    drag_start = pos
    drag_current = pos
    hint_label.text = "Przeciągnij w dół i w lewo, potem puść"
    _refresh_drag()

func _update_drag(pos: Vector2) -> void:
    drag_current = pos
    _refresh_drag()

func _release_drag(pos: Vector2) -> void:
    if not dragging: return
    dragging = false
    drag_current = pos
    drag_line.visible = false
    var pull := drag_current - drag_start
    if pull.length() < 28.0:
        hint_label.text = "Mocniej naciągnij procę"
        return
    var ratio := min(pull.length(), MAX_DRAG) / MAX_DRAG
    var power := lerp(7.0, 24.0, ratio)
    var direction := Vector3(clamp(-pull.x / MAX_DRAG, .35, 1.0) * 1.25, clamp(pull.y / MAX_DRAG, .25, 1.0) * .85 + .22, 0).normalized()
    launched = true
    flight_time = 0.0
    hint_label.text = "LEĆ, PINGWINIE!"
    power_label.text = ""
    penguin.freeze = false
    penguin.apply_central_impulse(direction * power)
    penguin.apply_torque_impulse(Vector3(0, 0, -1.8))

func _refresh_drag() -> void:
    var ratio := min((drag_current - drag_start).length(), MAX_DRAG) / MAX_DRAG
    power_label.text = "MOC %d%%" % int(ratio * 100.0)
    drag_line.clear_points()
    drag_line.add_point(drag_start)
    drag_line.add_point(drag_current)
    drag_line.visible = true

func _finish_run() -> void:
    finished = true
    penguin.freeze = true
    result_label.text = "DYSTANS: %d m\n\nDotknij ekranu, aby spróbować ponownie" % int(max_distance)
    result_panel.visible = true
    hint_label.text = ""

func _reset_run() -> void:
    launched = false
    finished = false
    dragging = false
    flight_time = 0.0
    max_distance = 0.0
    drag_line.visible = false
    result_panel.visible = false
    distance_label.text = "0 m"
    power_label.text = "MOC 0%"
    hint_label.text = "DOTKNIJ I NACIĄGNIJ PROCĘ"
    penguin.freeze = true
    penguin.linear_velocity = Vector3.ZERO
    penguin.angular_velocity = Vector3.ZERO
    penguin.global_position = LAUNCH_ORIGIN
    penguin.rotation = Vector3.ZERO
    camera.global_position = Vector3(-8, 7, 14)
    camera.look_at(Vector3(4, 2.2, 0), Vector3.UP)

func _update_camera(delta: float) -> void:
    var target_x := max(4.0, penguin.global_position.x + 4.0)
    var desired := Vector3(target_x - 10.0, max(6.5, penguin.global_position.y + 3.0), 15)
    camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-3.2 * delta))
    camera.look_at(Vector3(target_x, max(1.5, penguin.global_position.y), 0), Vector3.UP)

func _build_world() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("a9dcf5")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("d9ecff")
    env.ambient_light_energy = .9
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)
    _add_box(Vector3(420, .5, 22), Vector3(192, -.35, 0), Color("e8f8ff"), true)
    scenery = Node3D.new()
    add_child(scenery)
    _populate_scenery()
    _add_box(Vector3(.42, 2.7, .55), Vector3(-1, 1.3, 0), Color("8b4d2d"), false)
    _add_box(Vector3(.42, 2.7, .55), Vector3(1, 1.3, 0), Color("8b4d2d"), false)
    _add_box(Vector3(2.3, .35, .35), Vector3(0, 2.35, 0), Color("5d301d"), false)

func _populate_scenery() -> void:
    _spawn(HOLIDAY + "sled.glb", Vector3(-3.4, .05, 4), 1.1)
    _spawn(HOLIDAY + "snowman.glb", Vector3(4, 0, -4.7), 1.1)
    _spawn(HOLIDAY + "bench.glb", Vector3(8, 0, 4.8), 1.0)
    var trees := ["tree-snow-a.glb", "tree-snow-b.glb", "tree-snow-c.glb"]
    var rocks := ["rocks-small.glb", "rocks-medium.glb", "rocks-large.glb"]
    var nature_rocks := ["rock_largeA.glb", "rock_largeB.glb", "rock_largeC.glb"]
    for i in range(1, 24):
        var x := float(i) * 18.0
        var side := -1.0 if i % 2 == 0 else 1.0
        _spawn(HOLIDAY + trees[i % 3], Vector3(x + 2.5, 0, side * 5.1), 1.0 + float(i % 4) * .12)
        if i % 3 == 0: _spawn(HOLIDAY + rocks[i % 3], Vector3(x - 2.5, 0, -side * 4.8), 1.0)
        else: _spawn(NATURE + nature_rocks[i % 3], Vector3(x - 2, 0, -side * 4.9), 1.0)
        if i % 5 == 0: _spawn(HOLIDAY + "snow-pile.glb", Vector3(x + 5, 0, side * 3.7), 1.1)

func _spawn(path: String, pos: Vector3, scale_factor := 1.0) -> void:
    if not ResourceLoader.exists(path): return
    var resource := load(path)
    if resource is PackedScene:
        var node := (resource as PackedScene).instantiate()
        if node is Node3D:
            node.position = pos
            node.scale *= scale_factor
            scenery.add_child(node)

func _build_penguin() -> void:
    penguin = RigidBody3D.new()
    penguin.mass = 1.15
    penguin.linear_damp = .08
    penguin.angular_damp = .5
    penguin.continuous_cd = true
    add_child(penguin)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = .52
    capsule.height = 1.55
    collider.shape = capsule
    penguin.add_child(collider)
    for path in ["res://assets/penguin/penguin.glb", "res://assets/penguin/penguin.blend"]:
        if ResourceLoader.exists(path):
            var resource := load(path)
            if resource is PackedScene:
                var model := (resource as PackedScene).instantiate()
                if model is Node3D:
                    model.scale *= .8
                    model.rotation_degrees = Vector3(0, 90, 0)
                    penguin.add_child(model)
                    return
    _placeholder_penguin()

func _placeholder_penguin() -> void:
    var body := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = .62
    mesh.height = 1.6
    body.mesh = mesh
    body.scale = Vector3(.9, 1.15, .85)
    body.material_override = _mat(Color("16191d"))
    penguin.add_child(body)
    var belly := MeshInstance3D.new()
    var belly_mesh := SphereMesh.new()
    belly_mesh.radius = .48
    belly_mesh.height = 1.15
    belly.mesh = belly_mesh
    belly.position = Vector3(.28, -.05, 0)
    belly.scale = Vector3(.55, .9, .72)
    belly.material_override = _mat(Color("f4f4ed"))
    penguin.add_child(belly)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.fov = 46
    camera.current = true
    add_child(camera)

func _build_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var top := VBoxContainer.new()
    top.position = Vector2(24, 36)
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
    hint_label = Label.new()
    hint_label.position = Vector2(40, 1000)
    hint_label.size = Vector2(640, 80)
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 26)
    canvas.add_child(hint_label)
    drag_line = Line2D.new()
    drag_line.width = 8
    drag_line.default_color = Color(.85, .18, .18, .85)
    canvas.add_child(drag_line)
    result_panel = PanelContainer.new()
    result_panel.position = Vector2(90, 430)
    result_panel.size = Vector2(540, 260)
    canvas.add_child(result_panel)
    result_label = Label.new()
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    result_label.add_theme_font_size_override("font_size", 26)
    result_panel.add_child(result_label)

func _add_box(size: Vector3, pos: Vector3, color: Color, collider: bool) -> void:
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(color)
    add_child(mi)
    if collider:
        var body := StaticBody3D.new()
        body.position = pos
        var cs := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        cs.shape = shape
        body.add_child(cs)
        add_child(body)

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = .82
    return m
