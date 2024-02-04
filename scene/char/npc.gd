extends KinematicBody2D

export var mHp = 100
export var hp = -1
export var moveSpeed = 1000
var velocity = Vector2.ZERO
onready var tPos = global_position
onready var agent = $agent
export var desEnmDistRanged = [pow(64,2),pow(38,2)]
export var desEnmDistMelee = [pow(25,2),pow(30,2)] # squared on ready
onready var enemyPos = global_position
var remAmmo = 0
onready var wpn = null
var curDesDist = desEnmDistMelee
export var inaccuracy = 10
var meleeDist = pow(38,2)
export(Array,PackedScene) var weaponScenes = [preload("res://scene/wpn/sword.tscn"),preload("res://scene/wpn/wpn.tscn"),preload("res://scene/wpn/crossbow.tscn")]

var enmVisible = false

func minusRemAmmo(): # on reload fully & round loaded
	if wpn.reloadPerRound:
		remAmmo -= 1
	else: # reload fully
		remAmmo -= wpn.maxAmmo
	print(str(remAmmo))

func _ready():
	agent.set_navigation(General.nav)
	var nwpn = Utils.randArrayItem(weaponScenes).instance()
	$wpn/Node2D.add_child(nwpn)
	wpn = $wpn/Node2D.get_child(0)
	wpn.connect("meleed",$AnimationPlayer,"play",["meleeAttack"])
	wpn.inaccuracy += inaccuracy
	wpn.connect("reloadedFully",self,"minusRemAmmo")
	wpn.connect("roundLoaded",self,"minusRemAmmo")
#	wpn.connect("fired",self,"onEndReload")
#	wpn.connect()
#	for i in 2:
#		desEnmDistMelee[i] *= desEnmDistMelee[i]
#		desEnmDistRanged[i] *= desEnmDistRanged[i]
	curDesDist = desEnmDistMelee
	if hp == -1:
		hp = mHp
	
	remAmmo = ceil(20*ceil(10/wpn.maxAmmo)) # 2 magazines
	
	$wpn.position = Vector2(10,-3).rotated($Sprite.rotation)
	randSpot()

func randSpot():
	var map = get_tree().current_scene.get_node("Navigation2D/TileMap")
	agent.set_target_location(map.map_to_world(
		Utils.randArrayItem(map.get_used_cells_by_id(1))
	)+Vector2.ONE*(map.cell_size/2))

func _physics_process(delta):
	$vision.look_at(General.player.global_position)
	if $vision.get_collider() is Player:
		enmVisible = true
	else:
		enmVisible = false
	
	if enmVisible:
		agent.set_target_location(General.player.global_position)
		enemyPos = General.player.global_position
		getNextAttackAction()
		wpn.look_at(enemyPos)
	
	if !agent.is_navigation_finished():
		$Sprite.look_at(tPos)
		tPos = agent.get_next_location()
		wpn.look_at(tPos)
	$wpn.position = Vector2(10,-3).rotated($Sprite.rotation)
	
	if enmVisible:
		if global_position.distance_squared_to(enemyPos) < curDesDist[0]: # closer than desired
			velocity = move_and_slide(to_local(tPos).normalized()*delta*-moveSpeed)
		elif Utils.in_range(curDesDist[0], curDesDist[1],global_position.distance_squared_to(enemyPos)): # in range
			velocity = Vector2.ZERO
		elif global_position.distance_squared_to(enemyPos) > curDesDist[1]: # farther than desired
			velocity = move_and_slide(to_local(tPos).normalized()*delta*moveSpeed)
	else:
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
		wpn.reload()
		$actionTimer.start()
		# wait for reload, recall
	else: # ammo in gun
		if wpn.cockable:
			if wpn.cocked:
				wpn.fire()
			else:
				wpn.cocked = true
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
