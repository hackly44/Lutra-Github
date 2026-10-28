extends Node3D

func _process(_delta: float) -> void:
	if not get_viewport().get_camera_3d().is_position_behind(global_position):
		$Sprite2D.position = get_viewport().get_camera_3d().unproject_position(global_position)

	$Sprite2D/ProgressBar.visible = ($Sprite2D.position.distance_to(Vector2(576,324)) < 30)

	if not ($Sprite2D.position.distance_to(Vector2(576,324)) < 30 and Input.is_action_pressed("lmb")):
		$Timer.start(1)

	$Sprite2D/ProgressBar.value = 1 - $Timer.time_left

func _on_timer_timeout() -> void:
	var prePos = global_position
	var preRot = global_rotation
	global_position = GB.player.global_position
	global_rotation = GB.player.global_rotation
	GB.player.global_position = prePos
	GB.player.global_rotation = preRot
