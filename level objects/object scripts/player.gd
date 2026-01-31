extends CharacterBody3D

'''
Message from SELF:
----------------------------------------------------------------------------
| Just make it work, they said. Mabie you should do that instead of making |
| asci art of messages to yourself "from the future" and lock in. I mean,  |
| you havent even touched Lutra in a month, what are you doing? LOCK IN    |
|                                                           - Regards, You |
----------------------------------------------------------------------------
Message recived: 11/17/2025, 3:22 AM


Message from SELF:
----------------------------------------------------
| ORGANIZE YOUR CODE YOU FUCKING MESSY PRICK!!!!!! |
| (and your asci art isnt helping)                 |
|                                   - Regards, You |
----------------------------------------------------
Message recived:  1/20/2026, 7:38 PM
'''

#region -- Consts
const lifeIcon = preload("res://lifeIcon.tscn")

const velocityMult = 2

const baseMouseSens = 0.005

const gravityStrenth = 5
const jumpForce = 18
const wallJumpForce = 10
const wallpushForce = 10

const wallFriction = 0.6
const wallMin = -3
const wallFrac = 0.7

const sprintSpeed = 12
const walkSpeed = 7
const crouchSpeed = 5
const airSpeed = 4
const crouchAirSpeed = 7

const groundAcceleration = 1.5
const airAcceleration = 0.2
const crouchAcceleration = 1.5
const slideAcceleration = 0.1

const slideBuffer = 9
const slideTime = 0.5
const dashTime = 0.15
const dashForce = 1.5
const dashMinForce = 30
const slideForce = 1.5

const runningCost = 10
const slidingCost = 20

const redirectBuffer = 20
const inputBuffer = 0.3
const cyoteTime = 0.1

const camOffsetAmount = 10

const walkFootInterval = 0.5
const runFootInterval = 0.3
#endregion

## for the love of god, organize this shit eventually
#region -- Variables
var trueDirection = Vector3()
var speed = 0.0
var trueSpeed = 0.0
var acceleration = 1.0
var forwardDirection = Vector3()
var spawn = Vector3()
var crouched = false
var camOffset = Vector3()
var camRotation = Vector3()
var sliding = false
var canSlide1 = false
var canSlide2 = false
var realSpeed = 0.0
var realDirection = Vector3()
var dashVelocity = Vector3()
var dashing = false
var befVelocity1 = 0
var befVelocity2 = Vector3()
var footInterval = 0.5
var allowInput = true

## Settings
var mouseSens = 0.0

## Upgradables / Default Values
var activeDashes = []
var activeJumps = []
var activeGoals = []
var stamina = Globals.maxStamina
var staminaRegen = 5
var idleRegen = 8
#endregion

@onready var material = $DeathShader.material as ShaderMaterial

func _ready():
	Globals.player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawn = position
	$RigidBody3D.gravity_scale = gravityStrenth
	$"Ui/Verson Lable".text = Globals.version
	$DeathShader.hide()
	reload()
	$Ui/Upgrade.hide()


# can prob move to _physics_process
func _unhandled_input(event):
	if $"Death Anim".time_left == 0:
		mouseSens = baseMouseSens * Globals.Snesitivity
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				rotation.y -= event.relative.x * mouseSens
				camRotation.x -= event.relative.y * mouseSens
				camRotation.x = clamp(camRotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta):
	$Camera.rotation = camRotation + camOffset

	$Camera.fov = Globals.FOV

	#if position.y < -30:
		#damage()

	if is_on_ceiling():
		position.y += -0.001
		velocity.y = -0.5

#region -- SypherPk Flashbang
	if Input.is_action_just_pressed("sypherpk"):
		$Maxresdefault/Timer.start(10)
		$Maxresdefault/Sypherpk.play()
	$Maxresdefault.self_modulate.a = $Maxresdefault/Timer.time_left / 10
#endregion

#region -- Gravity
	if not is_on_floor() and not is_on_wall_only():
		velocity.y += (get_gravity().y * gravityStrenth) * delta
	elif is_on_wall_only():
		velocity.y += (get_gravity().y * gravityStrenth * wallFriction) * delta
#endregion

