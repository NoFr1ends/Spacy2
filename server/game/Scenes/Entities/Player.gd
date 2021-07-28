class_name Player
extends Node2D

export var max_health = 100
export var regen_interval = 1
export var regen_amount = 5

var peer_id = 0

var health = 100
var regen_time = regen_interval

var last_state_time = 0

func _process(delta):
	if health < max_health:
		regen_time -= delta
		if regen_time <= 0:
			health += regen_amount
			if health > max_health:
				health = max_health
				regen_time = regen_interval
			else:
				regen_time += regen_interval

func create_state():
	return {
		"P": position,
		"R": rotation,
		"H": health
	}

func sync_state(state):
	# todo: check plausability of the received state
	
	if state.T < last_state_time:
		print("Skip state as it's older than last receievd state")
		return
		
	position = state.P
	rotation = state.R
	last_state_time = state.T

func damage(peer_id, damage):
	if peer_id == self.peer_id:
		return # self hurting is evil!
	health -= damage
	if health < 0:
		health = 0 # dead is dead 
