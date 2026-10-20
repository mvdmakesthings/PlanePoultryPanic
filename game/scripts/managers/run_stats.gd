extends Node
## Keeps the stats of the run for the score screen, and the best score
## (autoload: RunStats).
##
## Two kinds of stats:
##   run-wide   - time (in all and per level), hits taken and knockouts.
##                These never go back: a knockout still costs the time
##                and the hit.
##   checkpoint - items collected and used, chickens met and spotted, and
##                chickens defeated. The level resets on a retry, so these
##                go back to what they were at the checkpoint, and nothing
##                is counted twice.
## Both go into every checkpoint snapshot (under "stats"), and the run-wide
## ones are written to the save again when they change, so quitting and
## choosing Continue can't undo a hit.
##
## Items are snacks and extinguishers; key items don't count. A snack is
## used when it's thrown or eaten, an extinguisher once it's empty.
## Dropping an item takes it off the collected count, so picking it up
## again doesn't count twice. A chicken has spotted Amanda once it chases
## her, including when another chicken alerted it.

const TIME_MAX := 3000
## Full time points at this many seconds or under, none at TIME_ZERO.
const TIME_FULL := 15.0 * 60.0
const TIME_ZERO := 45.0 * 60.0
const EFFICIENCY_MAX := 2000
const STEALTH_MAX := 2000
const DISCOVERY_MAX := 2000
## Perfect Run (no hits, no knockouts) and Pacifist (no chickens defeated).
const BONUS := 1000
## The Speed Runner badge, for finishing under this many seconds.
const SPEED_RUNNER_TIME := 25.0 * 60.0
## Ranks by total score, lowest first.
const RANKS := [
	[0, "LOST LUGGAGE"],
	[2500, "STANDBY"],
	[4500, "ECONOMY"],
	[6500, "BUSINESS CLASS"],
	[8500, "FIRST CLASS"],
	[10000, "CAPTAIN"],
]
## Run-wide stats are written to the save this often while playing.
const PERSIST_INTERVAL := 15.0
## Chicken states (by name) that mean it has spotted Amanda. Chickens are
## only ever handled by group and name here (and levels and the player as
## plain nodes): naming those classes in an autoload loads them too early,
## which breaks the scenes they preload.
const SPOTTED_STATES := ["PURSUE", "WINDUP", "BESIEGE"]

# ---------- run-wide ----------
## Seconds played: only while a level is running, not paused, and not on
## its clear or retry screen.
var time := 0.0
## Seconds played in each level, by scene path.
var level_times := {}
var hits := 0
var knockouts := 0

# ---------- rolled back to the checkpoint on a retry ----------
## Items picked up (plus the snacks the run starts with), and used.
var collected := 0
var used := 0
var defeated := 0
## Chickens met in the current level: path -> whether it spotted Amanda.
var chickens := {}
## Chickens met and spotted in levels before the current one.
var past_met := 0
var past_spotted := 0
## The level chickens is counting.
var chickens_level := ""

## The finished run's score (see score()), for the score screen, or {}.
var last_result: Dictionary = {}

var _level: Node
var _player: Node
var _last_health := 0
## Chickens being watched for spotting Amanda: instance id -> path.
var _watched := {}
var _persist_left := PERSIST_INTERVAL


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


## Starts a new run's stats.
func reset() -> void:
	time = 0.0
	level_times = {}
	hits = 0
	knockouts = 0
	collected = 0
	used = 0
	defeated = 0
	chickens = {}
	past_met = 0
	past_spotted = 0
	chickens_level = ""
	last_result = {}


func _physics_process(delta: float) -> void:
	if not _level_running():
		return
	time += delta
	var path := _level.scene_file_path
	level_times[path] = float(level_times.get(path, 0.0)) + delta
	for id: int in _watched.keys():
		var chicken := instance_from_id(id) as Node
		if chicken == null or not is_instance_valid(chicken) or not chicken.is_inside_tree():
			_watched.erase(id)
		elif _spotting(chicken):
			chickens[_watched[id]] = true
	_persist_left -= delta
	if _persist_left <= 0.0:
		persist()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist()


