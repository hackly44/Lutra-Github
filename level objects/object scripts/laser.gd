extends Node3D

var speed = 0.5

func _process(delta: float) -> void:
	if Globals.deathAnim:
		$Timer.start(2)
	$RayCast3D.target_position = Globals.player.global_position - global_position

	if $RayCast3D.is_colliding():
		$LaserDir.look_at(Globals.player.global_position)
		$Timer.start()

	$PlayerDir.look_at(Globals.player.global_position)

	if $Timer.time_left == 0:
		$LaserBeam/MeshInstance3D3.show()
		$LaserDir.rotation.y = rotate_toward($LaserDir.rotation.y, $PlayerDir.rotation.y, speed * delta)
		$LaserDir.rotation.x = rotate_toward($LaserDir.rotation.x, $PlayerDir.rotation.x, (speed / 2) * delta)
		$LaserBeam.look_at($LaserDir/Marker3D.global_position)

		$Laser.target_position = ($LaserDir/Marker3D.global_position - global_position) * 40

	else:
		$Laser.target_position = Vector3(0, 0, 0)

	if $Laser.get_collider() == Globals.player:
		Globals.player.damage()

	drawLaser()

func drawLaser():
	if $Laser.target_position != Vector3(0, 0, 0):
		$LaserBeam/MeshInstance3D3.show()
		$LaserBeam/MeshInstance3D3.global_position = (global_position - $Laser.get_collision_point())/2 + $Laser.get_collision_point()
		$LaserBeam/MeshInstance3D3.mesh.height = sqrt((global_position.x - $Laser.get_collision_point().x) ** 2 + (global_position.y - $Laser.get_collision_point().y) ** 2 + (global_position.z - $Laser.get_collision_point().z) ** 2) + 1
	else:
		$LaserBeam/MeshInstance3D3.hide()
