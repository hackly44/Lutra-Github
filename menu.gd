extends Node2D

func _ready() -> void:
	$"Verson Lable".text = Globals.version

func _on_button_pressed() -> void:
	$AudioStreamPlayer.play()
	get_tree().change_scene_to_file("res://maps/startroom.tscn")
	Globals.lives = 3

func _on_test_play_pressed() -> void:
	$AudioStreamPlayer.play()
	get_tree().change_scene_to_file("res://maps/testroom.tscn")
	Globals.lives = 3

func _process(_delta: float) -> void:
	Globals.FOV = $Panel/FOVPanel/FOV.value
	Globals.Snesitivity = $Panel/SensitivityPanel/Sensitivity.value / 100

	$Panel/FOVPanel/FOVValue.text = str($Panel/FOVPanel/FOV.value)
	$Panel/SensitivityPanel/SensitivityValue.text = str($Panel/SensitivityPanel/Sensitivity.value)
