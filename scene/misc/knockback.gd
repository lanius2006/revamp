extends Node

export var direction = 0 # radians
export var strength = 5000
export var duration = 0.1

func _ready():
	var t = get_tree().create_timer(duration)
	t.connect("timeout",self,"queue_free")

func _physics_process(delta):
	get_parent().move_and_slide(Vector2(strength*delta,0).rotated(direction))
