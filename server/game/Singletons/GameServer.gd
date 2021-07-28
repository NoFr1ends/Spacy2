extends Node

onready var players = $Players

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
	
	if not "test" in allowed_players:
		pass
	
func _on_peer_disconnected(peer_id):
	print("connection closed ", peer_id)
	
	# check if player has a player instance
	var player = players.get_node_or_null("Player" + str(peer_id))
	if player:
		player.queue_free()

remote func authorize(auth_token):
	# TODO: parse auth token (JWT) and verify it
	var peer_id = get_tree().multiplayer.get_rpc_sender_id()
	
	if not auth_token in allowed_players:
		printerr("Player is not allowed on this server!")
		network.disconnect_peer(peer_id)
		return
	
	print(peer_id, " authorized")
	rpc_id(peer_id, "authorized")
	
	# Spawn player in random position in the play area
	var player = Player.new()
	player.position = Vector2(rand_range(0, 10000), rand_range(0, 10000))
	player.peer_id = peer_id
	player.name = "Player" + str(peer_id)
	players.add_child(player)
	rpc_id(peer_id, "spawn", player.create_state())

remote func handshake(client_time, delta):
	var peer_id = get_tree().multiplayer.get_rpc_sender_id()
	var time = OS.get_system_time_msecs()
	var difference = time - (client_time + delta)
	if difference >= 0 and difference <= 50:
		print("Handshaking done, difference is ", difference)
		rpc_id(peer_id, "handshake_done")
		return
	
	delta = (time - client_time) / 2
	rpc_id(peer_id, "handshake", time, delta)

remote func recv_state(state):
	var peer_id = get_tree().multiplayer.get_rpc_sender_id()
	var player = players.get_node_or_null("Player" + str(peer_id))
	if not player:
		printerr("Received state from peer ", peer_id, " without having a player instance")
		network.disconnect_peer(peer_id)
		return
	
	player.sync_state(state)

func _physics_process(delta):
	var world_state = {
		"T": OS.get_system_time_msecs(),
		"P": {}
	}
	for player in players.get_children():
		world_state.P[player.peer_id] = player.create_state()
	rpc_unreliable("state", world_state)
