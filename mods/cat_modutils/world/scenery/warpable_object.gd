extends Spatial


func _arrive_at_warp_target(pos: Vector3, dir: Vector3):
	global_transform.origin = pos
	look_at(global_translation + dir, Vector3.UP)
	#set_initial_direction(Direction.get_nearest_xz(dir))
