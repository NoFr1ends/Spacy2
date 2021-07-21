extends Node

var endpoint = ""

var _health_check = null

func _init():
	# Calculate agones endpoint
	if OS.has_environment("AGONES_SDK_HTTP_PORT"):
		endpoint = "http://127.0.0.1:" + OS.get_environment("AGONES_SDK_HTTP_PORT")
	else:
		endpoint = "http://127.0.0.1:9358"
		printerr("No agones sdk http port found fallback to default port 9358")
	print("Agones endpoint: ", endpoint)
	
	# Start health check
	_health_check = Timer.new()
	_health_check.name = "Health Check Timer"
	_health_check.connect("timeout", self, "_on_health_check")
	_health_check.wait_time = 2
	_health_check.autostart = true
	add_child(_health_check)
	
func _on_health_check():
	var http = HTTPRequest.new()
	http.name = "Health Check"
	add_child(http)
	http.request(endpoint + "/health", ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print({}))
	
	var response = yield(http, "request_completed")
	if response[1] != 200:
		printerr("Health check failed")
	http.queue_free()

func mark_ready():
	var http = HTTPRequest.new()
	http.name = "Ready"
	add_child(http)
	http.request(endpoint + "/ready", ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print({}))
	
	var response = yield(http, "request_completed")
	http.queue_free()
	if response[1] != 200:
		printerr("Failed to mark gameserver as ready, retry in 5 seconds...")
		var retry_timer = get_tree().create_timer(5)
		retry_timer.connect("timeout", self, "mark_ready")
		return
	print("Server marked as ready")
