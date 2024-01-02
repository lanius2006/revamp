extends Node

var rng = RandomNumberGenerator.new()

func rollNumber(m=0,M=3,S=1):
	rng.randomize()
	return int(stepify(rng.randi_range(m,M),S))

func randArrayItem(array:Array):
	var res = null
	rng.randomize()
	if !array.size()==0:
		res = array[rng.randi_range(0,array.size()-1)]
	return res

func randBool():
	rng.randomize()
	return bool(rng.randi_range(0,1))

func rollFloat(m:float,M:float,s:float):
	rng.randomize()
	return stepify(rng.randf_range(m,M),s)

func biSign(num):
	if num<0:
		return -1
	else:
		return 1

func in_range(m,M,n):
	return (m<n && n<M)

func randomBox(motherArray:Array): # ponokefalos gamo th mana mou
	#----------------------------
	# M array = [ array1=[object,chance], array2... etc]
	# add chance range so array1=[object,chance,[minChance,maxChance]]
	# if chance is in range of array, it's first element (object) is chosen.
	# incredible weighted chance system, good for loot boxes and shit like that.
	#----------------------------
	var mArray = motherArray.duplicate()
	rng.randomize()
	var maxChance = 0
	# create values
	for array in mArray:
		maxChance += array[1] # second value of child array is chance
		array.append([maxChance-array[1],maxChance]) # element 2 is chance range
	
	var chance = rng.randf_range(0,maxChance)
	
	var res
	for array in mArray:
		if in_range( # if chance in range of array (element is chosen)
			# third element (range)
			array[2][0],array[2][1],chance
			):
				res = array[0]
	return res
	
