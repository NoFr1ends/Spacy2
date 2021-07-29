extends Node

var authentication_server = "http://localhost:8000"
var token = ""

signal auth_response(status)

func login(username: String, password: String):
	var request = HTTPRequest.new()
	add_child(request)
	request.request(authentication_server + "/login", ["Content-Type: application/json"], false, HTTPClient.METHOD_POST, JSON.print({
		"username": username,
		"password": password
	}))
	var result = yield(request, "request_completed")
	request.queue_free()
	
	if result[1] != 200:
		emit_signal("auth_response", false)
		return
	
	var json = JSON.parse(result[3].get_string_from_utf8())
	if json.error != OK:
		printerr("Failed to parse auth response: ", json.error_string)
		emit_signal("auth_response", false)
		return
	
	if not json.result.status:
		emit_signal("auth_response", false)
		return
	
	token = json.result.token
	emit_signal("auth_response", true)
