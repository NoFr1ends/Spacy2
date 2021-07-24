extends Node

var address = ""
var auth_token = ""
var network = NetworkedMultiplayerENet.new()

# Timing
var last_handshake_time = 0
var time_difference = 0
var client_clock = 0

signal connected()

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
	rpc_id(1, "authorize", auth_token)
	auth_token = ""