func _level_running() -> bool:
	return is_instance_valid(_level) and _level.is_inside_tree() and _level.is_playing()


# ---------- what the game reports ----------

## Called by a level once it's built. restore is the checkpoint it's about
## to restore ({} when it starts from the beginning).
func level_started(level: Node, player: Node, restore: Dictionary) -> void:
	_level = level
	_player = player
	_watched.clear()
	if restore.has("stats"):
		_restore_checkpoint(restore["stats"].get("checkpoint", {}))
	elif restore.is_empty() and time == 0.0 and collected == 0 and used == 0:
		# A brand new run: the snacks Amanda starts with count as hers.
		collected += _item_count(player.inventory.slots)
	if chickens_level != level.scene_file_path:
		past_met += chickens.size()
		past_spotted += _spotted_here()
		chickens = {}
		chickens_level = level.scene_file_path
	for node in get_tree().get_nodes_in_group("chickens"):
		if level.is_ancestor_of(node):
			_watch(node)
	_last_health = player.health
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)


## Called by the player on picking up count of an item (not key items).
func item_collected(count := 1) -> void:
	collected += count


## Called by the player on throwing or eating a snack, or emptying an
## extinguisher.
func item_used() -> void:
	used += 1


## Called by the player on dropping a slot (its item and count).
func item_dropped(slot: Dictionary) -> void:
	collected = maxi(collected - _item_count([slot]), 0)


func _on_node_added(node: Node) -> void:
	if node.is_in_group("chickens") and is_instance_valid(_level) and _level.is_ancestor_of(node):
		_watch(node)


func _watch(chicken: Node) -> void:
	var path := str(chicken.get_path())
	if not chickens.has(path):
		chickens[path] = false
	if not _watched.has(chicken.get_instance_id()):
		_watched[chicken.get_instance_id()] = path
		chicken.defeated.connect(func() -> void: defeated += 1)


func _spotting(chicken: Node) -> bool:
	var states: Dictionary = chicken.State
	for state: String in SPOTTED_STATES:
		if chicken.state == states[state]:
			return true
	return false


func _on_health_changed(current: int, _maximum: int) -> void:
	if current < _last_health:
		hits += 1
		persist()
	_last_health = current


func _on_player_died() -> void:
	knockouts += 1
	persist()


## Snacks count one each, an extinguisher one whatever its charges.
static func _item_count(slots: Array) -> int:
	var count := 0
	for slot: Dictionary in slots:
		if slot.get("item", "") == "snack":
			count += int(slot["count"])
		elif slot.get("item", "") == "extinguisher":
			count += 1
	return count


func _spotted_here() -> int:
	return chickens.values().count(true)


# ---------- saving ----------

## Every stat as plain JSON values, for a checkpoint snapshot.
func capture() -> Dictionary:
	return {"run": _run_state(), "checkpoint": _checkpoint_state()}


## Puts every stat back from a save (Continue).
func restore(state: Dictionary) -> void:
	reset()
	var run: Dictionary = state.get("run", {})
	time = float(run.get("time", 0.0))
	level_times = (run.get("level_times", {}) as Dictionary).duplicate()
	hits = int(run.get("hits", 0))
	knockouts = int(run.get("knockouts", 0))
	_restore_checkpoint(state.get("checkpoint", {}))


## Writes the run-wide stats into the latest checkpoint's save, so they
## survive quitting.
func persist() -> void:
	_persist_left = PERSIST_INTERVAL
	var checkpoint: Dictionary = GameManager.last_checkpoint
	if not checkpoint.has("stats"):
		return
	checkpoint["stats"]["run"] = _run_state()
	SaveSystem.save_game(checkpoint)


func _run_state() -> Dictionary:
	return {
		"time": time,
		"level_times": level_times.duplicate(),
		"hits": hits,
		"knockouts": knockouts,
	}


