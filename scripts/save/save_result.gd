class_name SaveResult
extends RefCounted

var success: bool = false
var error_code: String = "none"
var message: String = ""
var data: SaveGameData = null

static func ok(p_data: SaveGameData = null) -> SaveResult:
	var r := SaveResult.new()
	r.success = true
	r.data = p_data
	return r

static func fail(code: String, msg: String) -> SaveResult:
	var r := SaveResult.new()
	r.success = false
	r.error_code = code
	r.message = msg
	return r
