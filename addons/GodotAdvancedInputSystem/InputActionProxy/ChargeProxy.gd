## Intercepts and delays an action's execution until the input is physically released.
## Use this for mechanics like drawing a bow, charging a heavy attack, or channeling a spell. 
## The action only triggers if the input is held longer than the threshold before release.
##
## [b]STATE MODIFICATION CHART[/b][br]
## How the raw continuous input is translated by the proxy based on charge duration:[br]
## [kbd] +-----------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | Input Phase                 | Base Action    | Proxy Output              | [/kbd][br]
## [kbd] +-----------------------------+----------------+---------------------------+ [/kbd][br]
## [kbd] | On Initial Press            | STARTED        | DETECTED                  | [/kbd][br]
## [kbd] | Holding (Under Threshold)   | PROCESSING     | PENDING                   | [/kbd][br]
## [kbd] | Released (Under Threshold)  | ENDED          | CANCELLED (Fails)         | [/kbd][br]
## [kbd] | Holding (Past Threshold)    | PROCESSING     | PENDING                   | [/kbd][br]
## [kbd] | Released (Past Threshold)   | ENDED          | [STARTED | ENDED] (Fires) | [/kbd][br]
## [kbd] +-----------------------------+----------------+---------------------------+ [/kbd]
class_name ChargeProxy extends SingleActionProxy



## Defines the threshold for this proxy.
@export var charge_duration : float = 1.0:
	set(value):
		charge_duration = max(0.0, value)



func _input_action_fired(InContext: InputContext)->void:
	_context.value = InContext.value
	_context.elapsed_duration = InContext.elapsed_duration
	match InContext.execution_state:
		InputContext.STARTED:
			_context.execution_state = InputContext.DETECTED
		InputContext.PROCESSING:
			_context.execution_state = InputContext.PENDING
		InputContext.ENDED:
			if _context.elapsed_duration >= charge_duration:
				_context.execution_state = InputContext.STARTED | InputContext.ENDED
			else:
				_context.execution_state = InputContext.CANCELLED
	proxy_action.emit(_context)
