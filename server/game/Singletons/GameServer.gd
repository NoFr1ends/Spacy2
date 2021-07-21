extends Node

var network = NetworkedMultiplayerENet.new()

var mode = ""
var allowed_players = []

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
	if "object_meta" in gameserver:
		if "labels" in gameserver.object_meta and "mode" in gameserver.object_meta.labels:
			mode = gameserver.object_meta.labels.mode
		if "annotations" in gameserver.object_meta and "players" in gameserver.object_meta.annotations:
			allowed_players = gameserver.object_meta.annotations.players.split(",")
	print("Mode: ", mode)
	print("Allowed Players: ", allowed_players)
	
func _on_peer_connected(peer_id):
	if mode == "":
		# We aren't ready to accept connections yet
		network.disconnect_peer(peer_id)
		return
	print("new connection ", peer_id)
	
func _on_peer_disconnected(peer_id):
	print("connection closed ", peer_id)

remote func authorize(auth_token):
	# TODO: parse auth token (JWT) and verify it
	var peer_id = get_tree().multiplayer.get_rpc_sender_id()
	
	if not auth_token in allowed_players:
		printerr("Player is not allowed on this server!")
		network.disconnect_peer(peer_id)
		return
	
	print(peer_id, " authorized")
	rpc_id(peer_id, "authorized")
