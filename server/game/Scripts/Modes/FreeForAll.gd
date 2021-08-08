class_name FreeForAll
extends Node2D

export var winning_score = 100
export var max_round_time = 10 * 60
export var expected_players = []

var players = {}
var time_left = 0
var time_to_start = 30
var started = false

signal start_game()
signal end_game()
signal scoreboard(scoreboard)

func _ready():
	time_left = max_round_time

func _process(delta):
	if started:
		time_left -= delta
	elif players.size() >= 2:
		time_to_start -= delta
		if time_to_start <= 0:
			print("waiting time expired start game anyways")
			_start_game()
	
	if time_left <= 0:
		emit_signal("end_game")
		queue_free()

func _start_game():
	emit_signal("start_game")
	started = true

func create_state():
	var state = {
		"T": round(time_left)
	}
	if not started:
		state["P1"] = players.size()
		state["P2"] = expected_players.size() 
		state["W"] = round(time_to_start)
	
	return state

class ScoreBoardSorter:
	static func sort_ascending(a, b):
		if a["score"] < b["score"]:
			return true
		return false
	
	static func sort_decending(a, b):
		if a["score"] > b["score"]:
			return true
		return false

func create_scoreboard():
	var scoreboard = []
	
	for player in players.values():
		scoreboard.append({
			"name": player["username"],
			"score": player["score"]
		})
	
	scoreboard.sort_custom(ScoreBoardSorter, "sort_decending")
	
	return scoreboard

func player_joined(peer_id, username):
	players[peer_id] = {
		"username": username,
		"score": 0
	}
	
	if players.size() == expected_players.size():
		print("All players connected, start game")
		_start_game()
	
	if started:
		# We have to send match start to the newly connected client
		emit_signal("start_game")
	emit_signal("scoreboard", create_scoreboard())

func player_left(peer_id):
	if peer_id in players:
		players.erase(peer_id)
	emit_signal("scoreboard", create_scoreboard())

func player_killed(player, killed_by):
	print(player.peer_id, " was killed by ", killed_by)
	if killed_by in players:
		players[killed_by]["score"] = players[killed_by]["score"] + 1
		emit_signal("scoreboard", create_scoreboard())
