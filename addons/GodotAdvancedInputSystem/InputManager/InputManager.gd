## Input Manager that processes, filters, accumulates and split inputs among player controllers to then
## be processed by profiles and then finally getting emitted by InputActions
extends Node

## Called at the very end when all input processing has been completed for that frame.
## All InputActions have fired by this signal except proxies. This instead is used
## by proxies to process their end of the InputAction processing. It's called every frame
## even when there is no new event.
signal inputs_processed(delta: float)




## All different types of input devices are routed to the 1st Player Controller (Index 0). 
##
## Additional controllers (Controller 2, Controller 3, etc.) are assigned to Index 1 and onwards.
##
## [br]• Player Controller 1 (Index 0) routes: Keyboard-Mouse, Touch Screen, and Controller 1.
##
## [br]• Player Controller 2 (Index 1) routes: Controller 2 (and so on).
##
## [br] Use cases: Standard single-player games where players can seamlessly switch between different
## input devices to control the same character.
const MERGED = 0

## Keyboard and mouse inputs are strictly routed to the 1st Player Controller (Index 0). 
##
## Touch screen inputs and Controller 1 are routed to the 2nd Player Controller (Index 1). 
##
## [br]• Player Controller 1 (Index 0) routes: Keyboard-Mouse.
##
## [br]• Player Controller 2 (Index 1) routes: Touch Screen, Controller 1.
##
## [br]• Player Controller 3 (Index 2) routes: Controller 2 (and so on).
##
## [br] Use cases: Local co-op PC games where Player 1 uses the keyboard/mouse and Player 2 uses a gamepad.
const SPLIT_KEYBOARD = 1

## All input sources are strictly isolated into distinct slots. 
##
## [br]• Player Controller 1 (Index 0) routes: Keyboard-Mouse.
##
## [br]• Player Controller 2 (Index 1) routes: Touch Screen.
##
## [br]• Player Controller 3 (Index 2) routes: Controller 1.
##
## [br]• Player Controller 4 (Index 3) routes: Controller 2 (and so on).
##
## [br] Use cases: Asymmetrical local multiplayer games where unique roles require strictly separated hardware types.
const SPLIT_ALL = 2


## The active routing mode determining how hardware inputs are assigned to Player Controllers.[br]
## Default mode is [kbd]MERGED[/kbd].
var controller_mode : int = MERGED


# The list of created controller objects.
var _current_controllers : Array[PlayerController]


#region input processing

#region deadzones
## The deadzone for Gamepad joystick only, to account for stick drift. Any analog input
## with its absolute value under this deadzone won't be passed on to the InputActions
## and will be completely ignored.
var default_thumbstick_deadzone: float = 0.1

## The deadzone for Gamepad triggers. Altough triggers don't normally have any drift.
## Its still better than nothing.
var default_trigger_deadzone: float = 0.02
#endregion


#region cache dictionaries
#----------------- Input Caches ----------------
var _input_cache: Dictionary[int, InputEvent]
var _update_status: Dictionary[int, bool]
var _end_cache: Dictionary[int, InputEvent]
#----------------- end ----------------------
#endregion

#region cache functions
#const MOUSE_MOTION_KEY: int = 10

func _get_hash(event:InputEvent)->int:
	# 0 is reserved for deadzone
	if event is InputEventKey:
		if event.physical_keycode == 0:
			return 0
		return -event.physical_keycode # negative values to avoid collision with its enormous 7 digit numbers.
	elif event is InputEventMouseButton:
		if event.button_index == 0:
			return 0
		return event.button_index # 1-9 for its buttons
	elif event is InputEventMouseMotion:
		return 10 # MOUSE_MOTION_KEY
	elif event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_INVALID, JOY_BUTTON_SDL_MAX, JOY_BUTTON_MAX:
				return 0
		
		return 11 + event.button_index # 11-36 (26 from button list[0-25])
	elif event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_INVALID, JOY_AXIS_SDL_MAX, JOY_AXIS_MAX:
				return 0
		return 37 + event.axis # 37-42 (6 from axis [0-5])
	elif event is InputEventMagnifyGesture:
		return 43
	elif event is InputEventPanGesture:
		return 44
	elif event is InputEventScreenDrag:
		return 45 + event.index
	elif event is InputEventScreenTouch:
		return 100 + event.index
	return 0

