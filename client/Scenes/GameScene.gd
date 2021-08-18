extends Node2D

onready var player_template = preload("res://Scenes/Entities/Player.tscn")
onready var laser_template = preload("res://Scenes/Entities/Laser.tscn")
onready var debug_position = $UI/Debug/Position
onready var debug_network = $UI/Debug/Network
onready var time_left = $UI/TimeLeft

const interpolation_offset = 100

var started = false
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
	GameServer.connect("match_end", self, "_on_GameServer_match_end")
	GameServer.connect("match_scoreboard", self, "_on_GameServer_match_scoreboard")
	GameServer.connect("game_state", self, "_on_GameServer_game_state")
	GameServer.connect("spawn", self, "_on_GameServer_spawn")
	GameServer.connect("spawn_entity", self, "_on_GameServer_spawn_entity")
	GameServer.connect("despawn_entity", self, "_on_GameServer_despawn_entity")
	GameServer.connect("update_play_area", self, "_on_GameServer_update_play_area")

func _physics_process(delta):
	if is_instance_valid(player):
		debug_position.text = "Position: " + str(floor(player.position.x)) + "," + str(floor(player.position.y)) + " (" + str(player.position.distance_to(Vector2(0, 0))) + ")"
		if network_stats.I + network_stats.E > 0:
			debug_network.text = "Network: " + str(round(network_stats.I / float(network_stats.I + network_stats.E) * 1000) / 10) + "%"
		
	var render_time = GameServer.client_clock - interpolation_offset
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2].T:
			world_state_buffer.remove(0)
			
		if "M" in world_state_buffer[1]:
			var time = int(world_state_buffer[1].M.T)
			var minutes = time / 60
			var seconds = time % 60
			time_left.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
		if not started:
			$UI/C/V/NoPlayers.text = str(world_state_buffer[1].M.P1) + "/" + str(world_state_buffer[1].M.P2)
			$UI/C/V/TimeLeft.text = "Start in " + str(world_state_buffer[1].M.W) + " seconds"
			
		if world_state_buffer.size() > 2: # We can interpolate
			network_stats.I += 1
			
			var interpolation_factor = float(render_time - world_state_buffer[1].T) / float(world_state_buffer[2].T - world_state_buffer[1].T)
			for player in world_state_buffer[2].P.keys():
				if player == get_tree().get_network_unique_id():
					self.player.health = world_state_buffer[2].P[player].H
					continue
				if not world_state_buffer[1].P.has(player):
					continue # previous state was missing this player so it's new
				
				var p = get_player(player)
				if p:
					p.sync_state(
						lerp(world_state_buffer[1].P[player].P, world_state_buffer[2].P[player].P, interpolation_factor),
						lerp(world_state_buffer[1].P[player].R, world_state_buffer[2].P[player].R, interpolation_factor),
						world_state_buffer[1].P[player].P != world_state_buffer[2].P[player].P
					)
					p.health = world_state_buffer[2].P[player].H
				else:
					print("Spawn ship for player ", player)
					var instance = player_template.instance()
					instance.position = lerp(world_state_buffer[1].P[player].P, world_state_buffer[2].P[player].P, interpolation_factor)
					instance.rotation = lerp(world_state_buffer[1].P[player].R, world_state_buffer[2].P[player].R, interpolation_factor)
					instance.health = world_state_buffer[2].P[player].H
					instance.name = "Player" + str(player)
					$Players.add_child(instance)
			for projectile in world_state_buffer[2].PP.keys():
				if not world_state_buffer[1].PP.has(projectile):
					continue
				
				var p = get_projectile(projectile)
				if p:
					if not p.own:
						p.position = lerp(world_state_buffer[1].PP[projectile].P, world_state_buffer[2].PP[projectile].P, interpolation_factor)
						p.rotation = lerp(world_state_buffer[1].PP[projectile].R, world_state_buffer[2].PP[projectile].R, interpolation_factor)
				else:
					var instance = laser_template.instance()
					instance.position = lerp(world_state_buffer[1].PP[projectile].P, world_state_buffer[2].PP[projectile].P, interpolation_factor)
					instance.rotation = lerp(world_state_buffer[1].PP[projectile].R, world_state_buffer[2].PP[projectile].R, interpolation_factor)
					instance.name = "Projectile" + str(projectile)
					instance.id = projectile
					$Projectiles.add_child(instance)
			for projectile in $Projectiles.get_children():
				if not projectile.own and not world_state_buffer[2].PP.has(projectile.id):
					projectile.queue_free()
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
					var position_delta: Vector2 = world_state_buffer[1].P[player].P - world_state_buffer[0].P[player].P
					var rotation_delta = world_state_buffer[1].P[player].R - world_state_buffer[0].P[player].R
					p.sync_state(
						world_state_buffer[1].P[player].P + (position_delta * extrapolation_factor),
						world_state_buffer[1].P[player].R + (rotation_delta * extrapolation_factor),
						position_delta.length_squared() > 0
					)
			for projectile in world_state_buffer[1].PP.keys():
				if not world_state_buffer[0].PP.has(projectile):
					continue
				
				var p = get_projectile(projectile)
				if p and not p.own:
					var position_delta: Vector2 = world_state_buffer[1].PP[projectile].P - world_state_buffer[0].PP[projectile].P
					var rotation_delta = world_state_buffer[1].PP[projectile].R - world_state_buffer[0].PP[projectile].R
					p.position = world_state_buffer[1].PP[projectile].P + (position_delta * extrapolation_factor)
					p.rotation = world_state_buffer[1].PP[projectile].R + (rotation_delta * extrapolation_factor)

