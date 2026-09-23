---
layout: default
title: Architecture Details
nav_order: 4
---

# System Architecture & Deep Dive

> This document is for anyone who wants to know what goes on under the hood of the **Godot Advanced Input System (GAIS)**. If you just want to get your game up and running, you can safely skip this and check the [Getting Started Guide](Getting_Started.md).

---

## How Input Flows Through GAIS

Think of GAIS as a simple pipeline. When you press a key on your keyboard or push a joystick on your controller, the input travels through 5 clear stages before reaching your player:

```text
  [ Physical Button / Stick / Key ]
                 │
                 ▼
      1. InputManager (Autoload)
         - Catches raw inputs first
         - Keeps track of buttons being held down
         - Routes inputs to the right device ID
                 │
                 ▼
      2. PlayerController (Device)
         - Runs unblockable profiles (Pause / Dev Console)
         - Runs your active profile stack (Gameplay / Menus)
                 │
                 ▼
      3. InputProfile (Context)
         - Turns raw buttons into Vector2 values
         - Applies key-level modifiers (WASD math)
         - Combines multiple inputs into one vector
                 │
                 ▼
      4. InputAction (The Intent)
         - Applies final modifiers (like Normalize)
         - Converts to Bool, Float, or Vector2
         - Runs the state machine (STARTED -> PROCESSING -> ENDED)
                 │
         ┌───────┴───────┐
         │ (Direct)      │ (Optional Hijack)
         ▼               ▼
  [ Your Game ]   5. InputProxy
                     - Adds Holds, Combos, or Chords
                     - Adds PENDING and CANCELLED states
                         │
                         ▼
                  [ Your Game ]
```

---

## 1. InputManager (The Central Hub)

The `InputManager` is an autoload script that sits at the very start of the input pipeline.

### Why Not Just Use Normal Godot Events?
Normally, Godot only tells you when an input *changes* (you press a key down, or let it go). If you hold a key down for 5 seconds without moving it, Godot doesn't keep sending events every frame. 

Because GAIS needs to know when something is continuously held down (to run the `PROCESSING` state and track hold timers), `InputManager` steps in:
* It grabs raw events as soon as they arrive.
* Its `_process()` runs with a low priority number (`-1000`), ensuring it updates before the rest of your game scripts run.
* If a button is held down, it keeps that input alive every frame until the release event finally arrives.

### Device Routing
`PlayerController` objects are created automatically on demand. If you ask for controller `0`, it creates it. If an input comes from a device nobody is listening to, it gets ignored.

* **Default Mode `MERGED`:**
  * `ID 0`: Shared by Keyboard, Mouse, Touchscreen, and your first connected controller.
  * `ID 1+`: Your second controller, third controller, etc.
* **`SPLIT_KEYBOARD` Mode:**
  * `ID 0`: Only Keyboard and Mouse.
  * `ID 1+`: The Touchscreen and all controllers shift forward by one slot (your first controller is now `ID 1`).
* **`SPLIT_ALL` Mode:**
  * `ID 0`: Only Keyboard and Mouse.
  * `ID 1`: The Touchscreen
  * `ID 2+`:  All controllers shift forward by two slot (your first controller is now `ID 2`).

---

## 2. PlayerController (Handling Devices and Menus)

A `PlayerController` represents a single input device (like Keyboard 1 or Gamepad 1). It takes the events from the `InputManager` and pushes them through two sets of profiles:

### 1. Absolute Profiles (Unstoppable)
These profiles are checked first. They ignore all blocking rules and cannot consume events.
* **Why use this?** For things that must always work no matter what menu is open—like pressing `Esc` for the Pause Menu or `~` for the Dev Console.

### 2. The Profile Stack (Last In, First Out)
Next, it runs the normal profile stack in reverse order—the most recently added profile gets checked first.
* **Action Consumption:** If an action inside a profile has `consume_input = true`, that physical key event is swallowed immediately. Actions lower down the list won't see it.
* **Profile Blocking:** If a profile has its `block_propagation` box checked, it stops the whole chain right there. Profiles below it on the stack won't receive any inputs. This is how opening an inventory screen stops your character from walking around in the background.

