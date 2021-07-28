extends Node2D

export var speed = 1000

var id = 0
var own = false
var lifetime = 10.0

func _process(delta):
	if own:
		lifetime -= delta
		
		if lifetime <= 0:
			queue_free()

func _physics_process(delta):
	if own:
		position += Vector2(speed, 0).rotated(rotation) * delta
