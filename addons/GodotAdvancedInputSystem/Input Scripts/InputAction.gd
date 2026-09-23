## An InputAction is a logical representation of player's hardware inputs that should lead to 
## a specific result such as moving, driving, shooting, jumping and so on.[br]
## [br]
## The need for InputAction being that some inputs may come ready to be use as provided(eg MouseMotion),
## while others need to be combined before used(eg, WASD for walk), and some may not even come from
## the same source yet lead to same results(eg, WASD from keyboard and Left Thumbstick from controller,
## yet all leading to the same action of moving the character).[br]
## [br]
## In such regard InputAction acts as the middle man that converts all those hardware inputs into a
## single useful value.
## [br]
## [b]Technical:[/b][br]
## 1. All inputs in the raw form are calculated as Vector2 and then trimmed down to [member value_type].[br]
## 2. The action stays inactive/will not fire as long as its value evaluates to [constant Vector2.ZERO][br]
## 3. InputAction doesn't just emit a plain value but a context object that contains more detail such as 
## trigger Input, elapsed duration and so on. One of these details include [member InputContext.executon_state].
## It contains the current state of the InputAction as it fires the context. 
## [br]
## [b]Execution States (Ordered):[/b][br]
## - [b]NONE:[/b] Inactive (input is evaluated as ZERO). No signal is sent.[br]
## - [b]STARTED:[/b] Sends a signal once on the first frame a non-zero input is evaluated.[br]
## - [b]PROCESSING:[/b] Keeps sending a signal every frame as long as the input continues.[br]
## - [b]ENDED:[/b] Sends a signal once when the input stops or evaluates to ZERO.[br]
## - [b]INTERRUPTED:[/b] Triggered by the input manager when an abrupt change happens (like switching 
## profiles mid-input). The input is forcefully halted and reseted to inactive/NONE.[br]
## [br]
## [b]Important Rules:[/b][br]
## 1. [b]Strict order:[/b] A single InputAction only fires once in a single frame(except interruption).[br]
## 2. [b]Mutual Exclusivity:[/b] All states are mutually exclusive and will never appear together.
## (this does not apply to proxies).[br]
## 3. [b]Quick Taps:[/b] If a key or button is pressed for only one frame, the action jumps straight 
## from [code]STARTED[/code] to [code]ENDED[/code] on the next frame, skipping [code]PROCESSING[/code].[br]
## 4. [b]Interruption Handling:[/b] In case of interruption, the state is forcefully reset to [code]NONE[/code]
## after [code]INTERRUPTED[/code], and the [code]ENDED[/code] state will [b]not[/b] fire.
class_name InputAction extends Resource

## The context is polled (Using the same InputContext with updated values). So directly updating or capturing 
## the context is not recommended until you know what you're doing. Also once the context is updated, the state/
## values of context persist for the whole frame and can be checked at any time within the frame. However, the
## interrupted state is one call pass and the state is reseted to NONE on the very frame after firing.
signal action(context : InputContext)

## Called when the state resets to NONE from any other state
signal state_reset

enum ValueType {
	## The emitted value will be a boolean. Only x-axis of constructed vector is considered for value.
	BOOLEAN,
	## The emitted value will be a float. Only x-axis of incoming vector is considered for value.
	FLOAT,
	## The emitted value will be a Vector2. Sources that do not originally provide a vector2 will be modified
	## into a vector where the incoming value will be placed in x-axis and y-axis being left as 0.
	VECTOR
}

## Defines the value that the listener should receive.
@export var value_type : ValueType = ValueType.BOOLEAN

## The final list of modifiers that the constructed value will be processed through before being considered
## for evaluation. The order of applying modifers is always top to down.
@export var Modifiers : Array[InputModifier]

## If [code]true[/code], the InputEvent event that are relevant to this action's InputBindings will be consumed 
## and won't be passed on to the lower action Bindings, even within the same profile.[br][br]
## Input consumption works on the whole domain of input source instead of only the input specified in binding.[br][br]
## For normal inputs like buttons and touch, it works as expected and will consume that whole InputEvent.
## However for inputs that inherentially possess an axial or vector result like MouseMotion,
## MouseWheel(yes, this one too), ScreenSwipe, Gamepad Thumstick, etc. Even having a partial input binding 
## like Mouse Motion UP will consume the whole mouse motion. Similary for Gamepad Thumbstick, a partial
## input like Gamepad Left Thumstick UP will consume all the inputs belonging to Left Thumbstick. 
@export var consume_input : bool = false

## The InputContext that is passed around to the listeners.
## This context uses the concept of polling which means instead
## of creating a new context every frame when an input arrives. 
## This single context is updated with new values and passed again.
## It also means that the value of context persists for the
## whole frame until updated in the next frame and can be accessed
## at any time.
var _context: InputContext = InputContext.new(self)

## internal use only function do no call manually or override.
func _interrupted()->void:
	if _context.execution_state == InputContext.NONE:
		return
	_reset_context()
	_context.execution_state = InputContext.INTERRUPTED
	action.emit(_context)
	_context.execution_state = InputContext.NONE
	state_reset.emit()

## internal use only function do no call manually or override.
func _set_value_type(InValue: Vector2)->Variant:
	match value_type:
		ValueType.BOOLEAN:
			var magnitude:float = abs(InValue.x)
			return bool(magnitude)
		ValueType.FLOAT:
			return InValue.x
	return InValue

## internal use only function do no call manually or override.
func _process_input(InValue: Vector2 , cached_inputs: Array[InputEvent], delta: float)->void:
	if InValue != Vector2.ZERO:
		for modifier in Modifiers:
			InValue = modifier.evaluate(InValue)
	
	match _context.execution_state:
		InputContext.NONE:
			if InValue == Vector2.ZERO:
				return
		InputContext.ENDED:
			if InValue == Vector2.ZERO:
				_reset_context()
				state_reset.emit()
				return
			else:
				_reset_context()
	
	_context.cached_inputs.append_array(cached_inputs)
	_context.elapsed_duration += delta
	_context.processing_duration += delta
	_context.value = _set_value_type(InValue)
	
	match _context.execution_state:
		InputContext.NONE:
			_context.execution_state = InputContext.STARTED
			_context.elapsed_duration = 0
			_context.processing_duration = 0
		InputContext.STARTED:
			if InValue == Vector2.ZERO:
				_context.execution_state = InputContext.ENDED
			else:
				_context.execution_state = InputContext.PROCESSING
				
		InputContext.PROCESSING:
			if InValue == Vector2.ZERO:
				_context.execution_state = InputContext.ENDED
	
	action.emit(_context)

## internal use only function do no call manually or override.
func _reset_context()->void:
	_context.cached_inputs.clear()
	_context.elapsed_duration = 0
	_context.processing_duration = 0
	_context.value = _set_value_type(Vector2.ZERO)
	_context.execution_state = InputContext.NONE
