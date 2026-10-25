extends CanvasLayer
class_name HUD

@onready var suspicion_bar = $SuspicionContainer/SuspicionBar
@onready var suspicion_label = $SuspicionContainer/SuspicionLabel
@onready var interaction_prompt = $InteractionPrompt
@onready var minimap = $MinimapContainer/Minimap
@onready var interact_button = $MobileControls/InteractButton

func _ready() -> void:
	interaction_prompt.visible = false
	if interact_button:
		interact_button.visible = false
		interact_button.pressed.connect(_on_interact_pressed)

func update_suspicion(value: float) -> void:
	if suspicion_bar:
		suspicion_bar.value = value
	if suspicion_label:
		suspicion_label.text = "Suspicion: %d%%" % int(value)

func show_interaction_prompt(text: String) -> void:
	if interaction_prompt:
		interaction_prompt.text = text
		interaction_prompt.visible = true

func hide_interaction_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false

func set_interact_button_visible(visible: bool) -> void:
	if interact_button:
		interact_button.visible = visible

func _on_interact_pressed() -> void:
	# Signal the player to interact
	if get_parent().has_node("Player"):
		var player = get_parent().get_node("Player")
		if player and player.has_method("_try_interact_from_hud"):
			player._try_interact_from_hud()