extends Node

# Scripts for each pickup type
var xp_script = preload("res://Assets/Scripts/Pickups/xp.gd")
var health_script = preload("res://Assets/Scripts/Pickups/health.gd")

# The base pickup scene
var pickup_scene = preload("res://Scenes/Pickups/pickup.tscn")

func build_pickup(type: String, position: Vector2) -> Node:
	var pickup = pickup_scene.instantiate()
	pickup.global_position = position
	
	match type:
		"Xp":
			pickup.set_script(xp_script)
		"Health":
			pickup.set_script(health_script)
			
	return pickup
	
func try_chance_pickup(position: Vector2):
	var types = ["Health"]
	var roll = randf()
	if roll >= 0.90:
		var type = types[randi() % types.size()]
		return build_pickup(type, position)
