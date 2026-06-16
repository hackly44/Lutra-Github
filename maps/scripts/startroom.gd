extends Node3D

const midRooms = [preload("res://maps/room_1.tscn"), preload("res://maps/room_2.tscn"), preload("res://maps/room_3.tscn")]
const roomChance = [5, 1, 2]
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

	Globals.quota = 0
	randiRoom = randomSet(midRooms, roomChance)

## Generate Rooms
	generate.call_deferred()

	#var room : Marker3D = midRooms[0].instantiate()
	#add_child(room)
	#await get_tree().process_frame
	#var roomStart : Marker3D = room.get_child(0).get_child(0)
	#room.global_position = $Generator/Generator1.global_position
	#room.global_rotation = $Generator/Generator1.global_rotation
	#print(roomStart.position)
	#for i : Node3D in room.get_children():
		#i.position += -roomStart.position
	#room.rotation += -roomStart.rotation - Vector3(0, deg_to_rad(180), 0)

## Instancer for rooms
func instRoom(node, pos, rot):
	var instance : Marker3D = node.instantiate()
	
	var roomStart : Marker3D = instance.get_child(0).get_child(randf_range(0, instance.get_child(0).get_child_count() - 1))
	
	instance.position = pos
	instance.rotation = rot
	
	for i : Node3D in instance.get_children():
		i.position += -roomStart.position
	instance.rotation += -roomStart.rotation - Vector3(0, deg_to_rad(180), 0)
	roomStart.set_meta('free', false)
	
	add_child(instance)
	rooms.append(instance)

func inst(node, pos, rot):
	var instance = node.instantiate()
	instance.position = pos
	instance.rotation = rot
	add_child(instance)

# Search and Return first found empty generator
func findOpen():
	var open = []
	for i in rooms:
		for o in i.get_child(0).get_children():
			if o.get_meta("free"):
				open.append(o)
	return(open)

# Weighted Random room generator
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

## ENABLE FOR NEXT RELEASE
func _on_area_3d_body_entered(body: Node3D) -> void:
	pass
	#if body == Globals.player:
		#if fEnter:
			#fEnter = false
		#else:
			#if Globals.score >= Globals.quota:
				#Globals.intermission = true

## --- AI WAS USED FOR THIS FUNCTION!!! ---
func is_area_overlapping_instant(area: Area3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	
	# Get the collision shape from the Area3D
	var shape_owner = area.get_shape_owners()[0]
	var shape = area.shape_owner_get_shape(shape_owner, 0)
	
	# Set up the intersection query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = area.global_transform
	query.collision_mask = area.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	# Exclude itself from the check
	query.exclude = [area.get_rid()] 
	
	# Check for intersections immediately
	var results = space_state.intersect_shape(query, 1)
	return results.size() > 0

func generate() -> void:
	while not (generationPasses <= 0 or findOpen().size() == 0 or err > errBuffer):
		var gen = 0
		for j in range(generationPasses):
			var room = randiRoom.pick_random()
			if findOpen().size() == 0:
				break
			var root = findOpen().pick_random()
			instRoom(room, root.global_position, root.global_rotation)
			genErr = false
			await get_tree().physics_frame
			var roomAABB : Area3D = rooms[-1].get_child(1)
			var rootAABB : Area3D = root.get_parent().get_parent().get_child(1)
			rootAABB.set_collision_layer_value(4, false)
			if is_area_overlapping_instant(roomAABB):
				print('room overlap')
				rooms[-1].free()
				rooms.resize(rooms.size() - 1)
				genErr = true
			rootAABB.set_collision_layer_value(4, true)
			if not genErr:
				root.set_meta("free", false)
				generationPasses += -1
				gen += 1
			#await self.step_pressed
		if gen == 0:
			err += 1
	for i in findOpen():
		inst(endRoom, i.global_position, i.global_rotation)

#region -- Generate Enemies
	for i in rooms:
		if i.get_child(2).get_child_count() != 0:
			for j in i.get_child(2).get_children():
				enemySpawns.append(j)
	for i in range(enemyPasses):
		var root = enemySpawns.pick_random()
		var enemy = enemys.pick_random()
		inst(enemy, root.global_position, Vector3(0, 0, 0))
		enemySpawns.erase(root)
#endregion

#region -- Generate Goals
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
#endregion

#region -- Generate Items
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
#endregion

signal step_pressed

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_L and event.pressed:
			step_pressed.emit()
