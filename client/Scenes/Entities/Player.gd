extends Node2D

export var move_speed = 500

onready var booster_left = $BoosterLeft
onready var booster_right = $BoosterRight

func _process(delta):
	look_at(get_global_mouse_position())
	
	if Input.is_action_pressed("boost"):
		position += (Vector2.RIGHT * move_speed).rotated(rotation) * delta
		booster_left.visible = true
		booster_right.visible = true
	else:
		booster_left.visible = false
		booster_right.visible = false

func _physics_process(delta):
	pass
