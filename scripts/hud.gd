class_name GameHUD
extends CanvasLayer

const ACHIEVEMENT_NAMES := {
	"first_pickup": "First Find",
	"first_tree": "Forest Friend",
	"first_quest": "Helping Hand",
}

var _quest_label: Label
var _timber_label: Label
var _wallet_label: Label
var _achievement_label: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: Timer

func _ready() -> void:
	layer = 10
	_build_hud()
	GameState.progress_changed.connect(refresh)
	GameState.notification_requested.connect(_show_notification)
	refresh()

func refresh() -> void:
	if _quest_label == null:
		return
	var timber_count: int = GameState.inventory.get("timber", 0)
	match GameState.quest_stage:
		"not_started":
			_quest_label.text = "Mission: Find Mira in the village"
		"active":
			_quest_label.text = "Mission: Bring Mira 5 timber (%d/5)" % mini(timber_count, GameState.TIMBER_QUEST_REQUIREMENT)
		"completed":
			_quest_label.text = "Mission: Timber for the Trail ✓"
	_timber_label.text = "Timber: %d" % timber_count
	_wallet_label.text = "Points: %d     Imagination Tokens: %d" % [GameState.points, GameState.imagination_tokens]
	var unlocked_names: Array[String] = []
	for achievement_id: String in GameState.achievements:
		if ACHIEVEMENT_NAMES.has(achievement_id):
			unlocked_names.append(ACHIEVEMENT_NAMES[achievement_id])
	if unlocked_names.is_empty():
		_achievement_label.text = "Achievements: 0/3"
	else:
		_achievement_label.text = "Achievements: %d/3  ·  %s" % [unlocked_names.size(), ", ".join(unlocked_names)]

func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.name = "ProgressPanel"
	panel.offset_left = 24.0
	panel.offset_top = 24.0
	panel.offset_right = 484.0
	panel.offset_bottom = 238.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.11, 0.17, 0.88)))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		margin.add_theme_constant_override("margin_%s" % ["left", "top", "right", "bottom"][side], 16)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	var title := Label.new()
	title.text = "BRICKBOUND ISLES"
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color(1.0, 0.79, 0.28, 1.0))
	content.add_child(title)
	var controls := Label.new()
	controls.name = "ControlsLabel"
	controls.text = "WASD Move  ·  Mouse Look  ·  Space Jump\nClick Break  ·  E Talk"
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color(0.78, 0.88, 0.91, 1.0))
	content.add_child(controls)
	_quest_label = _add_status_label(content, "QuestLabel")
	_timber_label = _add_status_label(content, "TimberLabel")
	_wallet_label = _add_status_label(content, "WalletLabel")
	_achievement_label = _add_status_label(content, "AchievementLabel")

	_toast_panel = PanelContainer.new()
	_toast_panel.name = "NotificationPanel"
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_top = 1.0
	_toast_panel.anchor_right = 1.0
	_toast_panel.anchor_bottom = 1.0
	_toast_panel.offset_left = 10.0
	_toast_panel.offset_top = -102.0
	_toast_panel.offset_right = -24.0
	_toast_panel.offset_bottom = -24.0
	_toast_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.15, 0.19, 0.94)))
	_toast_label = Label.new()
	_toast_label.name = "NotificationLabel"
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size = Vector2(360.0, 0.0)
	_toast_panel.add_child(_toast_label)
	_toast_panel.visible = false
	add_child(_toast_panel)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 3.5
	_toast_timer.timeout.connect(func() -> void: _toast_panel.visible = false)
	add_child(_toast_timer)

func _add_status_label(parent: VBoxContainer, label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 0.92, 1.0))
	parent.add_child(label)
	return label

func _show_notification(message: String) -> void:
	if _toast_label == null:
		return
	_toast_label.text = message
	_toast_panel.visible = true
	_toast_timer.start()

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.57, 0.76, 0.73, 0.45)
	return style
