extends Node2D

export var speed = 1000

var lifetime = 10.0

func _ready():
	pass # Replace with function body.

func _process(delta):
	lifetime -= delta
	
	if lifetime <= 0:
		print(lifetime)
		queue_free()

func _physics_process(delta):
	position += Vector2(speed, 0).rotated(rotation) * delta