func _is_end_event(event: InputEvent)->bool:
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT:
		# Microscopic noise floor: just clean up tiny resting jitter
			return event.axis_value < default_trigger_deadzone
		else:
			# Thumbsticks deadzone (e.g., 0.15)
			return abs(event.axis_value) < default_thumbstick_deadzone
	if event is InputEventKey \
	or event is InputEventMouseButton \
	or event is InputEventJoypadButton \
	or event is InputEventScreenTouch:
		return event.is_released() or event.is_canceled()
	return false

func _set_end_state(key: int, event: InputEvent) -> void:
	# Only cache events that actually have a hold/release lifecycle
	if event is InputEventKey \
	or event is InputEventMouseButton \
	or event is InputEventJoypadButton \
	or event is InputEventScreenTouch:
		_end_cache[key] = event
	if event is InputEventJoypadMotion:
		event.axis_value = 0
		_end_cache[key] = event

func _get_end_state(key: int, event: InputEvent) -> InputEvent:
	# Zero out the stale event's deltas and return it as the final frame state
	if event is InputEventMouseMotion:
		event.relative = Vector2.ZERO
		event.screen_relative = Vector2.ZERO
		event.velocity = Vector2.ZERO
		return event
	elif event is InputEventScreenDrag:
		event.relative = Vector2.ZERO
		event.screen_relative = Vector2.ZERO
		event.velocity = Vector2.ZERO
		return event
	elif event is InputEventPanGesture:
		event.delta = Vector2.ZERO
		return event
	elif event is InputEventMagnifyGesture:
		event.factor = 1.0 # 1.0 is the neutral resting scale for zoom!
		return event
		
	var val = _end_cache.get(key)
	if val != null:
		_end_cache.erase(key)
		return val
		
	return null

# empties all caches
func _refresh_cache()->void:
	_end_cache.clear()
	_input_cache.clear()
	_update_status.clear()

func _update_event(old_event: InputEvent, new_event: InputEvent) -> InputEvent:
	if not (old_event and new_event):
		return new_event
	
	if new_event is InputEventMouseMotion:
		new_event.relative += old_event.relative
		new_event.screen_relative += old_event.screen_relative
		# Note: 'position' and 'velocity' safely retain the latest snapshot from new_event
		return new_event
		
	elif new_event is InputEventScreenDrag:
		new_event.relative += old_event.relative
		new_event.screen_relative += old_event.screen_relative
		return new_event
		
	elif new_event is InputEventPanGesture:
		new_event.delta += old_event.delta
		return new_event
		
	elif new_event is InputEventMagnifyGesture:
		# Scale factors must be multiplied
		new_event.factor *= old_event.factor
		return new_event
	
	
	# (Keys, Mouse Buttons, Joypad Buttons, Joypad Axes, Screen Touch)
	# They have no deltas to sum, so we simply return the latest frame snapshot.
	return new_event

# updates the inputs in the caches from the input bucket
func _update_cache()->void:
	for event in _input_bucket:
		var key: int = _get_hash(event)
		var is_end: bool = _is_end_event(event)
		if is_end:
			if _input_cache.get(key, null):
				_set_end_state(key,event)
		else:
			if _update_status.get(key, false):
				var old_event: InputEvent = _input_cache.get(key)
				_input_cache.set(key, _update_event(old_event, event))
			else:
				_update_status.set(key, true)
				_input_cache.set(key,event)
	_input_bucket.clear()

#endregion

#endregion

var _dead_keys: Array[int]

func _fill_inputs()->void:
	for key in _input_cache:
		var is_updated: bool = _update_status.get(key, false)
		var entry: InputEvent = _input_cache.get(key, null)
		if not entry:
			_dead_keys.append(key)
		elif is_updated:
			_process_inputs(entry)
			_update_status.set(key, false)
		else:
			var end_input: InputEvent = _get_end_state(key, entry)
			if end_input:
				_process_inputs(end_input)
				_dead_keys.append(key)
			else:
				_process_inputs(entry)
	for key in _dead_keys:
		_input_cache.erase(key)
		_update_status.erase(key)
	_dead_keys.clear()


