class_name Laser
extends Node2D

export var speed = 1000

onready var gameserver = $"/root/GameServer"

var id = 0
var peer_id = 0

var lifetime = 10.0

func _process(delta):
	lifetime -= delta
	
	if lifetime <= 0:
		queue_free()

func _physics_process(delta):
	var new_position = position + Vector2(speed, 0).rotated(rotation) * delta
	
	# check if we intersected a player
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(position, new_position, [], 1, false, true)
	if result:
		print("Projectile hit ", result)
		gameserver.send_hit(peer_id, id)
		result.collider.damage(peer_id, 10)
		queue_free()
	
	position = new_position

func create_state(): 
	return {
		"T": 1,
		"P": position,
		"R": rotation
	}