#region -- Hud
	var forwardSpeed = -((velocity.x * forwardDirection.x) + (velocity.z * forwardDirection.z))
	var leftwardSpeed = -((velocity.x * forwardDirection.rotated(Vector3(0,1,0),deg_to_rad(90)).x) + (velocity.z *forwardDirection.rotated(Vector3(0,1,0),deg_to_rad(90)).z))
	$Ui/Center/Forward.position.y = forwardSpeed
	if $Ui/Center/Forward.position.y > 0: $Ui/Center/Forward.position.y = 0
	$Ui/Center/Backward.position.y = forwardSpeed
	if $Ui/Center/Backward.position.y < 0: $Ui/Center/Backward.position.y = 0

	$Ui/Center/Cross.position = Vector2(leftwardSpeed, forwardSpeed) * 2

	if Vector2(leftwardSpeed, forwardSpeed) != Vector2(0, 0):
		$Ui/Center/Direction.show()
		$Ui/Center/Direction.look_at(Vector2(leftwardSpeed + 576.0, forwardSpeed + 324.0))
	else:
		$Ui/Center/Direction.hide()

	$Ui/UiDashes.text = str(activeJumps.size(), "⁄", Globals.jumpSlots)
	$Ui/UiJumps.text = str(activeDashes.size(), "⁄", Globals.dashSlots)
	$Ui/UiScore.text = str(activeGoals.size(), "⁄", str(Globals.quota))
	@warning_ignore("integer_division")
	$Ui/UiStamina.text = str(roundi((stamina / Globals.maxStamina) * 100), "%")
	#$Ui/UiStamina.text = str(stamina) + '/' + str(Globals.maxStamina)
	$Ui/UiLevel.text = str(Globals.level)

	$Ui/Upgrade/UpMoney.text = str(Globals.money)
	$Ui/Upgrade/UpJump.text = '+1 Jump \n' + str(Globals.money) + '/' + str(Globals.jumpCost)
	$Ui/Upgrade/UpDash.text = '+1 Dash \n' + str(Globals.money) + '/' + str(Globals.dashCost)
	$Ui/Upgrade/UpLife.text = '+1 Life \n' + str(Globals.money) + '/' + str(Globals.lifeCost)
	$Ui/Upgrade/UpRun.text = '+25 Stamina \n' + str(Globals.money) + '/' + str(Globals.runCost)


	$Ui/Center/Left.position.x = leftwardSpeed
	if $Ui/Center/Left.position.x > 0: $Ui/Center/Left.position.x = 0
	$Ui/Center/Right.position.x = leftwardSpeed
	if $Ui/Center/Right.position.x < 0: $Ui/Center/Right.position.x = 0

	if not $Ui/Upgrade.visible:
		if Input.is_action_just_pressed("esc"):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	Globals.score = activeGoals.size()

	if Globals.intermission:
		$Ui/Upgrade.show()
		Globals.money += Globals.score - Globals.quota
		Globals.intermission = false
		allowInput = false

	$Ui/UiDebug.text = str(Globals.score >= Globals.quota) + '\n' + str(Globals.score) + '/' + str(Globals.quota)
#endregion

#region -- Shaders
	material.set_shader_parameter("shake_power", ((-($"Death Anim".time_left * 2) + 2) / 2) * 0.1)
	material.set_shader_parameter("shake_block_size", ((-($"Death Anim".time_left * 2) + 2) / 2) * 200)
#endregion

#region -- Slope Redirect
	if realSpeed > redirectBuffer and (get_floor_normal() != Vector3(0, -1.0, 0) and get_floor_normal() != Vector3(0, 0.0, 0)):
		velocity = velocity.bounce(get_floor_normal())
#endregion

#region -- Wall Jump
	var trueWallPush = Vector3()

	if is_on_wall_only() and not crouched:
		velocity.y = clamp(velocity.y, wallMin, befVelocity1 * wallFrac)
		if trueDirection == Vector3(0.0, 0.0, 0.0):
			trueWallPush = get_wall_normal()
		else:
			trueWallPush = trueDirection.bounce(get_wall_normal()).normalized()
	else:
		befVelocity1 = velocity.y

	var tilt = sin(acos(forwardDirection.dot(get_wall_normal().rotated(Vector3(0,1,0),deg_to_rad(90)))) + (PI / 2))
	if is_on_wall_only():
		camOffset.z = tilt * deg_to_rad(-camOffsetAmount)
	else:
		camOffset.z = 0

	if is_on_wall_only() and Input.is_action_just_pressed("jump") and trueDirection.dot(get_wall_normal()) < 0:
		if realSpeed < wallJumpForce:
			pass
		velocity = trueWallPush * wallpushForce
		velocity.y = wallJumpForce
