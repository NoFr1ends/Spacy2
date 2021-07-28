extends Node2D

onready var player_template = preload("res://Scenes/Entities/Player.tscn")
onready var debug_position = $UI/Debug/Position
onready var debug_network = $UI/Debug/Network

const interpolation_offset = 100

var player = null
var last_world_state = 0
var world_state_buffer = []

var network_stats = {"E": 0, "I": 0}

func _ready():
	if GameServer.address == "":
		printerr("Missing gameserver address!")
		if not OS.has_feature("editor"):
			get_tree().change_scene("res://Scenes/SearchMatch.tscn")
		return

	# Connect to gameserver given by the matchmaking server
	GameServer.connect_to_server(GameServer.address)
	GameServer.address = ""

	GameServer.connect("connected", self, "_on_GameServer_connected")
	GameServer.connect("match_start", self, "_on_GameServer_match_start")
	GameServer.connect("game_state", self, "_on_GameServer_game_state")
	GameServer.connect("spawn", self, "_on_GameServer_spawn")

func _physics_process(delta):
	if player:
		debug_position.text = "Position: " + str(floor(player.position.x)) + "," + str(floor(player.position.y))
		if network_stats.I + network_stats.E > 0:
			debug_network.text = "Network: " + str(round(network_stats.I / float(network_stats.I + network_stats.E) * 1000) / 10) + "%"
		
	var render_time = GameServer.client_clock - interpolation_offset
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2].T:
			world_state_buffer.remove(0)
		if world_state_buffer.size() > 2: # We can interpolate
			network_stats.I += 1
			
			var interpolation_factor = float(render_time - world_state_buffer[1].T) / float(world_state_buffer[2].T - world_state_buffer[1].T)
			for player in world_state_buffer[2].P.keys():
				if player == get_tree().get_network_unique_id():
					continue
				if not world_state_buffer[1].P.has(player):
					continue # previous state was missing this player so it's new
				
				var p = get_player(player)
				if p:
					p.sync_state(
						lerp(world_state_buffer[1].P[player].P, world_state_buffer[2].P[player].P, interpolation_factor),
						lerp(world_state_buffer[1].P[player].R, world_state_buffer[2].P[player].R, interpolation_factor)
					)
				else:
					print("Spawn ship for player ", player)
					var instance = player_template.instance()
					instance.position = lerp(world_state_buffer[1].P[player].P, world_state_buffer[2].P[player].P, interpolation_factor)
					instance.rotation = lerp(world_state_buffer[1].P[player].R, world_state_buffer[2].P[player].R, interpolation_factor)
					instance.name = "Player" + str(player)
					$Players.add_child(instance)
		else: # We have to extrapolate
			if render_time - world_state_buffer[1].T > 5000:
				printerr("No world state in 5 seconds!")
				GameServer.disconnect_from_server()
				get_tree().change_scene("res://Scenes/SearchMatch.tscn") # todo move to disconnect event
				return
			network_stats.E += 1
			
			var extrapolation_factor = float(render_time - world_state_buffer[0].T) / float(world_state_buffer[1].T - world_state_buffer[0].T) - 1.0
			for player in world_state_buffer[1].P.keys():
				if player == get_tree().get_network_unique_id():
					continue
				if not world_state_buffer[0].P.has(player):
					continue
					
				var p = get_player(player)
				if p:
					var position_delta = world_state_buffer[1].P[player].P - world_state_buffer[0].P[player].P
					var rotation_delta = world_state_buffer[1].P[player].R - world_state_buffer[0].P[player].R
					p.sync_state(
						world_state_buffer[1].P[player].P + (position_delta * extrapolation_factor),
						world_state_buffer[1].P[player].R + (rotation_delta * extrapolation_factor)
					)

func get_player(player_id):
	return $Players.get_node_or_null("Player" + str(player_id))

func _on_GameServer_connected():
	print("Connected and authorized at gameserver, waiting for match to start")

func _on_GameServer_match_start():
	print("match start")
	
func _on_GameServer_game_state(state):
	if state.T < last_world_state:
		print("Received old world state, ignoring")
		return
	
	last_world_state = state.T
	world_state_buffer.append(state)

func _on_GameServer_spawn(details):
	if is_instance_valid(player):
		player.queue_free()
	
	player = player_template.instance()
	player.position = details.P
	player.rotation = details.R
	player.is_own_player = true
	$Players.add_child(player)
