extends CharacterBody2D


@export_group("Movement")
@export var move_speed: float = 200.0
@export var ground_acceleration: float = 2400.0
@export var ground_deceleration: float = 3200.0
@export var air_acceleration: float = 1400.0
@export var jump_velocity: float = -280.0
@export var fall_gravity_multiplier: float = 1.35
@export_range(0.0, 0.3) var coyote_time: float = 0.1
@export_range(0.0, 0.3) var jump_buffer_time: float = 0.12

@export_group("Combat")
@export_range(0.1, 2.0) var basic_attack_duration: float = 0.32
@export_range(0.1, 2.0) var heavy_attack_duration: float = 0.65

const REST_DELAY = 15.0
var IS_ATTACKING = false

var time_without_movement: float = REST_DELAY
var coyote_time_left: float = 0.0
var jump_buffer_left: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("rest")


func _physics_process(delta: float) -> void:
	coyote_time_left = coyote_time if is_on_floor() else maxf(coyote_time_left - delta, 0.0)
	jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)
	if Input.is_action_just_pressed("ui_accept") and not IS_ATTACKING:
		jump_buffer_left = jump_buffer_time

	# A slightly faster descent makes the jump feel less floaty.
	if not is_on_floor():
		var gravity_multiplier := fall_gravity_multiplier if velocity.y > 0.0 else 1.0
		velocity += get_gravity() * gravity_multiplier * delta

	var direction := Input.get_axis("ui_left", "ui_right")

	# Start attacks before processing movement so they stop walking immediately.
	if not IS_ATTACKING:
		if Input.is_action_just_pressed("Baic attack"):
			_start_attack("basic attack", basic_attack_duration, direction)
		elif Input.is_action_just_pressed("Heavy attack"):
			_start_attack("heavy attack", heavy_attack_duration, direction)

	# Preserve airborne momentum and ignore movement input during attacks.
	if IS_ATTACKING:
		if is_on_floor():
			velocity.x = 0.0
		move_and_slide()
		if is_on_floor():
			velocity.x = 0.0
		return

	# Accept jumps just before landing or just after leaving an edge.
	if (jump_buffer_left > 0.0 or Input.is_action_just_pressed("ui_accept")) and (is_on_floor() or coyote_time_left > 0.0):
		velocity.y = jump_velocity
		jump_buffer_left = 0.0
		coyote_time_left = 0.0
		time_without_movement = 0.0

	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	if direction:
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
		time_without_movement = 0.0
		animated_sprite.flip_h = direction < 0
	else:
		var deceleration := ground_deceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		time_without_movement = minf(time_without_movement + delta, REST_DELAY)

	move_and_slide()
	if not is_on_floor():
		animated_sprite.play("jump")
	elif absf(velocity.x) > 1.0:
		animated_sprite.play("walk", 1.5)
	else:
		animated_sprite.play("rest" if time_without_movement >= REST_DELAY else "idle")


func _start_attack(animation_name: StringName, duration: float, direction: float) -> void:
	IS_ATTACKING = true
	time_without_movement = 0.0
	jump_buffer_left = 0.0
	coyote_time_left = 0.0
	if is_on_floor() and direction != 0.0:
		animated_sprite.flip_h = direction < 0.0

	# Preserve the frame timing proportions while tuning the total attack length.
	var frames := animated_sprite.sprite_frames
	var animation_duration := 0.0
	for frame_index in range(frames.get_frame_count(animation_name)):
		animation_duration += frames.get_frame_duration(animation_name, frame_index)
	animation_duration /= frames.get_animation_speed(animation_name)
	animated_sprite.stop()
	animated_sprite.play(animation_name, animation_duration / maxf(duration, 0.01))


func _on_animation_finished() -> void:
	if animated_sprite.animation in ["basic attack", "heavy attack"]:
		IS_ATTACKING = false
