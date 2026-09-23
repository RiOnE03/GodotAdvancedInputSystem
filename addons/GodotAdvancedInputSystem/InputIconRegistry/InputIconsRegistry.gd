## A database holding a collection of all the display results corresponding to individual InputMetadata.[br]
## Create a resource and double click it to open the icon mapper. (Addon must be enabled under [kbd]Project[/kbd] > [kbd]Project Settings..[/kbd] > [kbd]Plugins[/kbd])
@tool
class_name InputIconsRegistry extends Resource

@export_storage var icon_database: Dictionary

var _popped_window: ConfimationWindow


func _show_popup()->void:
	if _popped_window:
		_popped_window.grab_focus()
		return
	if icon_database.is_empty():
		var registry := InputProvidersRegistry.new()
		
		for category in registry.Providers:
			var dict: Dictionary[String, String]
			for input in registry.Providers[category].get_input_list():
				dict[input] = ""
			icon_database[category] = dict
	_popped_window = ConfimationWindow.new(self)
	EditorInterface.get_base_control().add_child(_popped_window)
	_popped_window.popup_centered()

## Fetch the display icon (or text in case of fallback), corresponding to the InputMetadata provided.
func get_display_item(metadata: InputMetadata)->Variant:
	if not metadata:
		return null
	
	if icon_database.has(metadata.CategoryName):
		var input_dict: Dictionary = icon_database[metadata.CategoryName]
		if input_dict.has(metadata.InputName):
			var default_name: String = metadata.InputName
			var expected: Variant = input_dict[default_name]
			if expected is String:
				return default_name if expected.is_empty() else expected
			elif expected is int or expected is float:
				var sprite_frames: SpriteFrames = load(icon_database["SpriteFrames"])
				var text: Texture2D = sprite_frames.get_frame_texture(input_dict["animation"], expected)
				return text
	return null




# ==========================================
# WINDOW UI & LOGIC CLASS
# ==========================================

