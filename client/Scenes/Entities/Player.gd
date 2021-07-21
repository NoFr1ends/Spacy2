extends Node2D

func _process(delta):
	#translate(Vector2(0, -100 * delta))
	look_at(get_global_mouse_position())
	pass
