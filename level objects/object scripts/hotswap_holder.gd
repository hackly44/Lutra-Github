extends Node3D

var id = randi()

func _process(_delta: float) -> void:
	Globals.hotSwapHolders[id] = self
