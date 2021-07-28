class_name Laser
extends Node2D

export var speed = 1000

var id = 0
var peer_id = 0

var lifetime = 10.0

func _process(delta):
	lifetime -= delta
	
	if lifetime <= 0:
		queue_free()

func _physics_process(delta):
	position += Vector2(speed, 0).rotated(rotation) * delta

func create_state(): 
	return {
		"T": 1,
		"P": position,
		"R": rotation
	}
