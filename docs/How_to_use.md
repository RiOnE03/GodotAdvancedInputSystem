---
layout: default
title: How to Use
nav_order: 3
---

# How to Use GAIS

To get started, let's first think about what you actually want from an input. 

In most cases, you just want a signal that yells, *"Hey, an input arrived!"* along with a value you can actually use. Like an input for moving your character, making them jump, shoot, crouch, or sprint. In all these cases, what you want is a specific tag for an action, and a value that makes sense for it (e.g., movement(Tag) should be a 2D vector(value), while a jump(Tag) is just a simple trigger(value) to add upward velocity).

With that in mind, let's start with `InputAction`.

---

## 1. InputAction

Think of an **`InputAction`** as a player's **intent**, completely separate from physical buttons. 

Your character script shouldn't care if the player tapped the `Spacebar`, clicked the left mouse button, or smashed the `A` button on an Xbox controller. It just needs to know: *"Did the player want to **Jump**?"* 

That's what an `InputAction` is. It's a resource representing the concept of an action (like "Jump", "Shoot", or "Move"). You tell your character to listen to the action itself, and let the rest of the system worry about which physical keys actually trigger it.

In simpler terms, an `InputAction` is just a Resource that a listener bind to, and it tells the listener when that action is happening, passing along a bunch of useful data to help the listener react.

So let's create one! Follow along:

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/Create_InputAction.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

> **Tip:** You can read about what each property does directly in the Godot Inspector! Every part of the plugin is fully documented in Godot's native documentation system.

To listen for this action in your character script, you connect it like this:

```gdscript
@export var jump_action: InputAction

func _enter_tree() -> void:
	jump_action.action.connect(jump)

func _exit_tree() -> void:
	jump_action.action.disconnect(jump)

func jump(context: InputContext) -> void:
	if context.execution_state == InputContext.STARTED and is_on_floor():
		velocity.y = JUMP_VELOCITY
```

That's it for the `InputAction`! But wait, you're probably wondering... what the heck is an `InputContext`? Let's go through that next!

---

## 2. InputContext

This is the object that an action passes to your functions instead of a simple, boring value. It carries a bunch of useful information.

**`execution_state`:** The input system here works on a self-sustained small state machine which flows exactly like this: `STARTED -> PROCESSING -> ENDED`.

* **`STARTED`**: The initial state representing that the input just arrived. It only fires **once** and never again until the state machine resets.
* **`PROCESSING`**: The follow-up state that fires **every frame**, representing that the input is still being held/is active.
* **`ENDED`**: The final state that fires **only once**, telling you the input has been released or stopped.

This state machine flow is absolute and will always arrive in this order—it's up to you to decide how to use them. Also, the state coming from a raw `InputAction` is always exclusive, meaning you can check it directly with a `match` statement or an `==` comparison.

The `InputContext` also carries other juicy info:
* The actual **value** expected from the action (like a Vector2 or a float).
* The **elapsed time** since the action started.
* A list of all the raw **`InputEvent`** objects responsible for this action (useful if you need highly specific data like mouse motion velocity, pen pressure, or touchscreen finger index).
* The **sender action** itself, which is super useful for complex, multi-action systems.

Now, how are we gonna bind this action to actual hardware inputs? For that, we use `InputProfiles`.

---

## 3. InputProfile

Let's first create one!

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/Create_InputProfile.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

Now that we have created our profile, the next step is to tell the system we want to use it. To do that, you first fetch the input device (source) that you want to accept inputs from—like a controller, a keyboard/mouse, or a touchscreen.

```gdscript
@export var player_character_profile: InputProfile

func _ready() -> void:
	InputManager.get_player_controller(0).push_profile(player_character_profile)
```

**Wait, what just happened!?** How does this explain which device I subscribed to?

Don't worry! The `index = 0` practically means *"give me the first input device of its kind."* Godot (and even your operating system) doesn't separate multiple keyboards or mice into different devices, so they all share index `0`. A touchscreen will also share index `0`, and your first connected controller also uses index `0`. The next controller uses index `1`, and so on. 

For a standard single-player game, you almost always stick with index `0`.

*"What!? But then what about local co-op? How do I make the controller and keyboard act as separate devices if they both share ID 0?"*

Easy! You just change the default controller mode to split the keyboard out:

```gdscript
InputManager.controller_mode = InputManager.SPLIT_KEYBOARD
```

Now, Keyboard & Mouse gets exclusive rights to index `0`, while the touchscreen and all connected gamepads shift forward by one (so your first controller is now index `1`).

*(The `InputManager` comes with a few more handy features like this, so reading its Godot docs right after installing the plugin is highly recommended!)*

