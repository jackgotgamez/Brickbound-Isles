extends Node

signal progress_changed
signal notification_requested(message: String)

const SAVE_PATH := "user://brickbound_save.json"
const TIMBER_QUEST_REWARD_POINTS := 100
const TIMBER_QUEST_REWARD_TOKENS := 10
const TIMBER_QUEST_REQUIREMENT := 5
const QUEST_STAGES := ["not_started", "active", "completed"]

var inventory: Dictionary[String, int] = {}
var quest_stage: String = "not_started"
var player_position: Vector3 = Vector3.ZERO
var points: int = 0
var imagination_tokens: int = 0
var achievements: Array[String] = []

func collect_item(item_id: String, amount: int = 1) -> void:
	if item_id.strip_edges().is_empty() or amount <= 0:
		return
	inventory[item_id] = inventory.get(item_id, 0) + amount
	progress_changed.emit()

func start_timber_quest() -> bool:
	if quest_stage != "not_started":
		return false
	quest_stage = "active"
	notification_requested.emit("Mission started: Timber for the Trail. Collect 5 timber.")
	progress_changed.emit()
	return true

func try_complete_timber_quest() -> bool:
	if quest_stage != "active" or inventory.get("timber", 0) < TIMBER_QUEST_REQUIREMENT:
		return false
	var remaining_timber := inventory["timber"] - TIMBER_QUEST_REQUIREMENT
	if remaining_timber == 0:
		inventory.erase("timber")
	else:
		inventory["timber"] = remaining_timber
	quest_stage = "completed"
	points += TIMBER_QUEST_REWARD_POINTS
	imagination_tokens += TIMBER_QUEST_REWARD_TOKENS
	notification_requested.emit("Mission complete! +100 points and +10 Imagination Tokens.")
	progress_changed.emit()
	return true

func unlock_achievement(achievement_id: String) -> void:
	if achievement_id.strip_edges().is_empty() or achievements.has(achievement_id):
		return
	achievements.append(achievement_id)
	notification_requested.emit("Achievement unlocked: %s" % achievement_id.replace("_", " ").capitalize())
	progress_changed.emit()

func update_player_position(position: Vector3) -> void:
	player_position = position

func save_progress(path: String = SAVE_PATH) -> bool:
	if path.strip_edges().is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var data := {
		"inventory": inventory,
		"quest_stage": quest_stage,
		"player_position": [player_position.x, player_position.y, player_position.z],
		"points": points,
		"imagination_tokens": imagination_tokens,
		"achievements": achievements,
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_succeeded := file.get_error() == OK
	file.close()
	return write_succeeded

func load_progress(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		_reset_progress()
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_reset_progress()
		return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		file.close()
		_reset_progress()
		return false
	file.close()

	var data: Dictionary = parser.data
	var parsed_inventory: Variant = _parse_inventory(data.get("inventory"))
	var parsed_position: Variant = _parse_position(data.get("player_position"))
	var parsed_achievements: Variant = _parse_achievements(data.get("achievements"))
	var stage: Variant = data.get("quest_stage")
	var loaded_points: Variant = data.get("points")
	var loaded_tokens: Variant = data.get("imagination_tokens")
	if parsed_inventory == null or parsed_position == null or parsed_achievements == null:
		_reset_progress()
		return false
	if typeof(stage) != TYPE_STRING or not QUEST_STAGES.has(stage):
		_reset_progress()
		return false
	if not _is_non_negative_integer(loaded_points) or not _is_non_negative_integer(loaded_tokens):
		_reset_progress()
		return false

	inventory = parsed_inventory
	quest_stage = stage
	player_position = parsed_position
	points = int(loaded_points)
	imagination_tokens = int(loaded_tokens)
	achievements = parsed_achievements
	progress_changed.emit()
	return true

func _parse_inventory(value: Variant) -> Variant:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var parsed: Dictionary[String, int] = {}
	for key: Variant in value:
		var item_id: Variant = key
		var amount: Variant = value[key]
		if typeof(item_id) != TYPE_STRING or item_id.strip_edges().is_empty() or not _is_non_negative_integer(amount):
			return null
		if amount > 0:
			parsed[item_id] = int(amount)
	return parsed

func _parse_position(value: Variant) -> Variant:
	if typeof(value) != TYPE_ARRAY or value.size() != 3:
		return null
	for component: Variant in value:
		if typeof(component) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)):
			return null
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

func _parse_achievements(value: Variant) -> Variant:
	if typeof(value) != TYPE_ARRAY:
		return null
	var parsed: Array[String] = []
	for achievement: Variant in value:
		if typeof(achievement) != TYPE_STRING or achievement.strip_edges().is_empty():
			return null
		if not parsed.has(achievement):
			parsed.append(achievement)
	return parsed

func _is_non_negative_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return value >= 0
	if typeof(value) == TYPE_FLOAT:
		return is_finite(value) and value >= 0.0 and floor(value) == value
	return false

func _reset_progress() -> void:
	inventory.clear()
	quest_stage = "not_started"
	player_position = Vector3.ZERO
	points = 0
	imagination_tokens = 0
	achievements.clear()
	progress_changed.emit()
