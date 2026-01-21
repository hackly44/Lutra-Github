extends Node3D

const missile = preload("res://level objects/rocket.tscn")

func _process(_delta: float) -> void:
	$RayCast3D.target_position = Globals.player.global_position - global_position
	if not $RayCast3D.is_colliding():
		$Marker3D.look_at(Globals.player.global_position)
		if $Children.get_children().size() == 0 and Globals.player.get_child(-1).time_left == 0:
			inst(missile, Vector3(0,0,0), $Marker3D.global_rotation, $Children)

func inst(node, pos, rot, parent):
	var instance = node.instantiate()
	instance.set_deferred("position", pos)
	instance.set_deferred("rotation", rot)
	parent.add_child(instance)
