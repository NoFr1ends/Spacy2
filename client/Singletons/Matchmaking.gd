extends Node

var matchmaking_server = "http://localhost:8000"
var is_searching = false
var ticket_id = ""
var assignment_timer = Timer.new()

signal match_found(address)

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
	request.request(matchmaking_server + "/search", [
		"Content-Type: application/json", 
		"Authorization: Bearer " + Authorization.token
	], false, HTTPClient.METHOD_POST, JSON.print({
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
	
	return true
	
func cancel_search():
	if not is_searching:
		return
		
	is_searching = false
	assignment_timer.stop()
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(matchmaking_server + "/ticket/" + ticket_id + "/cancel", [
		"Authorization: Bearer " + Authorization.token
	])
	var result = yield(request, "request_completed")
	
	if result[1] != 204:
		printerr("Cancel of ticket failed: ", result[3].get_string_from_utf8())

func _on_assignment_timer():
	print("check for assignment of ticket ", ticket_id)
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request(matchmaking_server + "/ticket/" + ticket_id, [
		"Authorization: Bearer " + Authorization.token
	])
	var result = yield(request, "request_completed")
	request.queue_free()
	
	if result[1] != 200:
		printerr("Failed to check ticket status: ", result[3].get_string_from_utf8())
		return # todo what to do? cancel the search? ignore and retry count?
		
	var json = JSON.parse(result[3].get_string_from_utf8())
	if json.error != OK:
		printerr("Failed to parse response from matchmaking server: ", json.error_string)
		return
		
	var ticket = json.result
	if "assignment" in ticket:
		# We got a match!
		emit_signal("match_found", ticket.assignment.connection)
		is_searching = false
		assignment_timer.stop()
