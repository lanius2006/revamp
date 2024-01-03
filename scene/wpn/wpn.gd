extends Sprite
class_name Weapon

export var melee = true
export var ranged = true
export var meleeDmg = 15
export var rangedDmg = 50
export var meleeCooldown = 1.0
export var rangedCooldown = 0.5
export var maxAmmo = 8
export var ammo = -1
export var pullTrigger = false
export var reloadTime = 0.5
export var reloadPerRound = false
export var projCount = 1
export var proj : PackedScene = preload("res://scene/misc/bullet.tscn")
export var inaccuracy = 10 # degrees
export var cockable = false
export var cocked = false
export var mproj : PackedScene = preload("res://scene/misc/bullet.tscn")
export var recoilDuration = 0.2
export var reocoilStrength = 5000

signal reloadedFully
signal roundLoaded
signal reloadStarted
signal fired
signal meleed
signal rCooldownOver
signal mCooldownOver

func areTimersStopped():
	return $rangedTimer.is_stopped() && $reloadTimer.is_stopped() && $meleeTimer.is_stopped()

func _ready():
	$reloadTimer.wait_time = reloadTime
	$meleeTimer.wait_time = meleeCooldown
	$rangedTimer.wait_time = rangedCooldown
	if ammo == -1:
		ammo = maxAmmo

func reload():
	if ammo<maxAmmo && $reloadTimer.is_stopped():
		emit_signal("reloadStarted")
		$reloadTimer.start()

func reloadEnd():
	if reloadPerRound:
		ammo += 1
		if ammo == maxAmmo:
			emit_signal("reloadedFully")
		else:
			emit_signal("roundLoaded")
			reload()
	else:
		ammo = maxAmmo
		emit_signal("reloadedFully")
	print("ammo "+str(ammo))

func fire():
	if ammo>0 && areTimersStopped():
		cocked = false
		ammo -= 1
		print("ammo "+str(ammo))
		emit_signal("fired")
		for i in projCount:
			var np = proj.instance()
			np.global_position = $shootPos.global_position
			np.global_rotation_degrees = global_rotation_degrees+Utils.rollNumber(-inaccuracy,inaccuracy)
			np.damage = rangedDmg
			General.addProj(np)
		$rangedTimer.start()

func melee():
	if areTimersStopped() && melee:
		emit_signal("meleed")
		var np = mproj.instance()
		np.deathTime = 0.1
		np.global_position = global_position
		np.global_rotation_degrees = global_rotation_degrees
		np.damage = meleeDmg
		np.visible = false
		General.addProj(np)
		$meleeTimer.start()
		print("meleed")

func _on_rangedTimer_timeout():
	emit_signal("rCooldownOver")


func _on_reloadTimer_timeout():
	reloadEnd()


func _on_meleeTimer_timeout():
	emit_signal("mCooldownOver")
