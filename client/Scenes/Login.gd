extends Control

onready var username = $C/P/M/V/Username
onready var password = $C/P/M/V/Password
onready var fadeout = $UIFadeout
onready var dialog = $LoginDialog

func _ready():
	Authorization.connect("auth_response", self, "_on_Login_auth_response")

func _on_Login_pressed():
	fadeout.visible = true
	dialog.visible = true
	Authorization.login(username.text, password.text)

func _on_Login_auth_response(status):
	if status:
		get_tree().change_scene("res://Scenes/SearchMatch.tscn")
	else:
		fadeout.visible = false
		dialog.visible = false
		printerr("Login failed")
