extends VBoxContainer

onready var entry_template = preload("res://Scenes/UI/ScoreboardEntry.tscn")

var scores = [] setget set_scores

func _ready():
	refresh_scoreboard()

func refresh_scoreboard():
	for i in range(max(len(scores), get_child_count()-1)):
		if i >= len(scores):
			get_child(i+1).queue_free()
			continue
		
		var score = scores[i]
			
		var entry = null
		if i >= get_child_count()-1:
			entry = entry_template.instance()
			add_child(entry)
		else:
			entry = get_child(i+1)
		entry.get_node("Place").text = str(i+1) + "."
		entry.get_node("Name").text = score["name"]
		entry.get_node("Score").text = str(score["score"])

func set_scores(new_val):
	scores = new_val
	refresh_scoreboard()
