extends KinematicBody2D
class_name Player

export var moveSpeed = 5000
export var sideSpeed = 2000
export var mHp = 1000
export var hp = -1
var velocity = Vector2.ZERO
export var maxBlood = 10.0
export var blood = -1.0
export var bloodDecay = 0.25 # per 10 secs

onready var wpn = $wpnPos.get_child(0)

signal hpChanged

func _ready():
	General.player = self
	if hp == -1:
		hp = mHp
	wpn.connect("rCooldownOver",self,"rangedCdOver")
	wpn.connect("reloadedFully",self,"rangedCdOver")
	wpn.connect("mCooldownOver",self,"meleeCdOver")
	connect("hpChanged",self,"updUi")
	wpn.connect("meleed",$AnimationPlayer,"play",["meleeAttack"])

func rangedCdOver():
	if Input.get_action_strength("fire")>0:
		wpn.fire()

func meleeCdOver():
	if Input.get_action_strength("melee")>0:
		wpn.melee()

func die():
	get_tree().reload_current_scene()

func _input(event):
	if event.is_action_pressed("fire"):
		wpn.fire()
	if event.is_action_pressed("reload"):
		wpn.reload()
	if event.is_action_pressed("melee"):
		wpn.melee()

func takeDamage(amount:int):
	hp -= amount
	if hp <= 0:
		die()
	else:
		emit_signal("hpChanged")

func updUi():
	print("plr hp "+str(hp)+"/"+str(mHp))

func _physics_process(delta):
	look_at(get_global_mouse_position())
	velocity = move_and_slide(Vector2(
		(Input.get_action_strength("moveUp")-Input.get_action_strength("moveDown"))*moveSpeed,
		(Input.get_action_strength("moveRight")-Input.get_action_strength("moveLeft"))*sideSpeed
			).rotated(rotation)*delta)


func _on_hitarea_area_entered(area):
	takeDamage(area.get_parent().damage)
	area.get_parent().queue_free()