#endregion

#region -- Dash
	if Input.is_action_just_pressed("dash") and activeDashes.size() > 0:
		if trueDirection == Vector3(0, 0, 0):
			if (dashForce * realSpeed) < dashMinForce - 2:
				dashVelocity = forwardDirection * dashMinForce
			else:
				dashVelocity = forwardDirection * (dashForce * realSpeed)
		else:
			if (dashForce * realSpeed) < dashMinForce - 2:
				dashVelocity = trueDirection * dashMinForce
			else:
				dashVelocity = trueDirection * (dashForce * realSpeed)
		$Dash.start(dashTime)
		activeDashes.remove_at(0)

	if $Dash.time_left != 0:
		velocity = dashVelocity
#endregion

#region -- Speed/Acceleration Control
	if (Input.is_action_pressed("sprint") and stamina > 0) and not crouched:
		trueSpeed = sprintSpeed
		footInterval = runFootInterval
	elif crouched:
		trueSpeed = crouchSpeed
		footInterval = walkFootInterval
	else:
		trueSpeed = walkSpeed
		footInterval = walkFootInterval

	if is_on_floor():
		speed = trueSpeed
		if crouched:
			if sliding:
				acceleration = slideAcceleration
			else:
				if realSpeed > crouchSpeed:
					acceleration = slideAcceleration
				else:
					acceleration = crouchAcceleration
		else:
			acceleration = groundAcceleration
	else:
		if crouched:
			speed = trueSpeed + airSpeed + crouchAirSpeed
		else:

			speed = trueSpeed + airSpeed
		acceleration = airAcceleration
#endregion

#region -- Crouch/Slide
	if (Input.is_action_pressed("crouch") or $CrouchFix.get_overlapping_bodies().size() > 1) or sliding:
		crouched = true
	else:
		crouched = false

	#region -- Crouch Anim
	if crouched:
		$Standing.hide()
		$Standing.disabled = true
		$Crounched.show()
		$Crounched.disabled = false
		$Camera.position.y = -1
	else:
		$Standing.show()
		$Standing.disabled = false
		$Crounched.hide()
		$Crounched.disabled = true
		$Camera.position.y = 1.1
	#endregion

	if realSpeed > slideBuffer:
		canSlide1 = true
	else:
		canSlide1 = false
	if canSlide1 and canSlide2 and is_on_floor() and crouched and $Slide.time_left == 0 and stamina > slidingCost:
		sliding = true
		canSlide2 = false
		velocity = realDirection * (realSpeed * slideForce)
		stamina += -slidingCost
		$Slide.start(slideTime)

	if not crouched:
		canSlide2 = true

	if $Slide.time_left == 0:
		sliding = false
#endregion

#region -- Jump
	if is_on_floor():
		$Cyotee.start(cyoteTime)

	if Input.is_action_just_pressed("jump") and ($Cyotee.time_left > 0 or activeJumps.size() > 0) and not is_on_wall():
		if $Cyotee.time_left == 0:
			activeJumps.remove_at(0)
		velocity.y = jumpForce
		$Cyotee.stop()
#endregion

#region -- Movement
	forwardDirection = $ForwardMark.global_position - global_position

	realSpeed = velocity.length()
	if realSpeed == 0:
		realDirection = Vector3(0, 0, 0)
	else:
		realDirection = velocity / realSpeed

	var rawInput : Vector2

	if allowInput:
		rawInput = Input.get_vector("left", "right", "forward", "backward")
	else:
		rawInput = Vector2(0, 0)
	var velocityFoward : Vector3 = $".".global_basis.z
	var velocityRight : Vector3 = $".".global_basis.x

	if rawInput != Vector2(0, 0) and $AudioStreamPlayer3D/FootstepInterval.time_left == 0:
		$AudioStreamPlayer3D.play()
		$AudioStreamPlayer3D/FootstepInterval.start(footInterval)

	if Input.is_action_pressed("sprint"):
		stamina += -runningCost * delta
	elif stamina < Globals.maxStamina:
		if velocity == Vector3(0,0,0):
			stamina += idleRegen * delta
		else:
			stamina += staminaRegen * delta

	if stamina < 0:
		stamina = 0

	if stamina > Globals.maxStamina:
		stamina = Globals.maxStamina

	trueDirection = velocityFoward * rawInput.y + velocityRight * rawInput.x
	trueDirection.y = 0.0
	trueDirection = trueDirection.normalized()

	velocity = velocity.move_toward(trueDirection * speed, acceleration)

	if is_on_ceiling():
		velocity.y = -0.001

	if $"Death Anim".time_left == 0:
		for i in velocityMult:
			move_and_slide()
