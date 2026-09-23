## A spreadsheet that links physical hardware bindings to logical [InputAction]s.[br]
## [br]
## To function, this profile must be assigned to a player controller within the Input Manager. 
## Every frame, the Input Manager routes device-specific [InputEvent]s to the player controller, 
## which then passes them down into this profile for evaluation.[br]
## [br]
## [b]Evaluation Flow:[/b][br]
## - [b]Iteration:[/b] The profile compares the incoming frame's [InputEvent]s against its list 
## of bindings using a strict top-down approach.[br]
## - [b]Extraction:[/b] If a binding determines it cares about an event, it extracts the raw input value.[br]
## - [b]Modification:[/b] Each extracted input is then passed through its specific list of modifiers.[br]
## - [b]Accumulated:[/b] Each processed value then directly accumulated (added) into a single Vector2 value.[br]
## - [b]Handoff:[/b] The profile immediately forwards this Vector2 value to the corresponding [InputAction].[br]
## - [b]Final Execution:[/b] The [InputAction] takes over to perform the last evaluation (applying modifiers and 
## checking for zero result) and then firing the final signal(if the evaluation yields a non-zero value).
class_name InputProfile extends Resource

## List of InputActions that are binded to their corresponding InputBindings list.
## The size of _action_list and _bindings_list are maintained internally, so never 
## add or remove entries directly.
@export_storage var _action_list : Array [InputAction]


## List of InputBindings that are linked to their corresponding InputAction.
## The size of _action_list and _bindings_list are maintained internally, so never 
## add or remove entries directly.
@export_storage var _bindings_list : Array[InputBindings]

## Defines whether the remaining inputs should be passed down the profile stack or not.[br]
## If [code]true[/code], the profile evaluation will be considered completed for that frame
## and the profiles lower in the profile_stack won't receive any inputs.[br]
## This property is ignored in the absolute profiles evaluations.
@export_storage var block_input_propagation : bool = true

var _caches: Array[InputEvent]

## internal use only function do no call manually or override.
func _evaluate_profile(events : Array[InputEvent], is_absolute_profile : bool, delta: float)->void:
	for i in _action_list.size():
		if _action_list[i] == null:
			continue
		_caches.clear()
		var action: InputAction = _action_list[i]
		var value: Vector2 = _bindings_list[i]._evaluate_inputs(events,_caches, action.consume_input && !is_absolute_profile)
		action._process_input(value,_caches,delta)


## internal use only function do no call manually or override.
func _interrupt_actions()->void:
	for action in _action_list:
		action._interrupted()

## To fetch an input action. If the index provided is greater than the actions in the list, it'll return null.
func fetch_input_action(index : int )->InputAction:
	if index>= _action_list.size():
		return null
	return _action_list[index]

## To fetch hard input bindings for an input action.
func fetch_input_bindings_for_action(action: InputAction)->InputBindings:
	var key: int = _action_list.find(action)
	if key != -1:
		return _bindings_list[key]
	return null

## To fetch an hard input bindings. If the index provided is greater than the actions in the list, it'll return null.
func fetch_input_bindings(index : int )->InputBindings:
	if index>= _bindings_list.size():
		return null
	return _bindings_list[index]

func remove_entry(index: int)->void:
	if index>=_action_list.size():
		return
	_action_list.remove_at(index)
	_bindings_list.remove_at(index)

## Add an empty entry with a null action and emppty bindings
func add_new_empty_entry()->void:
	_action_list.append(null)
	_bindings_list.append(InputBindings.new())

## Adds a new entry with the given data.
func add_new_entry(action: InputAction, bindings : InputBindings)->void:
	if bindings:
		_action_list.append(action)
		_bindings_list.append(bindings)

## Assign an action for a specific entry in the list of actions. Providing an index greater than
## the number of entries will return false
func set_action(index: int, action: InputAction)->bool:
	if _action_list.size() > index:
		_action_list[index] = action
		return true
	return false

## Assign a hardware binding list for a specific entry in the list of bindings. Providing an index greater than
## the number of entries will return false
func set_bindings(index: int, bindings: InputBindings)->bool:
	if _bindings_list.size() > index:
		_bindings_list[index] = bindings
		return true
	return false

## To fetch hard input bindings for an input action. Returns false if no such action was found in the list.
func set_input_bindings_for_action(action: InputAction, bindings: InputBindings)->bool:
	var key: int = _action_list.find(action)
	if key != -1:
		_bindings_list[key] = bindings
		return true
	return false

## Iterates through all the input bindings for all actions and replaces all the matching hardware inputs.
func replace_metadata_for_all_actions(From: InputMetadata, To: InputMetadata)->void:
	if not (From and To):
		return
	for binding in _bindings_list:
		binding.replace_all_metadata(From, To)

func _update()->void:
	_action_list = _action_list
	_bindings_list = _bindings_list

func _update_bindings()->void:
	_bindings_list = _bindings_list
