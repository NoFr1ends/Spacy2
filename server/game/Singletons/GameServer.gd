extends Node

var network = NetworkedMultiplayerENet.new()

func _ready():
	network.server_relay = false
	start_server()
	# Server is ready to accept connections from player
	Agones.mark_ready()
	# Connect to changes for the gameserver configuration
	Agones.connect("gameserver", self, "_on_gameserver")

func start_server():
	network.create_server(8002, 32)
	get_tree().network_peer = network
	
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")
	
func _on_gameserver(gameserver):
	print("Recv gameserver update: ", gameserver)
	
func _on_peer_connected(peer_id):
	print("new connection ", peer_id)
	
func _on_peer_disconnected(peer_id):
	print("connection closed ", peer_id)
