extends "res://nodes/warp_region/WarpRegion.gd"

func _update_process(_ignored = null):
	var p = not disabled and (walkers.size() > 0 or get_overlapping_bodies().size() > 0)
	if not is_processing() and p:
		_frames_processed = 0
	set_process(p)
