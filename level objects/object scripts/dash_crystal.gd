extends Area3D

var transition = 0
const transitionTime = 2

const enabledRotationSpeed = 5
const disabledRotationSpeed = -3

const enabledColor = Color(1, 0, 1)
const disabledColor = Color(1, 0, 0.75)

const enabledLightStrenth = 1.0
const disabledLightStrenth = 0.5

var disabled = false

func _process(delta: float) -> void:
	$MeshInstance3D.rotation.y += lerp(enabledRotationSpeed, disabledRotationSpeed, transition) * delta
	$MeshInstance3D.material_override.albedo_color = lerp(enabledColor, disabledColor, transition)
	$MeshInstance3D.material_override.emission = lerp(enabledColor, disabledColor, transition)
	$MeshInstance3D/OmniLight3D.light_energy = lerp(enabledLightStrenth, disabledLightStrenth, transition)
	$MeshInstance3D/OmniLight3D.light_color = lerp(enabledColor, disabledColor, transition)
	if Globals.player.activeDashes.has(self):
		disabled = true
		transition = move_toward(transition, 1, transitionTime * delta)
	else:
		disabled = false
		transition = move_toward(transition, 0, transitionTime * delta)

func _on_body_entered(body: Node3D) -> void:
	if body == Globals.player and (not disabled) and Globals.player.activeDashes.size() < Globals.dashSlots:
		Globals.player.dashCrystal(self)
		$AudioStreamPlayer3D.play()
