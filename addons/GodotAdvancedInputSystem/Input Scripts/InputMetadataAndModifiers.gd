## An Intermediate container that holds Hardware input and its respective modifiers.
extends Resource

## The equivalent of hardware inputs like Keyboard keys, Mouse Button click, Gamepad buttons etc.
@export_storage var binded_input : InputMetadata

## An Array of modifers that the raw extracted Vector2 from binded_input is processed through before
## accumulated and passed to [InputAction] for final evaluation.
@export_storage var modifiers : Array[InputModifier]
