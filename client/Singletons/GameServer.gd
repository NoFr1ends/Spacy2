extends Node

var address = ""
var network = NetworkedMultiplayerENet.new()

# Timing
var last_handshake_time = 0
var time_difference = 0
var client_clock = 0

signal connected()
signal match_start()
signal match_end()
signal match_scoreboard(scoreboard)
signal game_state(state)
signal spawn(details)
signal spawn_entity(entity_type, id, position, rotation)
signal despawn_entity(entity_type, id)
signal update_play_area(size)

func _ready():
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("server_disconnected", self, "_on_server_disconnected")

func _process(_delta):
	client_clock = OS.get_system_time_msecs() - time_difference

func connect_to_server(address: String):
	print("Connecting to game server at ", address)
	var p = address.split(":")
	if p.size() != 2:
		printerr("Invalid address: ", address)
		return false
		
	if network.create_client(p[0], int(p[1])) != OK:
		return false
	
	get_tree().network_peer = network
	
	return true

func _on_connection_succeeded():
	print("Connected to game server")
	
	# Start time sync
	start_handshake()

func _on_connection_failed():
	printerr("Failed to connect to game server")
	
func _on_server_disconnected():
	printerr("Server closed the connection")

#################################
# H A N D S H A K E
#################################

func start_handshake():
	last_handshake_time = OS.get_system_time_msecs()
	rpc_id(1, "handshake", last_handshake_time, 0)

remote func authorized():
	emit_signal("connected")

remote func handshake(time, delta):
	print("handshake reply ", time, " ", delta)
	last_handshake_time = OS.get_system_time_msecs() + delta
	time_difference = delta
	rpc_id(1, "handshake", last_handshake_time, delta)
	
remote func handshake_done():
	print("handshake done, final delta is ", time_difference)
	rpc_id(1, "authorize", Authorization.token)
	
#################################
# G A M E M O D E
#################################

remote func start():
	emit_signal("match_start")

remote func end():
	emit_signal("match_end")

remote func scoreboard(scoreboard):
	emit_signal("match_scoreboard", scoreboard)

#################################
# W O R L D S Y N C
#################################

remote func spawn(details):
	print("received spawn event from server", details)
	emit_signal("spawn", details)

func send_state(state):
	rpc_unreliable_id(1, "recv_state", state)
	
remote func state(state):
	emit_signal("game_state", state)

remote func despawn_player(id):
	emit_signal("despawn_entity", "player", id)

remote func update_play_area(size):
	emit_signal("update_play_area", size)

#################################
# P L A Y E R A C T I O N S
#################################

func shoot(position, rotation):
	rpc_id(1, "shoot", position, rotation)
	
remote func spawn_projectile(id, position, rotation):
	emit_signal("spawn_entity", "projectile", id, position, rotation)

remote func despawn_projectile(id):
	emit_signal("despawn_entity", "projectile", id)
