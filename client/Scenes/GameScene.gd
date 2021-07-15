extends Node2D

func _ready():
	if GameServer.address == "":
		printerr("Missing gameserver address!")
		get_tree().change_scene("res://Scenes/SearchMatch.tscn")
		return

	# Connect to gameserver given by the matchmaking server
	GameServer.connect_to_server(GameServer.address)
	GameServer.address = ""