class_name Player
extends CharacterBody2D


## Player Controls:
## - Move Left and Right
## - Jump and Double Jump
## - Hold Jump button to jump higher
## - Press Down to fall faster
##
## Other effects:
## - Coyote timer allows jumping some time after walking off edge
## - Jump timer alows pressing jump some time before landingb
## - Acceleration and friction on ground and air
## - Emit some dust particles on the frame player hits the floor

#region movement config
const SPEED := 200.0
const JUMP_VELOCITY := -230.0
const DOUBLE_JUMP_VELOCITY := JUMP_VELOCITY
const COYOTE_DURATION := 0.25 # About 9 frames at 60fps
const COYOTE_DURATION_FROM_WALL_GRAB := 0.45
const JUMP_BUFFER_DURATION := 0.1
const GROUND_ACCELERATION := 1200.0
const GROUND_FRICTION := 1000.0
const AIR_ACCELERATION := 400.0
const AIR_FRICTION := 300.0
const GO_DOWN_SPEED := 3.0
const GRAVITY_WHEN_HOLDING_JUMP := 0.4
const GRAVITY_WHEN_FALLING := 1.5
#endregion

#region state variables
var _jump_buffer_timer := 0.0
var _coyote_timer := 0.0
var _double_jump_used := false
var _was_in_air := true
#endregion

#region variables
var gravity_modifier := 1.0
#endregion

@onready var orientation: Node2D = $Orientation
@onready var landing_particles: CPUParticles2D = $LandingParticles


func _physics_process(delta: float) -> void:
	var just_landed: bool = _was_in_air and is_on_floor()
	var on_ground = is_on_floor()
	var jumping := Input.is_action_just_pressed("jump")
	_update_timers(delta, on_ground, jumping)
	_vertical_movement(delta, on_ground, jumping, just_landed)
	_horizontal_movement(delta, on_ground)
	move_and_slide()
	_adjust_animation(just_landed)
	_was_in_air = not on_ground


## Updates cooldown timers
func _update_timers(delta: float, on_ground: bool, jumping: bool) -> void:
	if on_ground:
		_coyote_timer = COYOTE_DURATION # Reset timer while on ground
	else:
		_coyote_timer -= delta # Count down while in air
	if jumping:
		_jump_buffer_timer = JUMP_BUFFER_DURATION
	else:
		_jump_buffer_timer -= delta


## Apply 
func _get_modified_gravity() -> float:
	var gravity_vector := get_gravity()
	return gravity_vector.y * gravity_modifier


## Handles any movent on the Y axis
func _vertical_movement(delta: float, on_ground: bool, jumping: bool, just_landed: bool) -> void:
	if on_ground:
		if _jump_buffer_timer > 0. and _coyote_timer >= 0.:
			velocity.y = JUMP_VELOCITY
			_jump_buffer_timer = 0.
			_coyote_timer = 0.
	else:
		if not _double_jump_used and jumping:
			velocity.y = DOUBLE_JUMP_VELOCITY
			_double_jump_used = true
		elif Input.is_action_pressed("go_down"):
			velocity.y += _get_modified_gravity() * delta * GO_DOWN_SPEED
		elif velocity.y < 0.:
			if Input.is_action_pressed("jump"):
				velocity.y += _get_modified_gravity() * delta * GRAVITY_WHEN_HOLDING_JUMP
			else:
				velocity.y += _get_modified_gravity() * delta
		else:
			velocity.y += _get_modified_gravity() * delta * GRAVITY_WHEN_FALLING
	if just_landed:
		_double_jump_used = false


## Handles any movent on the X axis
func _horizontal_movement(delta: float, on_ground: bool) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := GROUND_ACCELERATION if on_ground else AIR_ACCELERATION
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, acceleration * delta)
	else:
		var friction := GROUND_FRICTION if on_ground else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0, friction * delta)


# We can adjust the animation here, for example trigger a landing squish
func _adjust_animation(just_landed: bool) -> void:
	
	if velocity.x != 0.0:
		orientation.scale.x = -1. if velocity.x < 0. else 1.0
	if just_landed:
		# play landing animtion and maybe some dust?
		#sprite.play("landing")
		landing_particles.emitting = true

	
