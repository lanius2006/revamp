extends Node

var player = null

func addProj(proj):
	get_tree().current_scene.get_node("projectiles").add_child(proj)
