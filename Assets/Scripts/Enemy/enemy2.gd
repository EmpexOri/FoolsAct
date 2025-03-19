extends CharacterBody2D

var Speed = 130
#var Enemy = preload("res://Scenes/Misc/enemy_2.tscn")
var OrbitSpeed = 50
var OrbitDirection
var BulletSpeed = 600
var Bullet = preload("res://Scenes/Misc/bullet.tscn")
var xp_scene = preload("res://Scenes/Misc/xp.tscn")
var Target = "Player"

func _ready():
	add_to_group("Enemy")
	OrbitDirection = [-1, 1].pick_random()
	start_firing_timer()
	
	var timer = Timer.new()
	timer.wait_time = randf_range(3, 6)  # Change direction every 3-6 seconds
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "orbit_direction_change")) # Executes the spawn function once timer has ended
	timer.autostart = true
	add_child(timer)
	
func orbit_direction_change():
	OrbitDirection *= -1
	print("ORBIT DIRECTION CHANGE")
	
func _physics_process(_delta):
	var Player = get_parent().get_node(Target)
	if is_in_group("Enemy"):
		Player = get_parent().get_node(Target)
	elif is_in_group("Minion") and get_tree().get_nodes_in_group("Enemy").size() > 0 and is_instance_valid(Target):
		Player = get_parent().get_node(Target)
	elif is_in_group("Minion") and get_tree().get_nodes_in_group("Enemy").size() > 0 and not is_instance_valid(Target):
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			Player = get_parent().get_node(Target)
	else:
		#Player = get_parent().get_node(self.get_path())
		Player = get_parent().get_node("Player")
	
	var Direction = (Player.position - position).normalized()
	
	if position.distance_to(Player.position) >= 150:
		velocity = Direction * Speed
	else:
		var Angle = (position - Player.position).angle() + OrbitSpeed * OrbitDirection * _delta
		var OrbitRadius = 300  # Keep distance from player
		var OrbitPosition = Player.position + Vector2(OrbitRadius, 0).rotated(Angle)
		
		velocity = (OrbitPosition - position).normalized() * Speed
	
	look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

func start_firing_timer():
	var timer = Timer.new()
	timer.wait_time = randf_range(3, 5)
	timer.one_shot = true  # Timer only goes once
	timer.connect("timeout", Callable(self, "fire")) # Executes the spawn function once timer has ended
	add_child(timer)
	timer.start()

func fire():
	var Player = get_parent().get_node(Target)
	if is_in_group("Enemy"):
		Player = get_parent().get_node(Target)
	elif is_in_group("Minion") and get_tree().get_nodes_in_group("Enemy").size() > 0 and is_instance_valid(Target):
		Player = get_parent().get_node(Target)
	elif is_in_group("Minion") and get_tree().get_nodes_in_group("Enemy").size() > 0 and not is_instance_valid(Target):
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			Player = get_parent().get_node(Target)
	else:
		Player = get_parent().get_node(self.get_path())
		return
	
	var BulletInstance = Bullet.instantiate()
	BulletInstance.name = "Laser_" + str(randi())  # Assigns a unique named
	BulletInstance.get_node("Sprite2D").modulate = Color(1, 0, 0)  # Red color
	if is_in_group("Enemy"):
		BulletInstance.add_to_group("Laser")
	elif is_in_group("Minion"):
		BulletInstance.add_to_group("Bullet")
	var Direction = (Player.position - position).normalized()
	var OffsetDistance = 30
	BulletInstance.position = position + (Direction * OffsetDistance)
	BulletInstance.rotation = Direction.angle()
	BulletInstance.linear_velocity = Direction * BulletSpeed
	get_tree().get_root().call_deferred("add_child", BulletInstance)
	
	start_firing_timer()

func drop_xp():
	var xp = xp_scene.instantiate()
	xp.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
	get_parent().add_child(xp)

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		for i in range(1):
			drop_xp()
		body.queue_free()
		queue_free()
	elif body.is_in_group("Spell"):
		remove_from_group("Enemy")
		add_to_group("Minion")
		var sprite = get_node("Sprite2D")
		sprite.modulate = Color(0.8, 0.9, 1)
		if get_tree().get_nodes_in_group("Enemy").size() > 0:
			Target = get_tree().get_nodes_in_group("Enemy")[0].get_path()
			print(Target)
	elif is_in_group("Minion") and body.is_in_group("Enemy"):
		await get_tree().process_frame
		if not is_instance_valid(body) or not body.get_parent():
			call_deferred("queue_free")