---

## 3. InputProfile (Mapping Keys to Actions)

An `InputProfile` is your binding spreadsheet. It maps physical buttons and sticks to logical actions.

1. **Everything Starts as a Vector2:** Whenever a button or key is pressed, GAIS treats it as a `Vector2`:
   * Normal buttons/keys become `(1.0, 0.0)` when pressed, and `(0.0, 0.0)` when released.
   * 1D triggers and sliders place their value on the X-axis: `(value, 0.0)`.
   * Joysticks and mouse deltas keep their full `(x, y)`.
2. **Key Modifiers:** The vector passes through any modifiers attached to that specific key (like `SwitchAxis` or `Negate`).
3. **Combining Keys:** The modified vectors for all keys assigned to the same action are added together.
4. **Sent to Action:** That combined vector is handed over to the `InputAction`.

---

## 4. InputAction (The State Machine)

An `InputAction` is the action itself (like "Jump" or "Move"). It takes the combined vector from the profile, applies any final action-level modifiers (like `Normalize`), and casts it to the format your game wants:

* **`BOOLEAN`**: Looks at the X-axis. If it is not zero, it returns `true`.
* **`FLOAT`**: Grabs the X-axis value directly.
* **`VECTOR2`**: Forwards the full 2D vector as-is.

### How the State Machine Works
Every frame, the action checks its final vector:

* **`STARTED`**: The exact frame the input stops being zero. Fires once.
* **`PROCESSING`**: Fires every frame the input is held down.
* **`ENDED`**: The exact frame the input drops back to zero. Fires once.
* **`INTERRUPTED`**: Fires if the input was cut short unexpectedly (such as Alt-Tabbing or a menu suddenly swallowing the input).

Every time a state fires, it sends an `InputContext` containing the value, how long the button was held, and the original Godot event.

---

## 5. InputModifiers (Math Helpers)

An `InputModifier` is a tiny resource with a single job: take a `Vector2`, change its numbers, and return it.

Because they are modular resources, you can stack them anywhere:
* **`SwitchAxis`**: Swaps X and Y: `(x, y) -> (y, x)`.
* **`Negate`**: Flips the signs: `(x, y) -> (-x, -y)`.
* **`Deadzone`**: Ignores tiny joystick drift near the center.
* **`Clamp`**: Keeps values within a set minimum and maximum.
* **`Accumulate`**: Measures the total length of the vector and puts that number on the X-axis.
* **`Normalize`**: Keeps diagonal movement from being faster than straight movement.
* **`Scale`**: To increase the magnitude/length of the vector to a new value.

---

## 6. InputProxies (State Hijackers & Interceptors)

An `InputActionProxy` is a specialized `Resource` that sits between an `InputAction` and your gameplay code. Instead of your player script connecting directly to an `InputAction`, the proxy intercepts the action's signal, inspects how and when the player interacts with it, and emits its own modified `InputContext` through `proxy_action`.

```text
       ┌───────────────────────────┐
       │ InputAction (or Actions)  │
       └─────────────┬─────────────┘
                     │ action.connect()
                     ▼
       ┌───────────────────────────┐
       │     InputActionProxy      │
       │  - Intercepts Context     │
       │  - Evaluates Conditions   │
       │  - Emits Custom States    │
       └─────────────┬─────────────┘
                     │ proxy_action.emit()
                     ▼
       ┌───────────────────────────┐
       │  Gameplay Script (Player) │
       └───────────────────────────┘
```

---

### Execution Pipelines: Signal-Driven vs. Frame-Evaluated

How a proxy processes input depends directly on whether it can ride the underlying action's active signals or needs to tick independently during periods of silence:

#### 1. Instant & Signal-Driven (`SingleActionProxy`)
Because a standard `InputAction` already tracks hold time and drives its own continuous states (`STARTED` $\to$ `PROCESSING` $\to$ `ENDED`), most single-action behaviors do **not** need a separate frame loop.

