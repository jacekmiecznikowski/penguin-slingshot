extends Node3D

const SECTION_LENGTH := 80.0
const SECTION_NAMES := ["ŚNIEŻNA WIOSKA", "LODOWY LAS", "KRYSZTAŁOWE POLE", "WIETRZNA PRZEŁĘCZ", "BIEGUNOWY FINAŁ"]
const PICKUP_BASE_VALUE := 5

var host: Node
var penguin: RigidBody3D
var camera: Camera3D
var course_root: Node3D
var pickup_nodes: Array[Area3D] = []
var section_label: Label
var run_pickup_label: Label
var run_pickup_coins := 0
var current_section := -1
var last_impact_ms := -10000
var setup_done := false
var previous_launched := false
var previous_finished := false

var sfx_player: AudioStreamPlayer
var coin_sfx: AudioStreamWAV
var boost_sfx: AudioStreamWAV
var impact_sfx: AudioStreamWAV
var launch_sfx: AudioStreamWAV

func _ready() -> void:
    call_deferred("_setup")

func _setup() -> void:
    host = get_parent()
    penguin = host.get("penguin") as RigidBody3D
    camera = host.get("camera") as Camera3D
    if penguin == null or camera == null:
        push_warning("Stage 4 course could not attach to the Stage 3 host.")
        return

    _build_audio()
    _build_course()
    _build_overlay()
    penguin.body_entered.connect(_on_penguin_body_entered)
    previous_launched = bool(host.get("launched"))
    previous_finished = bool(host.get("run_finished"))
    setup_done = true
    _reset_course_items()
    _refresh_overlay(true)

func _process(_delta: float) -> void:
    if not setup_done:
        return

    var launched := bool(host.get("launched"))
    var finished := bool(host.get("run_finished"))

    if launched and not previous_launched:
        run_pickup_coins = 0
        current_section = -1
        _reset_course_items()
        _spawn_burst(penguin.global_position, Color("ccefff"), 24)
        _play_sfx(launch_sfx, 1.0)

    if finished and not previous_finished:
        _show_stage4_result()
    elif not finished and previous_finished:
        run_pickup_coins = 0
        current_section = -1
        _reset_course_items()

    if not launched and previous_launched and not finished:
        run_pickup_coins = 0
        current_section = -1
        _reset_course_items()

    previous_launched = launched
    previous_finished = finished
    _refresh_overlay()

func _physics_process(delta: float) -> void:
    if not setup_done:
        return
    if not bool(host.get("launched")) or bool(host.get("run_finished")):
        return

    var speed := penguin.linear_velocity.length()
    camera.fov = lerp(camera.fov, clamp(46.0 + speed * 0.24, 46.0, 56.0), 1.0 - exp(-2.7 * delta))

func _refresh_overlay(force_section: bool = false) -> void:
    if not setup_done:
        return

    var distance := max(0.0, float(host.get("max_distance")))
    var index := clampi(int(distance / SECTION_LENGTH), 0, SECTION_NAMES.size() - 1)
    if force_section or index != current_section:
        current_section = index
        section_label.text = "%s  •  ODCINEK %d/%d" % [SECTION_NAMES[index], index + 1, SECTION_NAMES.size()]

    run_pickup_label.text = "ZEBRANE NA TRASIE  +%d" % run_pickup_coins

func _pickup_value() -> int:
    var multiplier := float(host.call("_income_multiplier"))
    return max(1, int(round(float(PICKUP_BASE_VALUE) * multiplier)))

func _build_course() -> void:
    course_root = Node3D.new()
    course_root.name = "Stage4Course"
    add_child(course_root)

    _add_obstacle(Vector3(3.2, 0.75, 5.5), Vector3(52.0, 0.12, 0.0), Color("b8e7f4"), "IceBankA")
    _add_obstacle(Vector3(2.4, 1.05, 5.5), Vector3(96.0, 0.28, 0.0), Color("9bd8ed"), "IceBankB")
    _add_obstacle(Vector3(4.4, 0.65, 5.5), Vector3(142.0, 0.07, 0.0), Color("d6f4fb"), "SnowBankC")
    _add_obstacle(Vector3(2.8, 1.25, 5.5), Vector3(190.0, 0.38, 0.0), Color("91cce6"), "IceBankD")
    _add_obstacle(Vector3(5.0, 0.8, 5.5), Vector3(246.0, 0.15, 0.0), Color("c8edf7"), "SnowBankE")
    _add_obstacle(Vector3(3.2, 1.15, 5.5), Vector3(312.0, 0.32, 0.0), Color("8cc5df"), "IceBankF")

    for i in range(24):
        var x := 18.0 + float(i) * 13.5
        var y := 2.4 + sin(float(i) * 0.82) * 1.25 + float(i % 3) * 0.28
        _add_coin_pickup(Vector3(x, y, 0.0))

    for pos in [Vector3(72.0, 4.1, 0.0), Vector3(164.0, 5.0, 0.0), Vector3(270.0, 4.5, 0.0)]:
        _add_boost_pickup(pos)

    for i in range(1, SECTION_NAMES.size()):
        var x := float(i) * SECTION_LENGTH
        _add_marker(Vector3(x, 2.3, -4.4))
        _add_marker(Vector3(x, 2.3, 4.4))

