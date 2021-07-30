extends Node2D

export var move_speed = 500
export var booster_time = 0.3
export var shoot_delay = 0.1
export var max_health = 100

export var team_color = "blue"
export var is_own_player = false

onready var booster_left = $Ship/BoosterLeft
onready var booster_right = $Ship/BoosterRight
onready var shoot_spawn_position = $ShootSpawnPosition
onready var tween = $Tween
onready var health_bar = $HealthBar
onready var direction_arrow = $DirectionArrow

onready var laser = preload("res://Scenes/Entities/Laser.tscn")
var shoot_cooldown = 0

var health_fade_out = 0

var boosting = false setget set_boosting
var health = 100 setget set_health

func _ready():
	if is_own_player:
		$Camera2D.current = true
	else:
		direction_arrow.visible = true
	health_bar.max_value = max_health
	health_bar.value = health

func _process(delta):
	if is_own_player:
		look_at(get_global_mouse_position())
	health_bar.set_rotation(-rotation)
	
	if health_fade_out > 0:
		health_fade_out -= delta
		if health_fade_out <= 0:
			tween.interpolate_property(health_bar, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.2, Tween.TRANS_LINEAR)
			tween.start()
	
	if direction_arrow.visible:
		for camera in get_tree().get_nodes_in_group("cameras"):
			if camera.current:
				var center: Vector2 = camera.get_camera_screen_center()
				var size = get_viewport().size
				if position.y < center.y:
					var top = Geometry.line_intersects_line_2d(Vector2(center.x - size.x / 2, center.y - size.y / 2 + 30), Vector2.RIGHT, center, center.direction_to(position))
					if top and top.x <= center.x + size.x / 2 and top.x >= center.x - size.x / 2:
						direction_arrow.position = to_local(top)
				if position.y > center.y:
					var bottom = Geometry.line_intersects_line_2d(Vector2(center.x - size.x / 2, center.y + size.y / 2 - 30), Vector2.RIGHT, center, center.direction_to(position))
					if bottom and bottom.x <= center.x + size.x / 2 and bottom.x >= center.x - size.x / 2:
						direction_arrow.position = to_local(bottom)
				if position.x < center.x:
					var left = Geometry.line_intersects_line_2d(Vector2(center.x - size.x / 2 + 30, center.y - size.y / 2), Vector2.DOWN, center, center.direction_to(position))
					if left and left.y <= center.y + size.y / 2 and left.y >= center.y - size.y / 2:
						direction_arrow.position = to_local(left)
				if position.x > center.x:
					var right = Geometry.line_intersects_line_2d(Vector2(center.x + size.x / 2 - 30, center.y - size.y / 2), Vector2.DOWN, center, center.direction_to(position))
					if right and right.y <= center.y + size.y / 2 and right.y >= center.y - size.y / 2:
						direction_arrow.position = to_local(right)
				
	
	if not is_own_player:
		return
	
	self.boosting = Input.is_action_pressed("boost")
	
	if boosting:
		position += (Vector2.RIGHT * move_speed).rotated(rotation) * delta
	
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	if Input.is_action_just_pressed("shoot") and shoot_cooldown <= 0:
		GameServer.shoot(to_global(shoot_spawn_position.position), rotation)
		#var sprite = laser.instance()
		#sprite.position = to_global(shoot_spawn_position.position)
		#sprite.rotation_degrees = rotation_degrees
		#get_parent().add_child(sprite)
		shoot_cooldown = shoot_delay

func _physics_process(delta):
	if is_own_player:
		# Send player state to server
		GameServer.send_state({
			"P": position,
			"R": rotation,
			"T": GameServer.client_clock
		})

func set_boosting(new_val):
	if new_val != boosting:
		if new_val:
			tween.interpolate_property(booster_left, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
			tween.interpolate_property(booster_right, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
			tween.start()
		else:
			tween.interpolate_property(booster_left, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
			tween.interpolate_property(booster_right, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
			tween.start()
	boosting = new_val

func set_health(new_val):
	if new_val != health:
		tween.interpolate_property(health_bar, "modulate", health_bar.modulate, Color(1, 1, 1, 1), 0.2, Tween.TRANS_LINEAR)
		tween.interpolate_property(health_bar, "value", health_bar.value, new_val, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		health_fade_out = 2.0
	health = new_val
	if health_bar:
		health_bar.max_value = max_health

func sync_state(position, rotation, boosting):
	if is_own_player:
		printerr("Sync state for our own ship?!")
		return
	self.position = position
	self.rotation = rotation
	self.boosting = boosting

func _on_VisibilityNotifier2D_screen_entered():
	if not is_own_player:
		direction_arrow.visible = false

func _on_VisibilityNotifier2D_screen_exited():
	if not is_own_player:
		direction_arrow.visible = true