func get_player(player_id):
	return $Players.get_node_or_null("Player" + str(player_id))

func get_projectile(projectile_id):
	return $Projectiles.get_node_or_null("Projectile" + str(projectile_id))

func _on_GameServer_connected():
	print("Connected and authorized at gameserver, waiting for match to start")

func _on_GameServer_match_start():
	started = true
	for node in get_tree().get_nodes_in_group("before_playing"):
		node.visible = false
	for node in get_tree().get_nodes_in_group("while_playing"):
		node.visible = true
	for node in $Players.get_children():
		node.paused = false

func _on_GameServer_match_end():
	for node in get_tree().get_nodes_in_group("while_playing"):
		node.visible = false
	for node in get_tree().get_nodes_in_group("after_playing"):
		node.visible = true
	for node in $Players.get_children():
		node.paused = true

func _on_GameServer_match_scoreboard(scoreboard):
	$UI/Scoreboard.scores = scoreboard

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
	player.name = "Player" + str(get_tree().get_network_unique_id())
	player.paused = !started
	$Players.add_child(player)

func _on_GameServer_spawn_entity(entity_type, id, position, rotation):
	if entity_type == "projectile":
		var instance = laser_template.instance()
		instance.own = true
		instance.id = id
		instance.position = position
		instance.rotation = rotation
		instance.name = "Projectile" + str(id)
		$Projectiles.add_child(instance)

func _on_GameServer_despawn_entity(entity_type, id):
	if entity_type == "projectile":
		var p = get_projectile(id)
		if p:
			p.visible = false
			# We have to delay despawning our own projectile for a short time
			# to prevent them from respawning due to world sync
			yield(get_tree().create_timer(interpolation_offset / 1000.0 * 2), "timeout")
			if is_instance_valid(p):
				p.queue_free()
	if entity_type == "player":
		var p = get_player(id)
		if p:
			p.visible = false
			yield(get_tree().create_timer(interpolation_offset / 1000.0 * 2), "timeout")
			if is_instance_valid(p):
				p.queue_free()

func _on_GameServer_update_play_area(size):
	var area = $PlayArea
	area.scale = Vector2(size * 4, size * 4)
	area.material.set_shader_param("radius", size)
	area.material.set_shader_param("scale", size * 4)
	area.visible = true
