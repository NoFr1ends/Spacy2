tool
extends EditorScript

func _run():
	var jwt = JWT.new()
	if jwt.parse("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2Mjc1OTQzNTUsInVzZXJuYW1lIjoidGVzdDEyMyJ9.Pr4pRKOrytcNIZvH68fcRrPSlXbWmFhuzDYk8bogmsA", "test123") != OK:
		printerr("Failed to parse JWT")
	
	if jwt.is_valid() and jwt.signing_method == "HS256":
		print("JWT is valid")
	else:
		printerr("JWT is invalid")
		return
	
	if jwt.claims["username"] == "test123":
		print("Username okay")
	else:
		print("Username invalid")
