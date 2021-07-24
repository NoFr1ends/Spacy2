extends Node

var address = ""
var auth_token = ""
var network = NetworkedMultiplayerENet.new()

# Timing
var latency = 0
var client_clock = 0
var clock_difference = 0

signal connected()

func _ready():
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("server_disconnected", self, "_on_server_disconnected")

func _process(_delta):
	client_clock = OS.get_system_time_msecs() + clock_difference

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
	rpc_id(1, "sync_time", OS.get_system_time_msecs())

func _on_connection_failed():
	printerr("Failed to connect to game server")
	
func _on_server_disconnected():
	printerr("Server closed the connection")

remote func authorized():
	emit_signal("connected")

remote func sync_time(client_time, server_time):
	latency = (OS.get_system_time_msecs() - client_time) / 2
	client_clock = server_time + latency
	clock_difference = client_clock - OS.get_system_time_msecs()
	
	rpc_id(1, "authorize", auth_token)
	auth_token = ""