---

#### Absolute Profiles (The Unblockables)

While we are on the topic of profiles, there is another option within each `PlayerController` called `absolute_profiles`. These behave a bit differently from the normal profiles you just pushed onto the stack.

Profiles added to the `absolute_profiles` list are always processed *before* the normal stack profiles. More importantly, any input that passes through them is **never consumed or blocked**. An absolute profile will *always* receive its input, no matter what else was added to the list.

**So why do we need this?** 
Well... it's a massive nice-to-have. When you push a normal profile onto the stack (like opening an Inventory or riding a Mount), it often blocks the inputs beneath it so your character doesn't walk around while navigating a menu. 

But an Absolute Profile ignores all of that. It always fires. 

**When would you use this?** 
You use it for global actions that should absolutely never be blocked by gameplay context. Think of pressing `Esc` to open the pause menu, or `Tab` to open the developer command console. By putting these in an absolute profile, you guarantee they will always work—whether the player is walking, driving, or digging through their inventory!

---

## 4. InputModifiers (Accumulation & Trimming)

Now that we have our pipeline built, let's talk about some cool stuff. Let's look at how you'd combine WASD keys to make a single `Vector2` output for movement.

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/Adding_Modifiers_WASD.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

Now now! Hold your horses! That wasn't black magic! Let's break it down into steps.

Think about the `W` key. When a player presses it, they expect their character to go upwards. In Godot's 2D space, "up" is `Vector2(0, -1)`. But a key is just a button! How do we convert a single button press into a specific 2D vector?

Here is a secret about GAIS: when any key is pressed, the extracted result is *always* treated as a `Vector2` under the hood. For simple digital buttons, it just puts the value on the X-axis. So pressing `W` yields `(1, 0)`. Releasing it yields `(0, 0)`. 

But we want `(0, -1)`, not `(1, 0)`! 

We use **Modifiers** to fix this on the fly:
1. For `W`, we added a **SwitchAxis** modifier. It swaps the X and Y values. 
   `(1, 0) -> (0, 1)`
2. Then, we add a **Negate** modifier, which multiplies the vector by -1. 
   `(0, 1) -> (0, -1)`

Boom! We got our `(0, -1)` vector. All the other directional keys follow a similar pattern of modifiers to yield their specific directions. Finally, the `InputAction` combines all the results from the individual keys and adds them together to create your final movement vector.

**But wait! Something ain't right...** 

We just created a raw vector. If the player presses `W` and `D` together, the vector becomes `(1, -1)`. The magnitude of a diagonal vector is `1.414`, which means your player will run *much faster* diagonally than they do walking straight! We need to normalize it. But where do we add that? Modifiers act on individual keys, not the combined result!

That's where **Action-Level Modifiers** come into play. The array of modifiers on the `InputAction` resource itself are applied to the *final combined result*. So, you just drop a **Normalize** modifier directly onto the `InputAction`. Problem solved.

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/Adding_Normize_Modifier.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

---

### Trimming Inputs (Vector2 -> Bool)

Next, let's look at trimming a raw `Vector2` down to a simple boolean (like a button press). Let's say you want an action that *only* fires when you flick the mouse **Up**. How do we do that?

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/Triming_Mouse_motion.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

Let's look at the steps:
1. First, we add a **RemoveAxis** Modifier and tell it to remove the X-axis. This simply forces the X value to `0`, completely ignoring horizontal left/right movement. So a diagonal mouse movement of `(12, -8)` becomes `(0, -8)`.
2. Next, we add a **Clamp** Modifier. Since "Up" in Godot means a negative Y value, we clamp the Y-axis to only allow negative numbers.
3. Lastly, we add a SwitchAxis modifier to move the value to the x-axis since the InputAction only considers the x-axis for the boolean and float results.

Now, whenever the mouse moves down (positive Y), it gets clamped to `0` and ignored. The action will only trigger when the mouse is moving Up!

---

### Accumulating Inputs (Vector2 -> Float)

Let's take one more example. What if you want your action to output a simple `float`, but that float needs to represent the total *speed* or *length* of a mouse flick, regardless of the direction?

By default, if an action asks for a float, it just grabs whatever value is sitting on the X-axis. But we want the full vector's length! How do we make it send the length instead of just 1 axis?

We use the **Accumulate** Modifier. What it does is calculate the total length (magnitude) of the incoming vector, and it replaces the X-axis with that length. Now, when the action checks the X-axis for its final float value, the value waiting for it is already the vector's true length.

And because it affects the final result, you can just drop this modifier directly onto the `InputAction` itself!


---

