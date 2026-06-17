@tool
class_name MCPLogger extends Node

static var _errors: Array[Dictionary] = []
static var _max_errors := 100
static var _mutex := Mutex.new()
static var _seq := 0


func _log_error(function: String, file: String, line: int, code: String,
				rationale: String, editor_notify: bool, error_type: int,
				script_backtraces: Array) -> void:
	_mutex.lock()
	var frames: Array[Dictionary] = []
	for backtrace in script_backtraces:
		for i in backtrace.get_frame_count():
			frames.append({
				"file": backtrace.get_frame_file(i),
				"line": backtrace.get_frame_line(i),
				"function": backtrace.get_frame_function(i),
			})

	var error_entry := {
		"timestamp": Time.get_ticks_msec(),
		"type": code,
		"message": rationale,
		"file": file,
		"line": line,
		"function": function,
		"error_type": error_type,
		"frames": frames,
	}
	if not _is_duplicate(error_entry):
		_seq += 1
		error_entry["seq"] = _seq
		_errors.append(error_entry)
		if _errors.size() > _max_errors:
			_errors.remove_at(0)
	_mutex.unlock()


static func _is_duplicate(entry: Dictionary) -> bool:
	if _errors.is_empty():
		return false
	var last := _errors[-1]
	return (last.get("file") == entry.get("file")
		and last.get("line") == entry.get("line")
		and last.get("message") == entry.get("message")
		and last.get("type") == entry.get("type"))


static func get_errors() -> Array[Dictionary]:
	return _errors


static func get_seq() -> int:
	return _seq


static func query(since: int, severity: String, limit: int) -> Dictionary:
	_mutex.lock()
	var cursor := _seq
	var total_count := _errors.size()
	var matched: Array[Dictionary] = []
	for entry in _errors:
		if int(entry.get("seq", 0)) <= since:
			continue
		if not _severity_matches(severity, int(entry.get("error_type", 0))):
			continue
		matched.append(entry)
	_mutex.unlock()

	var match_count := matched.size()
	var start_index := 0
	if limit > 0 and match_count > limit:
		start_index = match_count - limit
	var messages: Array[Dictionary] = matched.slice(start_index)

	return {
		"total_count": total_count,
		"match_count": match_count,
		"returned_count": messages.size(),
		"cursor": cursor,
		"messages": messages,
	}


static func _severity_matches(severity: String, error_type: int) -> bool:
	match severity:
		"error":
			return error_type != 1
		"warning":
			return error_type == 1
		_:
			return true


static func get_last_stack_trace() -> Array[Dictionary]:
	if _errors.is_empty():
		return []
	return _errors[-1].get("frames", [])


static func clear_errors() -> void:
	_mutex.lock()
	_errors.clear()
	_mutex.unlock()

