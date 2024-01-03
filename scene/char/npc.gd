extends KinematicBody2D

export var mHp = 100
export var hp = -1
export var moveSpeed = 1000
var velocity = Vector2.ZERO
onready var tPos = global_position
onready var agent = $agent
export var desEnmDistRanged = [64,80]
export var desEnmDistMelee = [25,30] # squared on ready
onready var enemyPos = global_position
var remAmmo = 0
onready var wpn = null
var curDesDist = desEnmDistMelee
export var inaccuracy = 10
var meleeDist = 38*38
export var weaponScene : PackedScene = preload("res://scene/wpn/wpn.tscn")

func minusRemAmmo(): # on reload fully & round loaded
	if wpn.reloadPerRound:
		remAmmo -= 1
	else: # reload fully
		remAmmo -= wpn.maxAmmo
	print(str(remAmmo))

func _ready():
	agent.set_navigation(General.nav)
	var nwpn = weaponScene.instance()
	$wpn/Node2D.add_child(nwpn)
	wpn = $wpn/Node2D.get_child(0)
	wpn.connect("meleed",$AnimationPlayer,"play",["meleeAttack"])
	wpn.inaccuracy += inaccuracy
	wpn.connect("reloadedFully",self,"minusRemAmmo")
	wpn.connect("roundLoaded",self,"minusRemAmmo")
#	wpn.connect("fired",self,"onEndReload")
#	wpn.connect()
	for i in 2:
		desEnmDistMelee[i] *= desEnmDistMelee[i]
		desEnmDistRanged[i] *= desEnmDistRanged[i]
	curDesDist = desEnmDistMelee
	
	agent.set_target_location(tPos)
	if hp == -1:
		hp = mHp
	
	$wpn.position = Vector2(10,-3).rotated($Sprite.rotation)

func _physics_process(delta):
	$vision.look_at(General.player.global_position)
	if $vision.get_collider() is Player:
		agent.set_target_location(General.player.global_position)
		enemyPos = General.player.global_position
		getNextAttackAction()
		wpn.look_at(enemyPos)
		$wpn.position = Vector2(10,-3).rotated($Sprite.rotation)
		
	if !agent.is_navigation_finished():
		$Sprite.look_at(tPos)
		tPos = agent.get_next_location()
#		print(str(tPos))
	
	
	if global_position.distance_squared_to(enemyPos) < curDesDist[0]: # closer than desired
		velocity = move_and_slide(to_local(tPos).normalized()*delta*-moveSpeed)
	elif Utils.in_range(curDesDist[0], curDesDist[1],global_position.distance_squared_to(enemyPos)): # in range
		velocity = Vector2.ZERO
	elif global_position.distance_squared_to(enemyPos) > curDesDist[1]:
		velocity = move_and_slide(to_local(tPos).normalized()*delta*moveSpeed)
	

func die():
	queue_free()

func getAttackPreference():
	var pref = "melee"
	if global_position.distance_squared_to(enemyPos)>=(meleeDist): # dist great
		if wpn.ranged:
			if remAmmo>0 or wpn.ammo>0:
				pref = "ranged"
				curDesDist = desEnmDistRanged
			elif remAmmo<=0 && wpn.melee: # no ammo
				pref = "melee"
				curDesDist = desEnmDistMelee
		elif wpn.melee:
			curDesDist = desEnmDistMelee
			pref = "melee"
	elif wpn.melee:
		pref = "melee"
		curDesDist = desEnmDistMelee
	print(str(sqrt(global_position.distance_squared_to(enemyPos)))+pref)
	return pref

func getNextAttackAction():
	if $actionTimer.is_stopped():
		if getAttackPreference() == "ranged":
			rangedLoop()
		else:
			meleeLoop()

func onEndReload():
	getNextAttackAction()

func meleeLoop():
	if global_position.distance_squared_to(enemyPos)<=meleeDist:
		wpn.melee()
		$actionTimer.start()
	# attack, cooldown
	# repeat
	# since based on preference, will update preference based on distance

func rangedLoop():
	if wpn.ammo<=0: # no ammo in gun
		print("reload")
		wpn.reload()
		$actionTimer.start()
		# wait for reload, recall
	else: # ammo in gun
		if wpn.cockable:
			if wpn.cocked:
				wpn.fire()
			else:
				wpn.cocked = true
				print("cocked!")
				$actionTimer.start()
		else: # non cockable
			wpn.fire()
			$actionTimer.start()

func takeDamage(amount:int):
	hp -= amount
	if hp <= 0:
		die()

func _on_hitarea_area_entered(area):
	takeDamage(area.get_parent().damage)
	area.get_parent().queue_free()
