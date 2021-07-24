extends Node2D

export var move_speed = 500
export var booster_time = 0.3

onready var booster_left = $BoosterLeft
onready var booster_right = $BoosterRight
onready var tween = $Tween

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

func _physics_process(delta):
	pass
