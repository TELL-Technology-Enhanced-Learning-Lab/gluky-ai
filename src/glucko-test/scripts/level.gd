extends Node3D

@export var modules: Array [PackedScene] = []
var amount = 50
var rng = RandomNumberGenerator.new()
var offset = 3
var initObs = 0
var started = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for n in amount:
		spawnModule(n*offset)
		
		
func spawnModule(n) -> void:
	if initObs > 10 :
		rng.randomize()
		var num = rng.randi_range(1, modules.size()-1)
		var instance = modules[num].instantiate()
		instance.position.z = n
		add_child(instance)
		if !started:
			started = true
		initObs = randf_range(5, 8)
		
	else: 
		var instance = modules[0].instantiate()
		instance.position.z = n
		add_child(instance)
		initObs += 1
