extends Node2D

export var move_speed = 500
export var booster_time = 0.3
export var shoot_delay = 0.1

export var team_color = "blue"

onready var booster_left = $BoosterLeft
onready var booster_right = $BoosterRight
onready var shoot_spawn_position = $ShootSpawnPosition
onready var tween = $Tween

onready var laser = preload("res://Scenes/Entities/Laser.tscn")
var shoot_cooldown = 0

func _process(delta):
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("boost"):
		tween.interpolate_property(booster_left, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		tween.interpolate_property(booster_right, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		tween.start()
	if Input.is_action_just_released("boost"):
		tween.interpolate_property(booster_left, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		tween.interpolate_property(booster_right, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), booster_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		tween.start()
	
	if Input.is_action_pressed("boost"):
		position += (Vector2.RIGHT * move_speed).rotated(rotation) * delta
		
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	if Input.is_action_just_pressed("shoot") and shoot_cooldown <= 0:
		var sprite = laser.instance()
		sprite.position = to_global(shoot_spawn_position.position)
		sprite.rotation_degrees = rotation_degrees
		get_parent().add_child(sprite)
		shoot_cooldown = shoot_delay

func _physics_process(delta):
	pass
