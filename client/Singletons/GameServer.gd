extends Node

var address = ""
var network = NetworkedMultiplayerENet.new()

func _ready():
	network.connect("connection_succeeded", self, "_on_connection_succeeded")
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("server_disconnected", self, "_on_server_disconnected")

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

func _on_connection_failed():
	printerr("Failed to connect to game server")
	
func _on_server_disconnected():
	printerr("Server closed the connection")