* Proxies like **Hold**, **Charge**, or **Pulse** connect directly to their target action and evaluate conditions inside `_input_action_fired()` using the action's existing `elapsed_duration` and states.
* Modifications happen on the spot with zero latency and zero polling overhead.

#### 2. Two-Stage Frame Evaluation (`MultiActionProxy` & `SingleActionProcessingProxy`)
A proxy requires its own tick loop (`_evaluate_proxy(delta)`) hooked into `InputManager.inputs_processed` under two specific circumstances:

* **Evaluating Across Empty Gaps (`SingleActionProcessingProxy`):**  
  Used when a proxy must stay active and keep ticking *after* an action has completely stopped. A prime example is **`MultiTapProxy`**: after the first tap ends, the target `InputAction` returns to `NONE` and stops emitting. The proxy must tick independently across those empty in-between frames to measure the delay before the next tap arrives or time out into `CANCELLED`.
* **Synchronizing Multiple Actions (`MultiActionProxy`):**  
  Used for multi-key coordination like **`ConcurrentProxy`** (chords) or **`SequenceProxy`** (combos), where several distinct actions must be cached, synchronized, and resolved together at the end of the frame step.

#### Interruption Safety (`_handle_interruption_reroute`)
All proxies automatically monitor incoming actions for the `INTERRUPTED` state (triggered by losing window focus, Alt-Tabbing, or a higher-priority menu swallowing inputs). If an active action gets cut short, the proxy catches it, fires its own `INTERRUPTED` signal via `_fire_interrupt()`, resets its internal tracking values, and cleanly reverts to `NONE`.

---

### The Three Base Proxy Classes

GAIS provides three abstract base classes depending on the scope of your input logic:

* **`SingleActionProxy`**: Directly intercepts one action (`proxy_of`) via signals without tick overhead. Used for state modifications, instantaneous conversions, and actions whose conditions resolve while the key is active (such as `HoldProxy` or `PulseProxy`).
* **`SingleActionProcessingProxy`**: Intercepts one action (`proxy_of`) but hooks into `InputManager.inputs_processed` for per-frame `_evaluate_proxy(delta)` updates. Specifically designed for mechanics like `MultiTapProxy` that must track timeouts across cycles of inactive/ended states.
* **`MultiActionProxy`**: Intercepts an array of actions (`proxy_of_actions`) and receives per-frame delta ticks. Designed for multi-button coordination like chords (`ConcurrentProxy`) or sequential directional combos.

> **Modifying Multi-Action Lists:** When configuring a `MultiActionProxy` via code, never modify `proxy_of_actions` directly. Always use `add_action(action)` and `remove_action(action)` so the proxy can safely connect signals and manage cached action arrays.

---

### The Expanded 6-State Lifecycle & Bitmasking

Standard `InputAction` resources only use three exclusive states: `STARTED`, `PROCESSING`, and `ENDED`. 

Proxies expand this by injecting intermediate tracking and failure states, allowing gameplay code to react before an input finishes:

* **`DETECTED`**: The very first frame any monitored action begins. Useful for triggering instant cues (like sound effects or wind-up animations).
* **`PENDING`**: The condition is in progress but not yet satisfied (e.g., waiting for the next tap in a double-tap window, or waiting for a chord to complete).
* **`CANCELLED`**: The player let go too early or timed out before meeting the activation condition.
* **`STARTED`**: The activation conditions were fully met. Fires once.
* **`PROCESSING`**: All required actions continue to be held down after triggering.
* **`ENDED`**: The input was cleanly released after reaching `STARTED`/`PROCESSING`.

#### Why You Must Use `has_state()`
Because GAIS enforces a strict **one dispatch per frame** rule, proxies cannot batch separate signal dispatches. If a proxy needs to communicate multiple lifecycle flags on the same frame, it combines them via bitmasking. 

Because of this, direct equality checks (`context.execution_state == InputContext.STARTED`) can fail when other bit flags are active. **Always use `context.has_state(...)` when listening to an `InputActionProxy`:**