func _add_obstacle(size: Vector3, pos: Vector3, color: Color, obstacle_name: String) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.material_override = _material(color)
    course_root.add_child(mesh_instance)

    var body := StaticBody3D.new()
    body.name = obstacle_name
    body.position = pos
    body.set_meta("hazard", true)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    course_root.add_child(body)

func _add_marker(pos: Vector3) -> void:
    var marker := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.16, 4.6, 0.16)
    marker.mesh = mesh
    marker.position = pos
    marker.material_override = _material(Color("77a7bb"))
    course_root.add_child(marker)

func _add_coin_pickup(pos: Vector3) -> void:
    var area := Area3D.new()
    area.name = "CoinPickup"
    area.position = pos
    area.set_meta("kind", "coin")
    area.set_meta("collected", false)

    var collision := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.72
    collision.shape = sphere
    area.add_child(collision)

    var visual := MeshInstance3D.new()
    var coin_mesh := CylinderMesh.new()
    coin_mesh.top_radius = 0.38
    coin_mesh.bottom_radius = 0.38
    coin_mesh.height = 0.12
    visual.mesh = coin_mesh
    visual.rotation_degrees = Vector3(90.0, 0.0, 0.0)
    visual.material_override = _material(Color("ffd452"))
    area.add_child(visual)

    area.body_entered.connect(_on_course_pickup.bind(area))
    course_root.add_child(area)
    pickup_nodes.append(area)

func _add_boost_pickup(pos: Vector3) -> void:
    var area := Area3D.new()
    area.name = "BoostPickup"
    area.position = pos
    area.set_meta("kind", "boost")
    area.set_meta("collected", false)

    var collision := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 1.05
    collision.shape = sphere
    area.add_child(collision)

    var visual := MeshInstance3D.new()
    var orb := SphereMesh.new()
    orb.radius = 0.55
    orb.height = 1.1
    visual.mesh = orb
    var material := _material(Color("49e6f2"))
    material.emission_enabled = true
    material.emission = Color("2bbfdb")
    material.emission_energy_multiplier = 2.2
    visual.material_override = material
    area.add_child(visual)

    area.body_entered.connect(_on_course_pickup.bind(area))
    course_root.add_child(area)
    pickup_nodes.append(area)

func _on_course_pickup(body: Node3D, area: Area3D) -> void:
    if body != penguin or bool(area.get_meta("collected", false)):
        return

    area.set_meta("collected", true)
    area.set_deferred("monitoring", false)
    area.visible = false
    var kind := String(area.get_meta("kind", "coin"))

    if kind == "coin":
        var value := _pickup_value()
        run_pickup_coins += value
        host.set("coins", int(host.get("coins")) + value)
        host.call("_save_progress")
        host.call("_refresh_upgrade_ui")
        _spawn_burst(area.global_position, Color("ffd452"), 14)
        _play_sfx(coin_sfx, 1.0)
    else:
        var sled_level := 0
        var upgrade_data = host.get("upgrades")
        if upgrade_data is Dictionary:
            sled_level = int(upgrade_data.get("sled", 0))
        var boost_strength := 5.5 + 0.35 * float(sled_level)
        penguin.apply_central_impulse(Vector3(boost_strength, 2.4, 0.0))
        _spawn_burst(area.global_position, Color("54eaf6"), 26)
        _play_sfx(boost_sfx, 1.0)
        var hint := host.get("hint_label") as Label
        if hint != null:
            hint.text = "DOPALACZ!"

    _refresh_overlay()

func _reset_course_items() -> void:
    for area in pickup_nodes:
        if is_instance_valid(area):
            area.set_meta("collected", false)
            area.visible = true
            area.monitoring = true

