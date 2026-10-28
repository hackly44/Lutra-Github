@tool
extends Node3D

# Drag your unindexed, baked CSG MeshInstance3D into this slot in the inspector
@export var target_mesh_instance: MeshInstance3D
@export var trigger_reindex: bool = false:
	set(val):
		if target_mesh_instance and target_mesh_instance.mesh:
			reindex_mesh()

func reindex_mesh():
	var old_mesh = target_mesh_instance.mesh
	var st = SurfaceTool.new()
	
	# Read the old mesh surfaces and generate indices
	for i in old_mesh.get_surface_count():
		st.append_from(old_mesh, i, Transform3D.IDENTITY)
	st.index() # <--- This generates the missing index array!
	
	var new_mesh = st.commit()
	
	# Save it back to your mesh instance
	target_mesh_instance.mesh = new_mesh
	print("Mesh successfully re-indexed! You can now bake your OccluderInstance3D.")
