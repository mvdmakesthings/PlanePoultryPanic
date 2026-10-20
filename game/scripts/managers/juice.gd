extends Node
## Game-feel feedback (autoload: Juice): screen shake, hit-stop, hit
## flashes, and squash and stretch. Gameplay scripts call these at the
## moment something happens, so every hit, stomp and slam reads clearly.
##
##   Juice.shake(3.0)                     shake the camera up to 3 px
##   Juice.hitstop(0.06)                  freeze the action for a moment
##   Juice.flash(sprite, Juice.DANGER)    flash a sprite a solid color
##   Juice.squash(sprite, Vector2(1.3, 0.7))  squash, then spring back
##
## Screen shake can be turned off in Settings (SaveSystem.screen_shake).

## Flash colors, from the palette. Danger red is reserved for damage.
const DANGER := Color("ff0044")
const WHITE := Color("ffffff")
const ICE := Color("c0cbdc")
## How long a shake lasts at full strength before it dies away.
const SHAKE_TIME := 0.25
## The shake jumps to a new offset this many times a second; every frame
## would be a blur at 320x180.
const SHAKE_RATE := 30.0
## Time runs this slowly during a hit-stop. Not zero, so nothing that
## waits on time gets stuck.
const HITSTOP_SCALE := 0.05
const FLASH_SHADER := preload("res://scripts/managers/flash.gdshader")

## Strongest shake in pixels; 0 when still.
var _shake := 0.0
var _shake_left := 0.0
var _shake_tick := 0.0
var _camera: Camera2D = null
## The offset this shake added to the camera, taken back off each frame.
var _applied := Vector2.ZERO
## Unslowed seconds left in the current hit-stop, and the time scale to
## go back to (tests speed time up).
var _hitstop_left := 0.0
var _time_scale_before := 1.0


func _ready() -> void:
	# Hit-stops have to end, and shakes settle, even if the game pauses.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_update_shake(delta)
	if _hitstop_left > 0.0:
		# delta is slowed down too; count the time as it really passes.
		_hitstop_left -= delta / Engine.time_scale
		if _hitstop_left <= 0.0:
			Engine.time_scale = _time_scale_before


## Shakes the camera by up to strength pixels, dying away over a quarter
## second. A smaller shake during a bigger one doesn't cut it short.
func shake(strength: float) -> void:
	if not SaveSystem.screen_shake:
		return
	if strength >= _shake * (_shake_left / SHAKE_TIME):
		_shake = strength
		_shake_left = SHAKE_TIME
		_shake_tick = 0.0


## Nearly freezes the action for a few frames, so a big hit lands.
func hitstop(seconds: float) -> void:
	if _hitstop_left <= 0.0:
		_time_scale_before = Engine.time_scale
		Engine.time_scale = HITSTOP_SCALE
	_hitstop_left = maxf(_hitstop_left, seconds)


## Flashes a sprite a solid color that fades back over seconds. Its
## outline and see-through pixels keep their shape.
func flash(sprite: CanvasItem, color: Color, seconds := 0.15) -> void:
	if not is_instance_valid(sprite):
		return
	var material := sprite.material as ShaderMaterial
	if material == null or material.shader != FLASH_SHADER:
		material = ShaderMaterial.new()
		material.shader = FLASH_SHADER
		sprite.material = material
	material.set_shader_parameter("flash_color", color)
	material.set_shader_parameter("flash", 1.0)
	var tween := sprite.create_tween()
	tween.tween_method(func(amount: float) -> void:
		material.set_shader_parameter("flash", amount), 1.0, 0.0, seconds)


## Squashes (or stretches) target to amount, then springs it back to
## normal. property is the Vector2 to squash: a sprite's "scale" by
## default, or a stand-in like a totem's stack_squash.
func squash(target: Object, amount: Vector2, seconds := 0.2, property := "scale") -> void:
	if not is_instance_valid(target):
		return
	var tween := (target as Node).create_tween()
	target.set(property, amount)
	target.set_meta(&"squashing", true)
	tween.tween_property(target, property, Vector2.ONE, seconds) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		if is_instance_valid(target):
			target.remove_meta(&"squashing"))


## True while target is mid-squash, so code that resets its scale every
## frame can leave it alone.
func is_squashing(target: Object) -> bool:
	return target.has_meta(&"squashing")


## The camera's current shake offset, for tests.
func shake_offset() -> Vector2:
	return _applied


func _update_shake(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != _camera:
		if is_instance_valid(_camera):
			_camera.offset -= _applied
		_applied = Vector2.ZERO
		_camera = camera
	if _camera == null or get_tree().paused:
		return
	var target := Vector2.ZERO
	if _shake_left > 0.0 and SaveSystem.screen_shake:
		_shake_left -= delta
		_shake_tick -= delta
		if _shake_tick > 0.0:
			return
		_shake_tick = 1.0 / SHAKE_RATE
		# Eases out: strong at first, then settling.
		var strength := _shake * pow(maxf(_shake_left, 0.0) / SHAKE_TIME, 2.0)
		# Whole pixels only, so the art never lands between pixels.
		target = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
		target = target.round()
	_camera.offset += target - _applied
	_applied = target
