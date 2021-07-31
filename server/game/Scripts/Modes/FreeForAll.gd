class_name FreeForAll
extends Node2D

export var winning_score = 100
export var max_round_time = 10 * 60

var scores = {}
var time_left = 0

signal end_game()

func _ready():
	time_left = max_round_time

func _process(delta):
	time_left -= delta
	
	if time_left <= 0:
		emit_signal("end_game")
		queue_free()

func create_state():
	return {
		"T": round(time_left)
	}
