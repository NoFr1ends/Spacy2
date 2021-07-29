class_name JWT
extends Reference

enum Error {
	OK,
	ERR_INVALID_DATA,
	ERR_UNSUPPORTED_ALGORITHM
}

var signature_valid = false
var signing_method = ""
var claims = {}

func _convert_base64(base64: String) -> String:
	var mod = base64.length() % 4
	if mod > 0:
		for i in range(4 - mod):
			base64 += "="
	return base64.replace("-", "+").replace("_", "/")

func parse(jwt_string: String, key: String) -> int:
	var parts = jwt_string.split(".")
	if parts.size() != 3:
		return Error.OK
	
	var header = parts[0]
	var payload = parts[1]
	var signature = parts[2]
	
	var header_decoded = Marshalls.base64_to_utf8(_convert_base64(header))
	var payload_decoded = Marshalls.base64_to_utf8(_convert_base64(payload))
	var signature_decoded = Marshalls.base64_to_raw(_convert_base64(signature))
	
	var header_json = JSON.parse(header_decoded)
	var payload_json = JSON.parse(payload_decoded)
	
	if header_json.error != OK or payload_json.error != OK:
		return Error.ERR_INVALID_DATA
	
	if not "alg" in header_json.result:
		return Error.ERR_INVALID_DATA
	
	match header_json.result.alg:
		"HS256":
			signing_method = "HS256"
			signature_valid = verify_signature_hs256(header, payload, key, signature_decoded)
		_:
			signature_valid = false
	
	claims = payload_json.result
	
	return OK

func verify_signature_hs256(header: String, payload: String, key: String, expected_signature: PoolByteArray) -> bool:
	var context = HMACContext.new()
	if context.start(HashingContext.HASH_SHA256, key.to_utf8()) != OK:
		return false
	
	if context.update((header + "." + payload).to_utf8()) != OK:
		return false
	
	var signature = context.finish()
	return signature == expected_signature

func is_valid():
	if "exp" in claims:
		if claims["exp"] < OS.get_system_time_secs():
			return false
	return signature_valid
