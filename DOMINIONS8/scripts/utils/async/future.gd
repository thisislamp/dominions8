class_name Future extends RefCounted


## The result value of the Future.
var result = null:
	get=get_result

## The error the Future encountered, if any.
var error: Exception = null:
	get=get_error

var _state: _STATE = _STATE.PENDING
var _callbacks: Array[Callable]

static var CancelledError := Exception.new("Cancelled"):
	set(v): pass

enum _STATE {PENDING, CANCELLED, FINISHED}

signal _done(result)


func get_result():
	return result

func get_error():
	return error

func set_result(_result) -> void:
	if is_done():
		push_warning("Future already done")
		return

	result = _result
	_state = _STATE.FINISHED
	_emit_done()
	_invoke_callbacks()

func set_error(_error: Exception) -> void:
	if is_done():
		push_warning("Future already done")
		return
	if not _error:
		push_error("Invalid exception")
		return

	error = _error
	_state = _STATE.FINISHED
	_emit_done()
	_invoke_callbacks()

## Returns true if the future is cancelled.
func is_cancelled() -> bool:
	return _state == _STATE.CANCELLED

## Returns true if the future is finished or cancelled.
func is_done() -> bool:
	return _state in [_STATE.FINISHED, _STATE.CANCELLED]

## Cancel the future
func cancel() -> void:
	if is_done():
		return

	_state = _STATE.CANCELLED
	_emit_done()
	_invoke_callbacks()

## Adds a callback that will be called when the future finishes.  Can be optionally
## called deferred.  The callback should take one argument, the future object.
func add_done_callback(cb: Callable, deferred: bool = false) -> void:
	if deferred:
		_callbacks.append(_cb_deferred.bind(cb))
	else:
		_callbacks.append(cb)

## Waits for the task to be done and return the result or error.
func done_async():
	if is_done():
		return _get_result()
	elif is_cancelled():
		return CancelledError.raise()
	await _done
	return _get_result()

## Waits for the task to be done and returns the result.
func result_async():
	if is_done():
		return result
	elif is_cancelled():
		CancelledError.raise()
		return null
	await _done
	return result


func _cb_deferred(_result, cb: Callable):
	cb.call_deferred(_result)

func _emit_done() -> void:
	_done.emit(_get_result())

func _invoke_callbacks() -> void:
	for cb: Callable in _callbacks:
		cb.call(self)
	_callbacks.clear()
	_callbacks.make_read_only()

func _get_result():
	if error:
		return error
	else:
		return result