func _on_penguin_body_entered(body: Node) -> void:
    if not setup_done or not bool(host.get("launched")) or bool(host.get("run_finished")):
        return

    var now := Time.get_ticks_msec()
    if now - last_impact_ms < 180:
        return

    var hint := host.get("hint_label") as Label
    if bool(body.get_meta("hazard", false)):
        last_impact_ms = now
        penguin.linear_velocity *= 0.83
        _spawn_burst(penguin.global_position, Color("cfeef7"), 18)
        _play_sfx(impact_sfx, 0.84)
        if hint != null:
            hint.text = "BUM! PRZESZKODA"
    elif body.name == "StaticBody3D" and float(host.get("flight_time")) > 0.45 and penguin.linear_velocity.length() > 2.0:
        last_impact_ms = now
        _spawn_burst(penguin.global_position, Color("eefaff"), 12)
        _play_sfx(impact_sfx, 0.68)

func _show_stage4_result() -> void:
    var result := host.get("result_label") as Label
    if result == null:
        return
    var distance := int(max(0.0, float(host.get("max_distance"))))
    var distance_reward := int(host.get("last_reward"))
    var total_wallet := int(host.get("coins"))
    result.text = "DYSTANS: %d m\nLOT: +%d  •  TRASA: +%d\nRAZEM ZA PRÓBĘ: +%d\n\nPORTFEL: %d\n\nDotknij poza kartami, aby lecieć ponownie" % [distance, distance_reward, run_pickup_coins, distance_reward + run_pickup_coins, total_wallet]

func _build_overlay() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 2
    add_child(canvas)

    section_label = Label.new()
    section_label.position = Vector2(24, 105)
    section_label.size = Vector2(672, 42)
    section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    section_label.add_theme_font_size_override("font_size", 18)
    section_label.add_theme_color_override("font_color", Color("31566d"))
    canvas.add_child(section_label)

    run_pickup_label = Label.new()
    run_pickup_label.position = Vector2(24, 154)
    run_pickup_label.size = Vector2(270, 46)
    run_pickup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    run_pickup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    run_pickup_label.add_theme_font_size_override("font_size", 17)
    run_pickup_label.add_theme_color_override("font_color", Color("725518"))
    run_pickup_label.add_theme_stylebox_override("normal", _ui_box(Color(1.0, 0.88, 0.52, 0.88), 14))
    canvas.add_child(run_pickup_label)

func _spawn_burst(pos: Vector3, color: Color, amount: int) -> void:
    var particles := GPUParticles3D.new()
    particles.one_shot = true
    particles.amount = amount
    particles.lifetime = 0.65
    particles.explosiveness = 0.92

    var process := ParticleProcessMaterial.new()
    process.direction = Vector3(0.0, 1.0, 0.0)
    process.spread = 180.0
    process.gravity = Vector3(0.0, -7.5, 0.0)
    process.initial_velocity_min = 2.2
    process.initial_velocity_max = 5.8
    process.scale_min = 0.55
    process.scale_max = 1.35
    process.color = color
    particles.process_material = process

    var quad := QuadMesh.new()
    quad.size = Vector2(0.16, 0.16)
    var particle_material := StandardMaterial3D.new()
    particle_material.vertex_color_use_as_albedo = true
    particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    quad.material = particle_material
    particles.draw_pass_1 = quad
    add_child(particles)
    particles.global_position = pos
    particles.emitting = true
    get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

func _build_audio() -> void:
    sfx_player = AudioStreamPlayer.new()
    sfx_player.name = "Stage4SFX"
    add_child(sfx_player)
    coin_sfx = _make_tone(860.0, 0.09, 0.20)
    boost_sfx = _make_tone(430.0, 0.18, 0.22)
    impact_sfx = _make_tone(120.0, 0.11, 0.18)
    launch_sfx = _make_tone(270.0, 0.13, 0.18)

func _make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
    var sample_rate := 22050
    var sample_count := max(1, int(float(sample_rate) * duration))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)
    for i in range(sample_count):
        var t := float(i) / float(sample_rate)
        var attack := min(1.0, t * 45.0)
        var release := max(0.0, 1.0 - t / duration)
        var wave := sin(TAU * frequency * t)
        var sample := int(clamp(wave * volume * attack * release, -1.0, 1.0) * 32767.0)
        bytes.encode_s16(i * 2, sample)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = bytes
    return stream

func _play_sfx(stream: AudioStreamWAV, pitch: float = 1.0) -> void:
    if sfx_player == null or stream == null:
        return
    sfx_player.pitch_scale = pitch
    sfx_player.stream = stream
    sfx_player.play()

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.78
    return material

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
