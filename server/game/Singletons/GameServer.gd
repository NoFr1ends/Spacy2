class_name GameServer
extends Node

onready var players = $Players
onready var projectiles = $Projectiles

onready var player_template = preload("res://Scenes/Entities/Player.tscn")
onready var laser_template = preload("res://Scenes/Entities/Laser.tscn")

const area_per_player = 2000

var network = NetworkedMultiplayerENet.new()

var mode = ""
var allowed_players = []
var projectile_id = 0
var play_area_size = area_per_player

var mode_controller = null

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
	
	if mode_controller:
		mode_controller.queue_free()
	if mode == "ffa":
		mode_controller = FreeForAll.new()
		mode_controller.name = "FreeForAllGameMode"
		mode_controller.expected_players = allowed_players
		mode_controller.connect("start_game", self, "_on_mode_start_game")
		mode_controller.connect("end_game", self, "_on_mode_end_game")
		mode_controller.connect("scoreboard", self, "_on_mode_scoreboard")
		add_child(mode_controller)
	else:
		printerr("Unknown game mode!")
		get_tree().quit()
	
func _on_peer_connected(peer_id):
	if mode == "":
		# We aren't ready to accept connections yet
		network.disconnect_peer(peer_id)
		return
	print("new connection ", peer_id)
	
func _on_peer_disconnected(peer_id):
	print("connection closed ", peer_id)
	
	mode_controller.player_left(peer_id)
	
	# check if player has a player instance
	var player = get_player(peer_id)
	if player:
		player.queue_free()
		rpc("despawn_player", peer_id)

func _on_mode_start_game():
	print("Start game!")
	rpc("start")

func _on_mode_end_game():
	print("Game finished!")
	rpc("end")
	Agones.shutdown()
	get_tree().quit()

func _on_mode_scoreboard(scoreboard):
	rpc("scoreboard", scoreboard)

func _physics_process(delta):
	var world_state = {
		"T": OS.get_system_time_msecs(),
		"P": {},
		"PP": {},
	}
	if mode_controller:
		world_state["M"] = mode_controller.create_state()
	
	for player in players.get_children():
		world_state.P[player.peer_id] = player.create_state()
	
	for projectile in projectiles.get_children():
		world_state.PP[projectile.id] = projectile.create_state()
	
	rpc_unreliable("state", world_state)

func get_player(player_id):
	return players.get_node_or_null("Player" + str(player_id))

func spawn_player(peer_id):
	var player = player_template.instance()
	var direction = Vector2.UP.rotated(rand_range(0, 2*PI))
	var distance = rand_range(0, play_area_size)
	player.position = direction * distance
	player.peer_id = peer_id
	player.name = "Player" + str(peer_id)
	players.add_child(player)
	rpc_id(peer_id, "spawn", player.create_state())
	
	player.connect("killed", self, "_on_Player_killed", [player])

func _on_Player_killed(killed_by, player):
	var peer_id = player.peer_id
	mode_controller.player_killed(player, killed_by)
	rpc("despawn_player", peer_id)
	player.queue_free()
	
	yield(get_tree().create_timer(5), "timeout")
	spawn_player(peer_id)

remote func authorize(auth_token):
	# TODO: parse auth token (JWT) and verify it
	var peer_id = get_tree().multiplayer.get_rpc_sender_id()
	
	var jwt = JWT.new()
	jwt.parse(auth_token, "test123") # todo: read secret from server configuration
	
	if not jwt.is_valid() or jwt.signing_method != "HS256" or not jwt.claims["username"] in allowed_players:
		printerr("Player is not allowed on this server!")
		network.disconnect_peer(peer_id)
		return
	
	print(peer_id, " authorized")
	rpc_id(peer_id, "authorized")
	
	mode_controller.player_joined(peer_id, jwt.claims["username"])
	
	play_area_size = max((players.get_child_count() + 1) * area_per_player, play_area_size) # we don't shrink the play area size
	print("Play area size is now ", play_area_size, " in all directions from the center")
	rpc("update_play_area", play_area_size)
	
	# Spawn player in random position in the play area
	spawn_player(peer_id)

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
	var player = get_player(peer_id)
	if not player:
		return
	
	player.sync_state(state)

remote func shoot(position: Vector2, rotation: float):
	var peer_id = get_tree().multiplayer.get_rpc_sender_id()
	var player = get_player(peer_id)
	if not player:
		printerr("Shoot from not existing player ", peer_id)
		network.disconnect_peer(peer_id)
		return

	# todo check position and rotation
	var projectile = laser_template.instance()
	projectile.id = projectile_id+1
	projectile.peer_id = peer_id
	projectile.position = position
	projectile.rotation = rotation
	projectile.name = "Projectile" + str(projectile.id)
	projectiles.add_child(projectile)
	
	projectile_id += 1
	rpc_id(peer_id, "spawn_projectile", projectile.id, position, rotation)

func send_hit(peer_id, by_entity_id):
	rpc_id(peer_id, "despawn_projectile", by_entity_id)
