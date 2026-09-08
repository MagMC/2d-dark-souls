extends CharacterBody2D


const SPEED = 170.0
const JUMP_VELOCITY = -250.0
const REST_DELAY = 15.0
var IS_ATTACKING = false

var time_without_movement: float = REST_DELAY

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("rest")


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Start attacks before processing movement so they stop walking immediately.
	if not IS_ATTACKING:
		if Input.is_action_just_pressed("Baic attack"):
			IS_ATTACKING = true
			time_without_movement = 0.0
			animated_sprite.play("basic attack")
		elif Input.is_action_just_pressed("Heavy attack"):
			IS_ATTACKING = true
			time_without_movement = 0.0
			animated_sprite.play("heavy attack")

	# Preserve airborne momentum and ignore movement input during attacks.
	if IS_ATTACKING:
		if is_on_floor():
			velocity.x = 0.0
		move_and_slide()
		if is_on_floor():
			velocity.x = 0.0
		return

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		time_without_movement = 0.0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		time_without_movement = 0.0
		animated_sprite.flip_h = direction < 0
		animated_sprite.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		time_without_movement = minf(time_without_movement + delta, REST_DELAY)
		animated_sprite.play("rest" if time_without_movement >= REST_DELAY else "idle")

	move_and_slide()


func _on_animation_finished() -> void:
	if animated_sprite.animation in ["basic attack", "heavy attack"]:
		IS_ATTACKING = false