## 5. InputActionProxies (Combos, Chords, and Holds)

If you're coming from Unreal, you're probably missing those sweet little Chord and Pulse triggers. Worry not! We have `InputActionProxies` for that! 

Proxies act as intermediate hijackers. Instead of listening to a normal `InputAction`, a Proxy connects to it, reads its values, creates its own highly modified version of the action, and sends *that* out instead. 

Let's take a Chord action (called a `ConcurrentProxy` in this system). You might wonder: *"If actions are individual values, how do I trigger an event only when two specific keys are pressed together? Do I have to write a complex script for that?"* Nope!

Let's create a Concurrent Proxy:

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/Concurrent_Proxy.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

Basically, the Proxy acts as an abstraction layer. You plug your actions into the Proxy, the Proxy does the complex math, and your player script connects to the Proxy. Here is how you code it:

```gdscript
@export var heavy_attack_proxy: InputActionProxy

func _enter_tree() -> void:
	heavy_attack_proxy.proxy_action.connect(heavy_attack)

func _exit_tree() -> void:
	heavy_attack_proxy.proxy_action.disconnect(heavy_attack)

func heavy_attack(context: InputContext) -> void:
	if context.has_state(InputContext.STARTED):
		attack.perform()
	elif context.has_state(InputContext.CANCELLED):
		attack.reset()
	elif context.has_state(InputContext.INTERRUPTED):
		attack.give_up()
```

**Wait a damn minute! What is all this!?** What's this `has_state()` function, and what are these `CANCELLED` and `INTERRUPTED` states? Weren't `STARTED`, `PROCESSING`, and `ENDED` the only states!?

Well... no, and yes.

`INTERRUPTED` is less of a state and more of a red alert warning. It fires only once if an active flow (like a held button) suffers an abrupt disruption before reaching `ENDED`. When does this happen? Maybe you pushed a UI menu profile that swallowed the inputs. Maybe the player Alt-Tabbed out of the game. It just means the input flow was forcefully halted.

But what about `CANCELLED`? 
When input flows get complex via Proxies, a simple `STARTED -> ENDED` flow isn't enough. Proxies inject new states like `DETECTED`, `PENDING`, and `CANCELLED`. 
For example, a `HoldProxy` only reaches `STARTED` *after* you hold the button for 2 seconds. But you still might want to know the exact moment the button was touched or attempted to start, so you can show a loading UI bar—that's what `DETECTED` and `PENDING` are for. If the player lets go early, it fires `CANCELLED`. 

**Why `has_state()` instead of `==`?**
Since Contexts have a strict policy of firing only once per frame, they can't batch signals. If a Proxy needs to declare two states on the exact same frame, it uses **bitmasking** to combine them into one value. Because of this, a direct `==` check might fail. `has_state()` is your safe, built-in way to check if the specific state you care about is currently active in the bitmask. 

*(Note: Raw `InputActions` don't use bitmasking, so `==` is completely safe there. Check the in-editor docs for a full chart on how every Proxy behaves!)*

---

## 6. InputProviderRegistry (Runtime Rebinding)

How do you change these hardware bindings through code while the game is running? 

You use the `InputProviderRegistry`. It's a RefCounted object you can create dynamically via `new()`. It acts as a container whose only job is to provide functions that convert Godot's native `InputEvent` objects into GAIS native `InputMetadata` resources. `InputProfile` uses these metadata resources internally, meaning you can use this registry to define new hardware inputs and swap them into your profiles dynamically for your in-game Settings menus.

---

## 7. InputIconRegistry

This is a nice-to-have utility tool! It's a custom resource used to map UI icons directly to individual `InputMetadata`. 

It provides an easy way to swap hardware inputs in your profile while automatically updating the UI icon prompt (like swapping an Xbox 'A' button icon to a Keyboard 'Spacebar' icon) in your binding menu.

It provides a simple `get_display_item(metadata)` function, which spits out your assigned texture or text for that input. How do you assign the icons? Just double-click the created resource and assign them!

<video 
  width="100%" 
  autoplay 
  loop 
  muted 
  playsinline 
  style="cursor: pointer; border-radius: 6px; border: 1px solid #373e47;" 
  onclick="this.requestFullscreen ? this.requestFullscreen() : this.webkitRequestFullscreen()">
  <source src="media/IconRegistry.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

Just drag and drop the resource into your UI script, feed it the hardware key's metadata, and it will hand back your assigned texture!

*(Note: Currently, it relies on using a sprite sheet to select your inputs, as assigning hundreds of individual textures for every possible key is a massive hassle. If there is enough demand, individual icon assignment might be added in the future!)*