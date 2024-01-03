extends Node

var player = null
onready var nav = get_tree().current_scene.get_node("Navigation2D")

func addProj(proj):
	get_tree().current_scene.get_node("projectiles").add_child(proj)

func getAvailableTile():
	var map = nav.get_node("TileMap")
	return map.map_to_world(
		Utils.randArrayItem(
			map.get_used_cells_by_id(0)
		)
	)
