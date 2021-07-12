extends Node

var matchmaking_server = "http://localhost:8000"
var is_searching = false
var ticket_id = ""
var assignment_timer = Timer.new()

signal match_found(address, port)

func _ready():
	add_child(assignment_timer)
	
	assignment_timer.connect("timeout", self, "_on_assignment_timer")

func search_match(modes):
	if is_searching:
		printerr("Searching for match while already searching for a match")
		return
		
	is_searching = true
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(matchmaking_server + "/search", ["Content-Type: application/json"], false, HTTPClient.METHOD_POST, JSON.print({
		"gameModes": modes
	}))
	var result = yield(request, "request_completed")
	request.queue_free()
	
	if result[1] != 200:
		printerr("Matchmaking server returned an error: ", result[3].get_string_from_utf8())
		is_searching = false
		return false
		
	var json = JSON.parse(result[3].get_string_from_utf8())
	if json.error != OK:
		printerr("Failed to parse response from matchmaking server: ", json.error_string)
		is_searching = false
		return false
		
	ticket_id = json.result.id
	
	# Start assignment clock
	assignment_timer.start(1)
	
func cancel_search():
	if not is_searching:
		return
		
	is_searching = false
	# todo send cancellation to matchmaking server
	assignment_timer.stop()

func _on_assignment_timer():
	print("check for assignment of ticket ", ticket_id)
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(matchmaking_server + "/ticket/" + ticket_id)
	var result = yield(request, "request_completed")
	request.queue_free()
	
	if result[1] != 200:
		printerr("Failed to check ticket status: ", result[3].get_string_from_utf8())
		return # todo what to do? cancel the search? ignore and retry count?
