extends KinematicBody2D

export var speed = 10000
export var damage = 50
export var deathTime = 5

func _physics_process(delta):
	move_and_slide(Vector2(speed*delta,0).rotated(rotation))

func _ready():
	var t = get_tree().create_timer(deathTime)
	t.connect("timeout",self,"queue_free")


func _on_hitarea_body_entered(body):
	queue_free()
