extends Node2D

export var move_speed = 500

func _process(delta):
	look_at(get_global_mouse_position())
	
	if Input.is_action_pressed("boost"):
		position += (Vector2.RIGHT * move_speed).rotated(rotation) * delta

func _physics_process(delta):
	pass
