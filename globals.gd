extends Node

var player

var level = 0

var score = 0
var startLives = 3
var lives = 15

var jumpCost = 1
var dashCost = 1
var lifeCost = 5
var runCost = 2

var quota = 3

var money = 0

var maxStamina = INF
var dashSlots = 1
var jumpSlots = 1

var FOV = 70
var Snesitivity = 1

const version = "Lutra v0.13.3\n\"Map Improvement 3\"\nhackly44 2026"

var deathAnim = false

var intermission = false
var continued = false

# Rooms
func f1(x: int):
	var X = float(x)
	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 1.0) / 15.0) + 1.0)) + 3.0))

# Goals min
func f2(x: int):
	var X = float(x)
	var ler

	if X <= 30.0:
		ler = 1.0 + (X / 30.0) * -1.0
	else:
		ler = 0.0

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 1.0) / 16.0) + 1.0)) + ler))

# Goals max
func f3(x: int):
	var X = float(x)
	var ler

	if X <= 30.0:
		ler = 0 + (X / 30.0) * 15.0
	else:
		ler = 15.0

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X + 5.0) / 18.0) + 1.0)) + ler))

# Enemies
func f4(x: int):
	var X = float(x)
	var ler

	if X <= 30.0:
		ler = -1.0 + (X / 30.0) * 2
	else:
		ler = 1

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 1.0) / 15.0) + 1.0)) + ler))

# Items
func f5(x: int):
	var X = float(x)

	return int(roundf(((5.0 * X) / (1.5 * 0.5 ** ((X - 10.0) / 20.0) + 1.0)) - 1))
