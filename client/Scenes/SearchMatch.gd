extends Control

onready var mode_tdm: CheckBox = $C/V/TDM
onready var mode_ffa: CheckBox = $C/V/FFA
onready var mode_ctf: CheckBox = $C/V/CTF

onready var dialog: PopupDialog = $SearchDialog
onready var time_searching: Label = $SearchDialog/M/V/TimeSearching
onready var fadeout: ColorRect = $UIFadeout

var searching: bool = false
var time_start: int = 0

func _ready():
	Matchmaking.connect("match_found", self, "_on_match_found")

func _process(delta):
	if searching:
		var elapsed = OS.get_unix_time() - time_start
		var seconds = elapsed % 60
		var minutes = elapsed / 60
		
		var ss = str(seconds)
		var sm = str(minutes)
		
		if ss.length() < 2:
			ss = "0" + ss
		if sm.length() < 2:
			sm = "0" + sm
			
		time_searching.text = sm + ":" + ss

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
		
	fadeout.visible = true
	time_searching.text = "00:00"
	dialog.show()
		
	var result = yield(Matchmaking.search_match(modes), "completed")
	if not result:
		printerr("Search for match failed!")
		return
		
	searching = true
	time_start = OS.get_unix_time()

func _on_match_found(address: String):
	fadeout.visible = false
	dialog.hide()
	searching = false
