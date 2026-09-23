## Represents a single physical input device (e.g., gamepad, keyboard/mouse, or touch screen).[br]
## It acts as a centralized hub that collects and holds all input data internally, serving as the 
## primary source that game logic subscribes to when looking for signals from that specific hardware.
class_name PlayerController extends RefCounted

var _input_bucket: Array[InputEvent]

var _absolute_profiles : Array[InputProfile]
var _profile_stack : Array[InputProfile]

## Sets the process mode for profile stack. The profiles in stack are always processed in a priority based system.
## Where the last profile is processed once and the leftovers are passed on to the lower profiles. [br][br]
## If [code]true[/code], the controller will collect the inputs and direct them to the profiles in the stack, if
## [code]false[/code], all the inputs will be ignored and the profiles will stay inactive.[br][br]
## Changing the mode while an input is processing will interrupt the input.
var process_profile_stack: bool = true:
	set(value):
		process_profile_stack = value
		if not value:
			interrupt_stack()

## Sets the process mode for absolute profiles. Absolute profiles are the profiles that are always passed all the
## available inputs that frame. All toggles relating to filtering or blocking will be ignored for them.[br][br]
## If [code]true[/code], the controller will collect the inputs and direct them through all the profiles, if
## [code]false[/code], the inputs will be ignored and the profiles will stay inactive.[br][br]
## Changing the mode while an input is processing will interrupt the input.
var process_absolute_profiles: bool = true:
	set(value):
		process_absolute_profiles = value
		if not value:
			for profile in _absolute_profiles:
				profile._interrupt_actions()

## Adds a profile the list of absolute profiles. Every profile in this list will always get all the inputs without
## any except. Any blocking or consumption boolean will be ignored.[br]
## Will return [code]true[/code], if the profile is not already in the list, otherwise [code]false[/code]
func add_absolute_profile(profile : InputProfile)->bool:
	if _absolute_profiles.has(profile):return false
	_absolute_profiles.append(profile)
	return true

## remove the provided profile from the list.[br]
## return [code]true[/code] if the operation was successful, [code]false[/code] if no such profile was present in the list.
func remove_absolute_profile(profile : InputProfile)->bool:
	if _absolute_profiles.has(profile):
		_absolute_profiles.erase(profile)
		return true
	return false

## Pushes [param profile] onto the top of the stack.[br]
## Inputs are evaluated by the newest profile first; unhandled inputs fall through to underlying profiles.[br]
## Returns [code]true[/code] if the profile was added, or [code]false[/code] if it is already present in the stack.
func push_profile(profile : InputProfile)->bool:
	if _profile_stack.has(profile):return false
	interrupt_stack()
	_profile_stack.push_back(profile)
	return true

## Removes the last profile from the stack.[br]
## returns [code]false[/code] if the stack is already empty, otherwise [code]true[/code]
func pop_profile()->bool:
	interrupt_stack()
	return _profile_stack.pop_back()

## Sends an interruption signal through all the profiles in the profile_stack. Causing a chain interruption event
## and reseting all the actions to the default state.
func interrupt_stack()->void:
	for profile in _profile_stack:
		profile._interrupt_actions()

## Same as [method interrupt_stack] but also affects absolute_profiles.
func interrupt_controller()->void:
	for profile in _absolute_profiles:
		profile._interrupt_actions()
	interrupt_stack()

func _evaluate_profiles(delta: float)->void:
	if _input_bucket.is_empty():
		return
	if process_absolute_profiles:
		for profile in _absolute_profiles:
			profile._evaluate_profile(_input_bucket, true, delta)
	if process_profile_stack:
		for i in range(1, _profile_stack.size() + 1):
			_profile_stack[-i]._evaluate_profile(_input_bucket, false, delta)
			if _profile_stack[-i].block_input_propagation or _input_bucket.is_empty():
				break
	_input_bucket.clear()