func _ready() -> void:
	# To make sure this is always the one processing the inputs before its processed by any listener node.
	process_priority = -1000 
	process_mode = Node.PROCESS_MODE_ALWAYS



var _input_bucket: Array[InputEvent]

func _input(event: InputEvent) -> void:
	_input_bucket.append(event)

## An input cycle once started cannot be skipped safely as it'd break the internal state machine [kbd](STARTED->PROCESSING->ENDED)[/kbd][br]
## However, the inputs that are yet to start can still be skipped from starting altogehter.[br][br]
## Treat this function the same as [method Viewport.set_input_as_handled]. However,
## the result is only evident if the event is an initializing event. If called within
## [kbd]PROCESSING[/kbd] state, the result varies depending on the event and is completely ignored for cycle ending events
## that would trigger the [kbd]ENDED[/kbd] state.[br][br]
## If the cycle should be forcefully stopped at any point, use [method interrupt_all_controllers] instead.
func skip_event_start()->void:
	var last_event: InputEvent = _input_bucket.back()
	if last_event and not _is_end_event(last_event):
		_input_bucket.pop_back()



func _notification(what: int) -> void:
	# Only trigger on full OS focus loss.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		interrupt_all_controllers()


func _process_inputs(event: InputEvent)->void:
	var controllers_count: int = _current_controllers.size()
	
	if controllers_count == 0:
		return
	
	var mode_offset : int = controller_mode

	if event is InputEventKey or event is InputEventMouse:
		if controllers_count:
			_current_controllers[0]._input_bucket.append(event)
	elif event is InputEventFromWindow:
		var index: int = clampi(mode_offset , 0,1)
		if  index < controllers_count:
			_current_controllers[index]._input_bucket.append(event)
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		var index: int = event.device + mode_offset
		if  index < controllers_count:
			_current_controllers[index]._input_bucket.append(event)


var _is_interrupted: bool = false

func _process(delta: float) -> void:
	if _is_interrupted:
		_is_interrupted = false
		_input_bucket.clear()
		return
	_update_cache() # updating the cache with new inputs this frame
	_fill_inputs() # take the updated cache dictionary to pass this frame's inputs into their respective controllers
	
	for controller in _current_controllers:
		controller._evaluate_profiles(delta)
	
	inputs_processed.emit(delta)

## The hard limit for connected controllers count is 16, if all input devices are split then it becomes 18 
## (0 is keyboard mouse, 1 is screen touch inputs and controllers are 2 onwards). So maximum supported index 
## is up to 17. Providing a higher index or negative index will return null.[br]
## This functions create the PlayerController objects on demand. The controllers don't exist until asked for.
## and afterwords exist till the end of session, whether being used or not.
func get_player_controller(index: int) -> PlayerController:
	if index < 0 or index > controller_mode + 15: 
		return null
		
	var current_size: int = _current_controllers.size()
	
	if index < current_size:
		return _current_controllers[index]
	
	_current_controllers.resize(index + 1)
	
	for i in range(current_size, index + 1):
		_current_controllers[i] = PlayerController.new()
		
	return _current_controllers[index]

## Defines whether the profiles within the profiles_stack should process or stop.[br]
## Does not effect the Player controllers created after calling this function.
func set_profile_stack_process_mode(active: bool)->void:
	for controller in _current_controllers:
		controller.process_profile_stack = active

## Defines whether the profiles within the absolute_profiles_list should process or stop.[br]
## Does not effect the Player controllers created after calling this function.
func set_absolute_profiles_process_mode(active: bool)->void:
	for controller in _current_controllers:
		controller.process_absolute_profiles = active

## Sends an interruption signal through all the PlayerController's profile_stacks. Causing a chain interruption event
## and reseting all the actions to the default state.
func interrupt_all_profile_stacks()->void:
	for controller in _current_controllers:
		controller.interrupt_stack()

## Sends an interruption signal through all the PlayerControllers. Causing a chain interruption event
## and reseting the state of the whole InputManager.
func interrupt_all_controllers()->void:
	_is_interrupted = true
	_refresh_cache()
	for controller in _current_controllers:
		controller.interrupt_controller()