#endregion

func jumpCrystal(body) -> void:
	activeJumps.append(body)


func dashCrystal(body) -> void:
	activeDashes.append(body)


func goalCrystal(body) -> void:
	activeGoals.append(body)


func damage(pos : Vector3 = Vector3(0,0,0), power : int = 0) -> void:
	Globals.deathAnim = true
	if $"Death Anim".time_left == 0:
		$RigidBody3D/Camera3D.rotation = $Camera.rotation
		$Camera.current = false
		$RigidBody3D/Camera3D.current = true
		$RigidBody3D.show()
		$RigidBody3D.freeze = false
		$Standing/Standing.hide()
		$Crounched/MeshInstance3D.hide()
		$DeathShader.show()
		$RigidBody3D.global_rotation.y = global_rotation.y

		$Standing.disabled = true
		$Crounched.disabled = true

		if pos != Vector3(0,0,0) and power != 0:
			$"Death Anim/Death Anim Dir".global_position = global_position
			$"Death Anim/Death Anim Dir".look_at(pos)
			$RigidBody3D.linear_velocity = (global_position - $"Death Anim/Death Anim Dir/Negative Anim Dir".global_position) * power
		else:
			$RigidBody3D.linear_velocity = velocity

		$"Death Anim".start(0.5)


func _on_death_anim_timeout() -> void:
	Globals.deathAnim = false
	Globals.lives += -1
	if Globals.lives <= 0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		reload()


func reload() -> void:
	$Camera.current = true
	$RigidBody3D/Camera3D.current = false
	$RigidBody3D.hide()
	$RigidBody3D.freeze = true
	$Standing/Standing.show()
	$Crounched/MeshInstance3D.show()
	$DeathShader.hide()
	activeDashes.clear()
	activeJumps.clear()
	Engine.time_scale = 1
	position = spawn
	rotation = Vector3(0, 0, 0)
	velocity = Vector3(0, 0, 0)
	$RigidBody3D.position = Vector3(0, 0, 0)
	$RigidBody3D.rotation = Vector3(0, 0, 0)
	$RigidBody3D.linear_velocity = Vector3(0, 0, 0)
	$RigidBody3D.angular_velocity = Vector3(0, 0, 0)
	$Standing.disabled = false
	$Crounched.disabled = false
	for i in $Ui/UiLives.get_children():
		i.queue_free()
	for i in range(Globals.lives):
		inst(lifeIcon, Vector2((i * 20), 0), $Ui/UiLives)


func inst(node, pos, parent)  -> void:
	var instance = node.instantiate()
	instance.position = pos
	parent.add_child(instance)


func _on_continue_pressed() -> void:
	Globals.continued = true


func _on_up_jump_pressed() -> void:
	if Globals.money >= Globals.jumpCost:
		Globals.money -= Globals.jumpCost
		Globals.jumpSlots += 1
		Globals.jumpCost += 2


func _on_up_dash_pressed() -> void:
	if Globals.money >= Globals.dashCost:
		Globals.money -= Globals.dashCost
		Globals.dashSlots += 1
		Globals.dashCost += 2


func _on_up_life_pressed() -> void:
	if Globals.money >= Globals.lifeCost:
		Globals.money -= Globals.lifeCost
		Globals.startLives += 1
		Globals.lifeCost += 5


func _on_up_run_pressed() -> void:
	if Globals.money >= Globals.runCost:
		Globals.money -= Globals.runCost
		Globals.maxStamina += 25
		Globals.runCost += 5
