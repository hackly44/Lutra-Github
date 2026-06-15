extends Area3D

var playing = true
var tracking = true
const lookSpeed = 3
const speed = 20
const vector = Vector3(0, 0, -1)

func _process(delta: float) -> void:
	$ForwardDir.look_at(Globals.player.global_position)

	if tracking and playing:
		$AudioStreamPlayer3D2.play()
		playing = false

	$RealForwardDir.rotation.x = rotate_toward($RealForwardDir.rotation.x, $ForwardDir.rotation.x, lookSpeed * delta)
	$RealForwardDir.rotation.y = rotate_toward($RealForwardDir.rotation.y, $ForwardDir.rotation.y, lookSpeed * delta)

	$Mesh.rotation = $RealForwardDir.rotation

	var forwardVe = $RealForwardDir.global_basis.z.normalized() * -speed
	position += forwardVe * delta

func _on_body_entered(body: Node3D) -> void:
	if body == Globals.player and !Globals.deathAnim:
		Globals.player.damage(global_position, 10)
	$Mesh/MeshInstance3D.visible = false
	$Mesh/GPUParticles3D.emitting = false
	$AudioStreamPlayer3D.play()
	$AudioStreamPlayer3D2.stop()
	tracking = false
	$Timer.start(2)
	set_deferred("monitoring", false)

func _on_timer_timeout() -> void:
	self.queue_free()

func _on_audio_stream_player_3d_2_finished() -> void:
	playing = true
