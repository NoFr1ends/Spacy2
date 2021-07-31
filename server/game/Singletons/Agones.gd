extends Node

var endpoint = ""
var port = 9358
var ip = "127.0.0.1"

var _health_check = null
var _watch_client: HTTPClient = null
var _watch_waiting = true

signal gameserver(details)

func _init():
	# Calculate agones endpoint
	if OS.has_environment("AGONES_SDK_HTTP_PORT"):
		endpoint = "http://127.0.0.1:" + OS.get_environment("AGONES_SDK_HTTP_PORT")
		port = OS.get_environment("AGONES_SDK_HTTP_PORT")
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
	
func _ready():
	# Watch for changes of the gameserver
	watch_gameserver()
	
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

func shutdown():
	pass # todo implement

func watch_gameserver():
	_watch_waiting = true
	_watch_client = HTTPClient.new()
	if _watch_client.connect_to_host(ip, port) != OK:
		printerr("Failed to connect to host to watch gameserver")

func _process(_delta):
	if _watch_client:
		_watch_client.poll()
		
		var status = _watch_client.get_status()
		if _watch_waiting and status == HTTPClient.STATUS_CONNECTED:
			_watch_waiting = false
			if _watch_client.request(HTTPClient.METHOD_GET, "/watch/gameserver", ["Content-Type: application/json"]) != OK:
				printerr("Failed to request watch gameserver")
		if status == HTTPClient.STATUS_BODY:
			var chunk = _watch_client.read_response_body_chunk()
			if chunk.size() > 0:
				var data = chunk.get_string_from_utf8()
				var json = JSON.parse(data)
				if json.error != OK:
					printerr("Failed to parse watch gameserver chunk: ", json.error_string)
				else:
					emit_signal("gameserver", json.result.result)