```gdscript
func _on_proxy_action(context: InputContext) -> void:
	if context.has_state(InputContext.STARTED):
		player.perform_action()
	elif context.has_state(InputContext.PENDING):
		ui_bar.set_progress(context.elapsed_duration)
	elif context.has_state(InputContext.CANCELLED):
		player.reset_stance()
```

---

### Creating Custom Proxies

You can easily build custom proxy behaviors by extending `SingleActionProxy`, `SingleActionProcessingProxy`, or `MultiActionProxy`. Pre-built templates showing all overrideable functions are located in:

```text
addons/GodotAdvancedInputSystem/InputActionProxy/Templates/
```

Simply override `_ready()`, `_input_action_fired()`, `_evaluate_proxy()`, or `_reset_context()` to implement custom timing, tap thresholds, or complex multi-key conditions.

---

## 7. Registries (Runtime Rebinding & Dynamic Icons)

Building player-facing settings menus typically introduces two headaches: converting raw engine input events into serializable data, and updating UI prompts so an Xbox button doesn't show up when using a PlayStation controller or keyboard. GAIS handles both through dedicated registry utilities.

---

### `InputProviderRegistry` (The Rebinding Engine)

`InputProviderRegistry` is an engine utility class instantiated via `InputProviderRegistry.new()`. Its primary role is to serve as a bi-directional translation bridge between Godot's transient `InputEvent` objects and GAIS's serializable `InputMetadata` resources.

```text
[ Physical Keypress / Controller Input ]
                  │
                  ▼
          Godot InputEvent
       (InputEventKey, Joypad, etc.)
                  │
                  ▼
     InputProviderRegistry.new()
                  │
                  ▼
          GAIS InputMetadata
   (Serializable, Profile-Ready Data)
```

#### Why Not Store Raw `InputEvent`s?
Native Godot `InputEvent` objects carry instance-specific overhead and platform quirks, making them clunky to save to disk or swap dynamically inside an `InputProfile`. 

`InputMetadata` strips out that noise, storing only the pure identity of the hardware input (key code, joypad button index, motion axis, etc.).

#### How It's Used:
When building a custom **"Press any key to rebind"** menu:
1. Wait for the player's next raw event in `_unhandled_input(event)`.
2. Pass that `InputEvent` to the registry to generate clean `InputMetadata`.
3. Swap or update the hardware row in the active `InputProfile` with that metadata—no manual engine-level input map rewriting required.

For any confusion, you can also checkout the demo and see how it was structured for that setup.

---

### `InputIconRegistry` (Context-Aware UI Glyphs)

`InputIconRegistry` is a custom Godot `Resource` that pairs `InputMetadata` keys with visual UI assets (icons and button prompt glyphs).

Instead of hardcoding separate UI paths for every input device, you configure an `InputIconRegistry` asset in your project, map your controller prompt textures or sprite sheets, and query it dynamically.

#### Sprite-Sheet Sampling & Resolution
* **Automatic Coordinate Slicing:** The registry supports uniform sprite sheets. By configuring cell size and layout rules, it cuts out the exact button glyph without requiring dozens of individual image files.
* **Fallback Display:** If an icon texture isn't assigned for an input (such as rare keyboard keys), it gracefully falls back to a formatted text label (e.g., `"Space"`, `"Shift"`, `"F12"`).

#### Dynamic UI Updating:
```gdscript
@export var icon_registry: InputIconRegistry

func update_prompt(action_metadata: InputMetadata) -> void:
	# Fetches either a Texture2D or a formatted fallback String
	var display_item = icon_registry.get_display_item(action_metadata)
	
	if display_item is Texture2D:
		prompt_texture_rect.texture = display_item
		prompt_label.visible = false
	else:
		prompt_label.text = str(display_item)
		prompt_texture_rect.visible = false
```

Whenever the active controller changes (e.g., the player picks up a DualSense instead of an Xbox controller), passing the metadata back through `get_display_item()` instantly updates your UI with the correct platform icon.