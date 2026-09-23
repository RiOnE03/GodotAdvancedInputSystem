@tool
extends ConfirmationDialog

@onready var ListenerButton: Button = $"MarginContainer/Body/Header/Input Listener"
@onready var search_bar: LineEdit = $"MarginContainer/Body/Header/Search bar"
@onready var tree: Tree = $"MarginContainer/Body/Panel/Margins/Heirarchy Tree"

var input_provider_registry :InputProvidersRegistry = InputProvidersRegistry.new()


signal metadata_generated(input_metadata: InputMetadata) 

func _ready():
	if Engine.is_editor_hint() and (search_bar.right_icon == null):
		search_bar.right_icon = EditorInterface.get_editor_theme().get_icon("Search", "EditorIcons")
	
	# UI Signals
	search_bar.text_changed.connect(_on_search_text_changed)
	tree.item_activated.connect(confirm_selection)
	ListenerButton.pressed.connect(start_listening)
	
	# Dialog Signals
	confirmed.connect(confirm_selection)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)
	
	populate_tree()
	popup_centered()


var listener_overlay: Control

func start_listening() -> void:
	listener_overlay = Control.new()
	
	listener_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	listener_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	listener_overlay.focus_mode = Control.FOCUS_ALL
	
	add_child(listener_overlay)
	listener_overlay.grab_focus()
	
	listener_overlay.gui_input.connect(listner_input)
	
	ListenerButton.disabled = true
	search_bar.placeholder_text = "Press any key/button..."

func listner_input(event: InputEvent) -> void:
	# Ignore mouse motion
	if event is InputEventMouseMotion:
		return
	
	if event.is_pressed():
		
		detect_input_from_providers(event)
		
		listener_overlay.accept_event() 
		
		listener_overlay.queue_free()
		
		ListenerButton.disabled = false
		search_bar.placeholder_text = "Search..."


func detect_input_from_providers(event: InputEvent) -> void:
	for provider in input_provider_registry.Providers.values():
		var input_name = provider.get_input_name(event)
		if not input_name.is_empty():
			search_bar.text = input_name 
			_on_search_text_changed(input_name)
			break

func _on_search_text_changed(query: String):
	var root = tree.get_root()
	if not root: return
	
	var lower_query = query.to_lower()
	var item_to_scroll_to: TreeItem = null 
	
	for category in root.get_children():
		var has_visible_children = false
		
		for child in category.get_children():
			var item_name = child.get_text(0).to_lower()
			
			if lower_query.is_empty() or lower_query in item_name:
				child.visible = true
				has_visible_children = true
				
				if item_name == lower_query:
					child.select(0)
					item_to_scroll_to = child 
			else:
				child.visible = false
				
		category.visible = has_visible_children
		
		if lower_query.is_empty():
			category.collapsed = true
		else:
			category.collapsed = false
			
	if item_to_scroll_to:
		item_to_scroll_to.select(0)
		tree.scroll_to_item(item_to_scroll_to)
	else:
		tree.deselect_all()


func confirm_selection():
	var selected_item: TreeItem = tree.get_selected()
	var metadata : InputMetadata = null
	if selected_item and selected_item != tree.get_root() and not selected_item.get_children(): 
		
		var input_name: String = selected_item.get_text(0)
		var category_name: String = selected_item.get_parent().get_text(0)
		
		metadata = input_provider_registry.get_metadata_from_name(input_name,category_name)
	
	metadata_generated.emit(metadata)
	queue_free()

func populate_tree():
	var root = tree.create_item() 
	
	for provider in input_provider_registry.Providers.values():
		var category_item: TreeItem = tree.create_item(root)
		category_item.set_text(0, provider.get_category_name())
		category_item.set_selectable(0, false) 
		category_item.collapsed = true
		var input_list: Array[String] = provider.get_input_list()
		
		for input_name in input_list:
			var child_item = tree.create_item(category_item)
			child_item.set_text(0, input_name)
