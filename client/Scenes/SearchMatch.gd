extends Control

onready var mode_tdm: CheckBox = $C/V/TDM
onready var mode_ffa: CheckBox = $C/V/FFA
onready var mode_ctf: CheckBox = $C/V/CTF

func _on_Search_pressed():
	var modes = []
	if mode_tdm.pressed:
		modes.append("td")
	if mode_ffa.pressed:
		modes.append("ffa")
	if mode_ctf.pressed:
		modes.append("ctf")
	
	if modes.empty():
		return
		
	var result = yield(Matchmaking.search_match(modes), "completed")
	if not result:
		printerr("Search for match failed!")
