extends Node3D

const midRooms = [preload("res://maps/room_1.tscn"), preload("res://maps/room_2.tscn")]
const roomChance = [3, 1]
var randiRoom = []

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
var maxGoalPasses = 100

#region -- Generation Passes
var generationPasses = 100
var enemyPasses = 0
var itemPasses = 0
#endregion

func _ready():

	Globals.level += 1

	#generationPasses = Globals.f1(Globals.level)
	#Globals.quota = Globals.f2(Globals.level)
	#maxGoalPasses = Globals.f3(Globals.level)
	#enemyPasses = Globals.f4(Globals.level)
	#itemPasses = Globals.f5(Globals.level)

	randiRoom = randomSet(midRooms, roomChance)

## Generate Rooms
	while not (generationPasses <= 0 or findOpen().size() == 0 or err > errBuffer):
		var gen = 0
		for j in range(generationPasses):
			var room = randiRoom.pick_random()
			if findOpen().size() == 0:
				break
			var root = findOpen().pick_random()
			instRoom(room, root.global_position, root.global_rotation)
			await get_tree().physics_frame
			genErr = false
			for i in rooms:
				var roomAABB = rooms[-1].get_child(1)
				var checkAABB = i.get_child(1)
				var rootAABB = root.get_parent().get_parent().get_child(1)
				if check_intersection(roomAABB, checkAABB) and roomAABB != checkAABB and roomAABB != rootAABB:
					rooms[-1].queue_free()
					rooms.resize(rooms.size() - 1)
					genErr = true
					break
			if not genErr:
				root.set_meta("free", false)
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
	for i in range(randi_range(Globals.quota, maxGoalPasses)):
		#print(i)
		var root = itemSpawns.pick_random()
		inst(goal, root.global_position, root.global_rotation)
		itemSpawns.erase(root)
		if itemSpawns.size() == 0:
			break

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

## Weighted Random room generator
func randomSet(value : Array, weight : Array):
	var arr = []
	for i in range(value.size()):
		var x = value[i]
		for j in range(weight[i]):
			arr.append(x)

	return(arr)

var fEnter = true

func _process(_delta: float) -> void:
	if Globals.deathAnim:
		fEnter = true
	if Globals.continued:
		Globals.continued = false

		Globals.lives = Globals.startLives

		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("enter"):
		get_tree().reload_current_scene()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == Globals.player:
		if fEnter:
			fEnter = false
		else:
			if Globals.score >= Globals.quota:
				Globals.intermission = true

## --- AI WAS USED FOR THIS FUNCTION!!! ---
func check_intersection(mesh_a : MeshInstance3D, mesh_b : MeshInstance3D) -> bool:
	# 1. Create temporary shape resources
	var shape_a := ConvexPolygonShape3D.new()
	var shape_b := ConvexPolygonShape3D.new()
	
	# 2. Populate them with your mesh vertex data
	shape_a.points = mesh_a.mesh.get_faces()
	shape_b.points = mesh_b.mesh.get_faces()
	
	# 3. Set up the shape query parameters
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_a
	query.transform = mesh_a.global_transform
	
	# 4. Optional: If you only want to check against mesh_b specifically,
	# you can dynamically read its collision body if it has one, 
	# or let it query the entire physics world space:
	var space_state := get_world_3d().direct_space_state
	var results := space_state.collide_shape(query)
	
	return results.size() > 0
