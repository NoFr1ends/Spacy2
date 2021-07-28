extends Node2D

export var move_speed = 500
export var booster_time = 0.3
export var shoot_delay = 0.1

export var team_color = "blue"
export var is_own_player = false

onready var booster_left = $BoosterLeft
onready var booster_right = $BoosterRight
onready var shoot_spawn_position = $ShootSpawnPosition
onready var tween = $Tween

onready var laser = preload("res://Scenes/Entities/Laser.tscn")
var shoot_cooldown = 0

var boosting = false setget set_boosting

func _ready():
	if is_own_player:
		$Camera2D.current = true

func _process(delta):
	if not is_own_player:
		return
	
	look_at(get_global_mouse_position())
	
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

func sync_state(position, rotation, boosting):
	if is_own_player:
		printerr("Sync state for our own ship?!")
		return
	self.position = position
	self.rotation = rotation
	self.boosting = boosting
