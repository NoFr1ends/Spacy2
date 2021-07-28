class_name Player
extends Node2D

export var max_health = 100

var peer_id = 0

var health = 100

var last_state_time = 0

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
