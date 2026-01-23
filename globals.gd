extends Node

var player

var level = 0

var score = 0
var lives = 3

var quota = 3

var FOV = 70
var Snesitivity = 1

const version = "Lutra v0.11.7\nhackly44 2026"

var deathAnim = false

var intermission = false
var continued = false

# Rooms
func f1(x: int):
	var X = float(x)
	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 1.0) / 15.0) + 1.0)) + 3.0))

# Goals
func f2(x: int):
	var X = float(x)
	var ler

	if X <= 30.0:
		ler = 1.0 + (X / 30.0) * -1.0
	else:
		ler = 0.0

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 1.0) / 16.0) + 1.0)) + ler))

# Enemies
func f3(x: int):
	var X = float(x)
	var ler

	if X <= 30.0:
		ler = -1.0 + (X / 30.0) * 2
	else:
		ler = 1

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 1.0) / 15.0) + 1.0)) + ler))

# Items
func f4(x: int):
	var X = float(x)

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 10.0) / 20.0) + 1.0)) - 1))