func _checkpoint_state() -> Dictionary:
	return {
		"collected": collected,
		"used": used,
		"defeated": defeated,
		"chickens": chickens.duplicate(),
		"past_met": past_met,
		"past_spotted": past_spotted,
		"chickens_level": chickens_level,
	}


func _restore_checkpoint(state: Dictionary) -> void:
	# JSON turns every number into a float; counts are whole numbers.
	collected = int(state.get("collected", 0))
	used = int(state.get("used", 0))
	defeated = int(state.get("defeated", 0))
	chickens = (state.get("chickens", {}) as Dictionary).duplicate()
	past_met = int(state.get("past_met", 0))
	past_spotted = int(state.get("past_spotted", 0))
	chickens_level = str(state.get("chickens_level", ""))


# ---------- the score ----------

## The current run's stats in the form score() takes.
func summary() -> Dictionary:
	return {
		"time": time,
		"level_times": level_times.duplicate(),
		"collected": collected,
		"used": used,
		"met": past_met + chickens.size(),
		"spotted": past_spotted + _spotted_here(),
		"defeated": defeated,
		"hits": hits,
		"knockouts": knockouts,
		"secrets": secrets_found(),
		"secret_total": secrets_total(),
	}


## Secrets are kept by GameManager (secrets_found, saved with the run, and
## SECRETS_TOTAL), which the secrets work adds. Until it's there, these
## read 0 of 0.
static func secrets_found() -> int:
	var found: Variant = GameManager.get("secrets_found")
	return (found as Array).size() if found is Array else 0


static func secrets_total() -> int:
	return int(GameManager.get_script().get_script_constant_map().get("SECRETS_TOTAL", 0))


## Scores a run's summary: points per category, bonuses, total and rank.
static func score(stats: Dictionary) -> Dictionary:
	var seconds: float = stats["time"]
	var time_share := clampf((TIME_ZERO - seconds) / (TIME_ZERO - TIME_FULL), 0.0, 1.0)
	var collected_count: int = stats["collected"]
	var spare := 1.0 if collected_count <= 0 \
		else clampf(1.0 - float(stats["used"]) / collected_count, 0.0, 1.0)
	var met: int = stats["met"]
	var unseen := 1.0 if met <= 0 else clampf(1.0 - float(stats["spotted"]) / met, 0.0, 1.0)
	var secret_total: int = stats["secret_total"]
	var found := 0.0 if secret_total <= 0 else clampf(float(stats["secrets"]) / secret_total, 0.0, 1.0)
	var perfect: bool = stats["hits"] == 0 and stats["knockouts"] == 0
	var pacifist: bool = stats["defeated"] == 0
	var points := {
		"time": roundi(TIME_MAX * time_share),
		"efficiency": roundi(EFFICIENCY_MAX * spare),
		"stealth": roundi(STEALTH_MAX * unseen),
		"discovery": roundi(DISCOVERY_MAX * found),
		"perfect": BONUS if perfect else 0,
		"pacifist": BONUS if pacifist else 0,
	}
	var total := 0
	for value: int in points.values():
		total += value
	return {
		"stats": stats,
		"points": points,
		"total": total,
		"rank": rank_for(total),
		"perfect": perfect,
		"pacifist": pacifist,
		"speed_runner": seconds < SPEED_RUNNER_TIME,
	}


static func rank_for(total: int) -> String:
	var rank: String = RANKS[0][1]
	for entry: Array in RANKS:
		if total >= entry[0]:
			rank = entry[1]
	return rank


## Ends the run: scores it, keeps it in last_result for the score screen,
## and saves it if it's a new best score or fastest time.
func finish_run() -> Dictionary:
	last_result = score(summary())
	var best := SaveSystem.load_best()
	last_result["new_best"] = best.is_empty() or last_result["total"] > int(best.get("total", 0))
	last_result["new_fastest"] = best.is_empty() or time < float(best.get("time", INF))
	if last_result["new_best"]:
		best["total"] = last_result["total"]
		best["rank"] = last_result["rank"]
	if last_result["new_fastest"]:
		best["time"] = time
	SaveSystem.save_best(best)
	last_result["best"] = best
	return last_result
