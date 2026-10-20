class_name ScoreScreen
extends Control
## The end-of-run score screen, after the ending: a departure board of the
## run's stats. The rows flip in one at a time like split-flap letters, the
## total counts up, then the rank lands, with the best score and fastest
## finish under it. Any confirm or pause press shows everything at once;
## once it's all shown, it goes back to the main menu.
##
## Shows RunStats.last_result. Run on its own (no finished run), it shows a
## sample run, so it can be tried straight from the command line.

## Where each level's time comes from, and its short name in the splits.
const LEVELS := [
	["res://scenes/levels/level_01_arrivals.tscn", "ARRIVALS"],
	["res://scenes/levels/level_02_security.tscn", "SECURITY"],
	["res://scenes/levels/level_03_food_court.tscn", "FOOD"],
	["res://scenes/levels/level_04_gates.tscn", "GATES"],
	["res://scenes/levels/level_05_final_gate.tscn", "FINAL"],
]
## A made-up run for trying the screen on its own.
const SAMPLE := {
	"time": 1591.0,
	"level_times": {
		"res://scenes/levels/level_01_arrivals.tscn": 262.0,
		"res://scenes/levels/level_02_security.tscn": 318.0,
		"res://scenes/levels/level_03_food_court.tscn": 301.0,
		"res://scenes/levels/level_04_gates.tscn": 366.0,
		"res://scenes/levels/level_05_final_gate.tscn": 344.0,
	},
	"collected": 22, "used": 9, "met": 96, "spotted": 31, "defeated": 0,
	"hits": 4, "knockouts": 1, "secrets": 0, "secret_total": 0,
}
const PANEL := Rect2(8, 6, 304, 150)
const ROW_HEIGHT := 11.0
## Seconds between rows flipping in, and how long each flips for.
const ROW_DELAY := 0.35
const FLIP_TIME := 0.25
const COUNT_TIME := 0.8
const FLAP_CHARS := "#?*%&"

var result: Dictionary = {}
## True when showing the sample run.
var sample := false
## How many rows have settled, the total shown so far, and whether the rank
## and best score are showing yet.
var shown_rows := 0
var shown_total := 0
var rank_shown := false

var _rows: Array[Dictionary] = []
var _elapsed := 0.0
var _flipping := -1
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result = RunStats.last_result
	if result.is_empty():
		sample = true
		result = RunStats.score(SAMPLE)
		result["new_best"] = true
		result["new_fastest"] = false
		result["best"] = {"total": result["total"], "rank": result["rank"], "time": 1504.0}
	_rows = rows_for(result)
	AudioManager.play_music("victory")
	InputSetup.device_changed.connect(func(_gamepad: bool) -> void: queue_redraw())


## The board's rows for a result: {"label", "detail", "points"}.
static func rows_for(score: Dictionary) -> Array[Dictionary]:
	var stats: Dictionary = score["stats"]
	var points: Dictionary = score["points"]
	var time_detail := format_time(stats["time"])
	if score["speed_runner"]:
		time_detail += "  SPEED RUNNER!"
	var hits: int = stats["hits"]
	var perfect_detail := "NO HITS" if score["perfect"] else "%d %s" % [hits, "HIT" if hits == 1 else "HITS"]
	if stats["knockouts"] > 0:
		perfect_detail += ", %d KO" % stats["knockouts"]
	var defeated: int = stats["defeated"]
	return [
		{"label": "TIME", "detail": time_detail, "points": points["time"]},
		{"label": "EFFICIENCY", "detail": "USED %d OF %d ITEMS" % [stats["used"], stats["collected"]],
			"points": points["efficiency"]},
		{"label": "STEALTH", "detail": "SPOTTED BY %d OF %d" % [stats["spotted"], stats["met"]],
			"points": points["stealth"]},
		{"label": "DISCOVERY", "detail": "%d OF %d SECRETS" % [stats["secrets"], stats["secret_total"]],
			"points": points["discovery"]},
		{"label": "PERFECT RUN", "detail": perfect_detail, "points": points["perfect"]},
		{"label": "PACIFIST", "detail": "NONE DEFEATED" if defeated == 0
			else "%d DEFEATED" % defeated, "points": points["pacifist"]},
	]


## Seconds as m:ss, or h:mm:ss from an hour up.
static func format_time(seconds: float) -> String:
	var whole := int(seconds)
	if whole >= 3600:
		return "%d:%02d:%02d" % [whole / 3600, whole / 60 % 60, whole % 60]
	return "%d:%02d" % [whole / 60, whole % 60]