class ConfimationWindow extends ConfirmationDialog:

	var ui_cache: Dictionary = {}
	var icon_database: Dictionary = {}
	var global_picker: EditorResourcePicker
	
	var registry: InputIconsRegistry
	
	func _init(Inregistry: InputIconsRegistry) -> void:
		registry = Inregistry
		icon_database = registry.icon_database
		
		title = "Input Sprite Mapper"
		exclusive = false
		transient = true
		minimize_disabled = false
		maximize_disabled = false
		ok_button_text = "Save"
		
		# Root Scroll Container
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(700, 500)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		add_child(scroll)
		
		var main_vbox = VBoxContainer.new()
		main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(main_vbox)

		_build_global_header(main_vbox)
		
		# Separator
		main_vbox.add_child(HSeparator.new())
		
		_build_categories(main_vbox)
		
		confirmed.connect(_on_confirmed)
		canceled.connect(queue_free)
		close_requested.connect(queue_free)


	func _build_global_header(parent: Control) -> void:
		var header_hbox = HBoxContainer.new()
		var header_lbl = Label.new()
		header_lbl.text = "Global SpriteFrames:"
		
		global_picker = EditorResourcePicker.new()
		global_picker.base_type = "SpriteFrames"
		global_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Load existing SpriteFrames if present in JSON's 1st tier
		if icon_database.has("SpriteFrames") and icon_database["SpriteFrames"] != "":
			if ResourceLoader.exists(icon_database["SpriteFrames"]):
				global_picker.edited_resource = load(icon_database["SpriteFrames"])
				
		# Update ALL dropdowns and previews when the global resource changes
		global_picker.resource_changed.connect(func(res): 
			_refresh_all_dropdowns()
			_refresh_all_previews()
		)
		
		header_hbox.add_child(header_lbl)
		header_hbox.add_child(global_picker)
		parent.add_child(header_hbox)

	func _build_categories(parent: Control) -> void:
		for category in icon_database:
			if category == "SpriteFrames": 
				continue # Skip the global key
				
			ui_cache[category] = {"inputs": {}}
			
			# Category Header
			var cat_btn = Button.new()
			cat_btn.text = "▼ " + category
			cat_btn.add_theme_font_size_override("font_size", 16)
			parent.add_child(cat_btn)
			
			var cat_body = VBoxContainer.new()
			cat_body.add_theme_constant_override("separation", 20)
			cat_body.visible = false
			parent.add_child(cat_body)
			
			cat_btn.pressed.connect(func(): cat_body.visible = not cat_body.visible)
			
			# 1. Animation Row Setup (Now a Dropdown)
			var anim_hbox = HBoxContainer.new()
			var label := Label.new()
			label.text = "Sprite Selection Row:"
			anim_hbox.add_child(label)
			
			var anim_dropdown = OptionButton.new()
			anim_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			anim_hbox.add_child(anim_dropdown)
			cat_body.add_child(anim_hbox)
			
			ui_cache[category]["anim_dropdown"] = anim_dropdown
			
			# Update only THIS category's previews when its dropdown changes
			anim_dropdown.item_selected.connect(func(idx): _refresh_category_previews(category))
			
			# 2. Inputs Generation
			var input_margin = MarginContainer.new()
			input_margin.add_theme_constant_override("margin_left", 40)
			cat_body.add_child(input_margin)
			
			var input_vbox = VBoxContainer.new()
			input_margin.add_child(input_vbox)
			
			for input_name in icon_database[category]:
				if input_name == "animation": 
					continue # Skip the animation key
					
				ui_cache[category]["inputs"][input_name] = {}
				
				# Input Header
				var inp_btn = Button.new()
				inp_btn.flat = true
				inp_btn.text = "▶ " + input_name
				inp_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				input_vbox.add_child(inp_btn)
				
				var inp_body = VBoxContainer.new()
				inp_body.visible = false
				input_vbox.add_child(inp_body)
				inp_btn.pressed.connect(func(): 
					inp_body.visible = not inp_body.visible
					inp_btn.text = ("▼ " if inp_body.visible else "▶ ") + input_name
				)
				
				var grid = GridContainer.new()
				grid.columns = 2
				inp_body.add_child(grid)
				
				# Text Option
				label = Label.new()
				label.text = "Fallback Display Text:"
				grid.add_child(label)
				var line_edit = LineEdit.new()
				line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(line_edit)
				
				# Frame Option
				label = Label.new()
				label.text = "Frame Index:"
				grid.add_child(label)
				var spin_frame = SpinBox.new()
				spin_frame.min_value = -1
				spin_frame.value = -1
				grid.add_child(spin_frame)
				
				# Preview Image
				label = Label.new()
				label.text = "Preview:"
				grid.add_child(label)
				var preview = TextureRect.new()
				preview.custom_minimum_size = Vector2(80, 80)
				preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				grid.add_child(preview)
				
				# Populate Existing JSON Data
				var existing_val = icon_database[category][input_name]
				
				if typeof(existing_val) == TYPE_FLOAT or typeof(existing_val) == TYPE_INT:
					spin_frame.value = int(existing_val)
				else:
					line_edit.text = str(existing_val)
					
				# Save to cache
				var field_cache = ui_cache[category]["inputs"][input_name]
				field_cache["text"] = line_edit
				field_cache["frame"] = spin_frame
				field_cache["preview"] = preview
				
				# Live Update connections
				spin_frame.value_changed.connect(func(val): _update_preview(category, input_name))
		
		# Initial population of dropdowns and previews once the UI is fully built
		_refresh_all_dropdowns()
		_refresh_all_previews()

	# --- DROPDOWN LOGIC ---
	func _refresh_all_dropdowns() -> void:
		for category in ui_cache:
			_refresh_animation_dropdown(category)

	func _refresh_animation_dropdown(cat_name: String) -> void:
		var dropdown: OptionButton = ui_cache[cat_name]["anim_dropdown"]
		dropdown.clear()
		
		if global_picker.edited_resource is SpriteFrames:
			var sf: SpriteFrames = global_picker.edited_resource
			var anims = sf.get_animation_names()
			
			if anims.size() > 0:
				for anim in anims:
					dropdown.add_item(anim)
					
				# Try to select the previously saved animation
				var saved_anim = icon_database[cat_name].get("animation", "")
				var found = false
				
				for i in range(dropdown.item_count):
					if dropdown.get_item_text(i) == saved_anim:
						dropdown.select(i)
						found = true
						break
				
				# If the saved animation wasn't found (or was empty), automatically select the first item
				if not found:
					dropdown.select(0)
			else:
				dropdown.add_item("default") # Safe fallback if SpriteFrames is completely empty
		else:
			dropdown.add_item("default") # Safe fallback if no resource is loaded

	# --- PREVIEW LOGIC ---
	func _refresh_all_previews() -> void:
		for category in ui_cache:
			_refresh_category_previews(category)

	func _refresh_category_previews(cat_name: String) -> void:
		for input_name in ui_cache[cat_name]["inputs"]:
			_update_preview(cat_name, input_name)

	func _update_preview(cat_name: String, inp_name: String) -> void:
		var fields = ui_cache[cat_name]["inputs"][inp_name]
		var frame_idx = int(fields["frame"].value)
		var dropdown: OptionButton = ui_cache[cat_name]["anim_dropdown"]
		
		# Get current dropdown text safely
		var anim_name = ""
		if dropdown.item_count > 0:
			anim_name = dropdown.get_item_text(dropdown.selected)
		
		if frame_idx >= 0 and global_picker.edited_resource is SpriteFrames:
			var sf: SpriteFrames = global_picker.edited_resource
			
			if sf.has_animation(anim_name) and frame_idx < sf.get_frame_count(anim_name):
				fields["preview"].texture = sf.get_frame_texture(anim_name, frame_idx)
			else:
				fields["preview"].texture = null # Animation missing or frame out of bounds
		else:
			fields["preview"].texture = null

	# --- SAVE DATA ---
	func _on_confirmed() -> void:
		var final_database: Dictionary = {}
		
		# 1st Tier: Global SpriteFrames Path
		if global_picker.edited_resource:
			final_database["SpriteFrames"] = global_picker.edited_resource.resource_path
		else:
			final_database["SpriteFrames"] = ""
			
		# Iterate Categories
		for category in ui_cache:
			final_database[category] = {}
			
			# Save Animation Row string from Dropdown safely
			var dropdown: OptionButton = ui_cache[category]["anim_dropdown"]
			var anim_name = ""
			if dropdown.item_count > 0:
				anim_name = dropdown.get_item_text(dropdown.selected)
				
			final_database[category]["animation"] = anim_name
			
			# Save Inputs
			for input_name in ui_cache[category]["inputs"]:
				var fields = ui_cache[category]["inputs"][input_name]
				var frame_idx = int(fields["frame"].value)
				
				# PRIORITY: If frame >= 0, save as INT. Otherwise, save text as STRING.
				if frame_idx >= 0:
					final_database[category][input_name] = frame_idx
				else:
					final_database[category][input_name] = fields["text"].text
		
		registry.icon_database = final_database
		queue_free()
