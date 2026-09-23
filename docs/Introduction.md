---
layout: default
title: Getting Started
nav_order: 2
---

# Introduction

Welcome to **Godot Advanced Input System (GAIS)**!

GAIS is a self-sustained, resource-driven input architecture built for Godot 4. Instead of forcing you to build complex boilerplate around raw input strings and static maps, GAIS abstracts hardware events into clear, structured values and state lifecycles so you can focus directly on gameplay logic.

If you are coming from Unreal Engine, you will find many familiar paradigms (like Input Mapping Contexts and Triggers) re-imagined as native, inspectable Godot `Resource` files. While it may look unfamiliar at first glance, the system is designed around a straightforward pipeline:

```text
Hardware Event 
  ──> PlayerController (Device) 
  ──> InputProfile (Context Spreadsheet) 
  ──> InputModifiers (Shape/Vectorize) 
  ──> InputAction 
  ──> InputProxies (State Interceptors/Triggers) 
  ──> Listener (Your Gameplay Code)
```

---

## The 7 Core Building Blocks

Here is a quick breakdown of the foundational classes you will encounter throughout the plugin:

1. **`PlayerController`**  
   The logical representation of a single physical device (Keyboard & Mouse, Gamepad 1, Gamepad 2, Touchscreen). Managed globally by the `InputManager` autoload. You simply subscribe your game systems to the controller you want to listen to.

2. **`InputProfile`**  
   The equivalent of Unreal's *Input Mapping Context (IMC)*. Acts as a context spreadsheet that maps hardware inputs to logical actions (e.g., mapping WASD and Left Stick into a unified `Vector2`). Profiles are registered to a `PlayerController` and can be pushed or popped dynamically for different contexts (e.g., Character, Mount, Inventory).

3. **`InputAction`**  
   The logical embodiment of an action (e.g., Jump, Interact, Move). Bound within an `InputProfile`, it receives input events from the controller and dispatches rich state data to listeners.

4. **`InputModifiers`**  
   Lightweight resources applied to raw inputs to shape values along the processing conveyor belt—such as accumulating discrete keys (WASD -> `Vector2`), trimming axes (`Vector2` -> `bool`), curves, clamps, and deadzones.

5. **`InputProxies`**  
   The equivalent of Unreal's *Triggers*. Proxies act as interceptors that hijack an `InputAction` before it reaches listeners. A proxy can use the incoming states and values from the context to modify the values and even the state itself. The original Action only has 3 states (`STARTED`, `PROCESSING`, and `ENDED`), but a proxy can add more states like `DETECTED`, `PENDING`, and `CANCELLED` to provide additional features. Because of this state manipulation, proxies can handle behaviors like long presses (`ChargeProxy`), holds (`HoldProxy`), chording (`ConcurrentProxy`), combos (`SequenceProxy`), or pulsing (`PulseProxy`).

6. **`InputProviderRegistry`**  
   A global utility class that translates Godot's native `InputEvent` instances into GAIS `InputMetadata` resources—critical for runtime key rebinding.

7. **`InputIconRegistry`**  
   A custom resource used to link `InputMetadata` to prompt textures, allowing you to easily look up controller glyphs and key icons for your HUD and settings menus.

> For a deep dive into the design philosophy and inner workings of each class, check out the [Architecture Deep Dive](Technical_Details.md).

---

## Installation

You can install GAIS through standard methods:

* **Godot Asset Library:** Search for **Godot Advanced Input System** directly within the Godot editor's AssetLib tab and click Install.
* **GitHub Releases:** Download the latest release `.zip` from GitHub and unpack it.
* **Git Clone:** Clone the repository directly into your workspace.

### What to Copy
If you are downloading or cloning directly from the GitHub repository, you only need two folders:
* **`addons/GodotAdvancedInputSystem/`** — The core plugin folder. Drop this directly into your project's `res://addons/` directory.
* **`Input_System_Demo/`** *(Optional)* — The demo project folder, containing example scenes and Kenny prompt icons to help you test and explore the system.

### Enabling & Customizing Editor UI Layout

1. Open your project in the Godot Editor.
2. Navigate to **Project -> Project Settings -> Plugins**.
3. Locate **Godot Advanced Input System** and toggle the status checkbox to **Enable**.
4. The `InputManager` autoload singleton will register automatically, ready for use.

#### Choosing Your Preferred Editor Layout

This plugin includes 3 different editor plugin scripts so you can choose where the Input Profile Mapping UI lives based on your workflow:

* **Bottom Dock (Default):** Uses `Bottom_dock_plugin.gd` to place the profile mapping UI neatly in Godot's bottom panel (alongside Output, Debugger, etc.).
* **Main Screen (Top Bar):** Uses `Main_Screen_plugin.gd` to place the UI as a primary workspace view in the top viewport bar (next to 2D, 3D, Script, and AssetLib).
* **Floating Window:** Uses `Floating_Window_plugin.gd` to open the mapping UI in an independent, detachable floating window (similar to Unreal Engine's editor windows).

**How to switch layouts:**
1. Navigate to `res://addons/GodotAdvancedInputSystem/` and open `plugin.cfg` in a text editor or inside Godot.
2. Locate the line:
   ```ini
   script="Bottom_dock_plugin.gd"
   ```
3. Change the script filename to your preferred layout:
   * For the top bar workspace: `script="Main_Screen_plugin.gd"`
   * For a separate floating window: `script="Floating_Window_plugin.gd"`
1. Save the file and reload the plugin (or restart the Godot project) for the new UI layout to take effect.