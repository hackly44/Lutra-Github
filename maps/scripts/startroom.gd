extends Node3D

const midRooms = [preload("res://maps/room_1.tscn"), preload("res://maps/room_2.tscn")]
const roomChance = [100, 50]

const endRoom = preload("res://maps/endroom.tscn")

var rooms = [self]

const enemys = [preload("res://level objects/launcher.tscn"), preload("res://level objects/laser.tscn")]
var enemySpawns = []

const items = [preload("res://level objects/dash_crystal.tscn"), preload("res://level objects/jump_crystal.tscn")]
var itemSpawns = []

const goal = preload("res://level objects/goal_crystal.tscn")

var genErr = false

var err = 0
var errBuffer = 4

#region -- Generation Passes
var generationPasses = 5
var enemyPasses = 1
var itemPasses = 1
#endregion

func _ready():

	Globals.level += 1

	generationPasses = Globals.f1(Globals.level)
	Globals.quota = Globals.f2(Globals.level)
	enemyPasses = Globals.f3(Globals.level)
	itemPasses = Globals.f4(Globals.level)

## Generate Rooms
	while not (generationPasses <= 0 or findOpen().size() == 0 or err > errBuffer):
		var gen = 0
		for j in range(generationPasses):
			var room = midRooms[randArray(roomChance)]
			if findOpen().size() == 0:
				break
			var root = findOpen().pick_random()
			instRoom(room, root.global_position, root.global_rotation)
			genErr = false
			for i in rooms:
				var roomAABB = rooms[-1].get_child(1).global_transform * rooms[-1].get_child(1).get_aabb()
				var rootAABB = i.get_child(1).global_transform * i.get_child(1).get_aabb()
				if roomAABB.intersects(rootAABB) and not (rooms[-1] == i):
					#print("error generate - ", rooms[-1].get_instance_id())
					rooms[-1].queue_free()
					rooms.resize(rooms.size() - 1)
					genErr = true
					break
			if not genErr:
				root.set_meta("free", false)
				#print("room generated - ", rooms[-1].get_instance_id())
				generationPasses += -1
				gen += 1
		if gen == 0:
			err += 1
	for i in findOpen():
		inst(endRoom, i.global_position, i.global_rotation)

## Generate Enemies
	for i in rooms:
		if i.get_child(2).get_child_count() != 0:
			for j in i.get_child(2).get_children():
				enemySpawns.append(j)
	for i in range(enemyPasses):
		var root = enemySpawns.pick_random()
		var enemy = enemys.pick_random()
		inst(enemy, root.global_position, Vector3(0, 0, 0))
		enemySpawns.erase(root)

## Find all open item / goal spawns
	for i in rooms:
		if i.get_child(3).get_child_count() != 0:
			for j in i.get_child(3).get_children():
				itemSpawns.append(j)

## Generate Goals
	for i in range(int(Globals.quota * randf_range(1.0, 1.5))):
		#print(i)
		var root = itemSpawns.pick_random()
		inst(goal, root.global_position, root.global_rotation)
		itemSpawns.erase(root)

## Generate Items
	var passes = 0
	if itemPasses < itemSpawns.size():
		passes = itemPasses
	else:
		passes = itemSpawns.size()
	for i in range(passes):
		var root = itemSpawns.pick_random()
		var item = items.pick_random()
		inst(item, root.global_position, root.global_rotation)
		itemSpawns.erase(root)

## Instancer for rooms
func instRoom(node, pos, rot):
	var instance = node.instantiate()
	instance.position = pos
	instance.rotation = rot
	add_child(instance)
	rooms.append(instance)


func inst(node, pos, rot):
	var instance = node.instantiate()
	instance.position = pos
	instance.rotation = rot
	add_child(instance)


## Search and Return first found empty generator
func findOpen():
	var open = []
	for i in rooms:
		for o in i.get_child(0).get_children():
			if o.get_meta("free"):
				open.append(o)
	return(open)


func randArray(x):
	var total = 0
	var totals = [0]
	var rand = 0
	for i in x:
		total += i
		totals.append(total)
	rand = randi_range(0, total - 2)

	for i in range(totals.size()):
		if i < totals.size() - 1:
			if rand >= totals[i] and rand <= totals[i + 1]:
				return(i)
		else:
			return(i)

var fEnter = true

func _process(_delta: float) -> void:
	if Globals.deathAnim:
		fEnter = true
	if Globals.continued:
		Globals.continued = false

		Globals.lives = 3

		get_tree().reload_current_scene()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == Globals.player:
		if fEnter:
			fEnter = false
		else:
			if Globals.score >= Globals.quota:
				print("level passed")
				Globals.intermission = true