## A whole number with thousands separators, like 10,250.
static func format_points(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return ("-" if value < 0 else "") + out


func _process(delta: float) -> void:
	_elapsed += delta
	if not rank_shown:
		_advance()
	queue_redraw()


## Flips the rows in one by one, then counts the total up, then the rank.
func _advance() -> void:
	var row := int(_elapsed / ROW_DELAY)
	if row < _rows.size():
		_settle(row)
		if _elapsed - row * ROW_DELAY < FLIP_TIME:
			_flipping = row
		else:
			_flipping = -1
			_settle(row + 1)
		return
	_settle(_rows.size())
	_flipping = -1
	var counting := _elapsed - _rows.size() * ROW_DELAY
	shown_total = roundi(int(result["total"]) * clampf(counting / COUNT_TIME, 0.0, 1.0))
	if counting >= COUNT_TIME + 0.3:
		_show_all()


## Shows the first count rows, ticking if that's new.
func _settle(count: int) -> void:
	if count > shown_rows:
		shown_rows = count
		AudioManager.play("tick")


func _show_all() -> void:
	if rank_shown:
		return
	shown_rows = _rows.size()
	shown_total = result["total"]
	_flipping = -1
	rank_shown = true
	AudioManager.play("checkpoint" if result.get("new_best", false) else "stamp")


func _unhandled_input(event: InputEvent) -> void:
	var pressed := event.is_action_pressed("ui_accept") or event.is_action_pressed("pause") \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if not rank_shown:
		_show_all()
	elif not _done:
		_done = true
		GameManager.change_scene(GameManager.MAIN_MENU)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), BoardMenu.BACK)
	draw_rect(PANEL.grow(2), BoardMenu.BEZEL)
	draw_rect(PANEL.grow(1), BoardMenu.BEZEL_LIGHT)
	draw_rect(PANEL, BoardMenu.BACK)
	var left := PANEL.position.x + 6.0
	var right := PANEL.end.x - 6.0
	var width := right - left
	var y := PANEL.position.y + 12.0
	draw_string(font, Vector2(left, y), "ARRIVED: FLIGHT 13" + ("  (SAMPLE RUN)" if sample else ""),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.TITLE)
	draw_string(font, Vector2(left, y), "POINTS", HORIZONTAL_ALIGNMENT_RIGHT, width, 8, BoardMenu.FOOTER)
	y += 4.0
	draw_line(Vector2(left, y), Vector2(right, y), BoardMenu.DIVIDER)
	y += ROW_HEIGHT

	for i in _rows.size():
		var row := _rows[i]
		draw_string(font, Vector2(left, y), row["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.LABEL)
		if i < shown_rows:
			draw_string(font, Vector2(left + 64, y), row["detail"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.FOOTER)
			var value: int = row["points"]
			var text := format_points(value)
			if i >= 4:
				text = "+" + text if value > 0 else "-"
			draw_string(font, Vector2(left, y), text, HORIZONTAL_ALIGNMENT_RIGHT, width, 8,
				BoardMenu.STATUS if value > 0 else BoardMenu.DIMMED)
		elif i == _flipping:
			draw_string(font, Vector2(left, y), _flap(5), HORIZONTAL_ALIGNMENT_RIGHT, width, 8, BoardMenu.STATUS)
		y += ROW_HEIGHT
		if i == 0:
			# The level splits under the time.
			if shown_rows > 0:
				draw_string(font, Vector2(left + 8, y - 2), _splits(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.DIMMED)
			y += ROW_HEIGHT - 2.0

	y -= 6.0
	draw_line(Vector2(left, y), Vector2(right, y), BoardMenu.DIVIDER)
	y += 16.0
	draw_string(font, Vector2(left, y), "TOTAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BoardMenu.TITLE)
	if shown_rows >= _rows.size():
		draw_string(font, Vector2(left, y), format_points(shown_total), HORIZONTAL_ALIGNMENT_RIGHT, width, 16, BoardMenu.TITLE)
	y += 14.0
	if not rank_shown:
		return
	draw_string(font, Vector2(left, y), "RANK", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.LABEL)
	draw_string(font, Vector2(left + 64, y), result["rank"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.SELECTED)
	y += ROW_HEIGHT
	var best: Dictionary = result.get("best", {})
	draw_string(font, Vector2(left, y), "BEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.LABEL)
	var best_text := "%s  %s" % [format_points(int(best.get("total", 0))), best.get("rank", "")]
	if best.has("time"):
		best_text += "   FASTEST " + format_time(best["time"])
	draw_string(font, Vector2(left + 64, y), best_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, BoardMenu.FOOTER)
	# New records blink, like a status that just changed.
	var news: Array[String] = []
	if result.get("new_best", false):
		news.append("NEW BEST!")
	if result.get("new_fastest", false):
		news.append("NEW FASTEST!")
	if not news.is_empty() and int(_elapsed * 3.0) % 2 == 0:
		draw_string(font, Vector2(left, y), "  ".join(news), HORIZONTAL_ALIGNMENT_RIGHT, width, 8, BoardMenu.CANCELLED)

	ButtonGlyphs.draw_centered(self, font, size.x / 2.0, PANEL.end.y + 14.0, "{ui_accept} MAIN MENU", BoardMenu.FOOTER)


func _splits() -> String:
	var parts: PackedStringArray = []
	var times: Dictionary = result["stats"].get("level_times", {})
	for level: Array in LEVELS:
		if times.has(level[0]):
			parts.append("%s %s" % [level[1], format_time(times[level[0]])])
	return "  ".join(parts)


func _flap(length: int) -> String:
	var text := ""
	for i in length:
		text += FLAP_CHARS[randi() % FLAP_CHARS.length()]
	return text
