extends CharacterBody2D

@onready var nav: NavigationAgent2D = $NavigationAgent2D

var Speed = 100
var Health = 20
#var Enemy = preload("res://Scenes/Misc/enemy_2.tscn")
var OrbitSpeed = 50
var OrbitDirection
var BulletSpeed = 800
var Target = "Player"
var WeaponScene = preload("res://Prefabs/Weapons/EnemyWeapons/SpewlingWeapon.tscn") 
var CurrentWeapon: Weapon = null

func _ready():
	add_to_group("Enemy")
	OrbitDirection = [-1, 1].pick_random()
	
	var orbittimer = Timer.new()
	orbittimer.wait_time = randf_range(3, 6)  # Change direction every 3-6 seconds
	orbittimer.one_shot = false
	orbittimer.connect("timeout", Callable(self, "orbit_direction_change")) # Executes the spawn function once timer has ended
	orbittimer.autostart = true
	add_child(orbittimer)
	
	CurrentWeapon = WeaponScene.instantiate() # Create new weapon instance
	CurrentWeapon.owning_entity = "Enemy" # Set the owning entity, used to set collisions for projectile
	add_child(CurrentWeapon) # Add our new weapon as a child
	
	var firetimer = Timer.new()
	firetimer.wait_time = randf_range(2, 3)  # Fire every 2-3 seconds
	firetimer.one_shot = false
	firetimer.connect("timeout", Callable(self, "fire")) # Executes the spawn function once timer has ended
	firetimer.autostart = true
	add_child(firetimer)
	
func _process(delta):
	if Health <= 0:
		for i in range(1):
			drop_xp()
	
		Global.spawn_blood_splatter(global_position)
		Global.spawn_death_particles(global_position) 
		queue_free()
	
func orbit_direction_change():
	OrbitDirection *= -1
	print("ORBIT DIRECTION CHANGE")
	
func _physics_process(_delta):
	var Player
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
	
	nav.target_position = Player.position
	var Direction = nav.get_next_path_position() - global_position
	Direction = Direction.normalized()
	
	if position.distance_to(Player.position) >= 150:
		velocity = Direction * Speed
	else:
		var Angle = (position - Player.position).angle() + OrbitSpeed * OrbitDirection * _delta
		var OrbitRadius = 300  # Keep distance from player
		var OrbitPosition = Player.position + Vector2(OrbitRadius, 0).rotated(Angle)
		
		velocity = (OrbitPosition - position).normalized() * Speed
	
	#look_at(Player.position)
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)

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
	
	if CurrentWeapon:
		var direction_to_player = (Player.global_position - global_position).normalized() # Get direction to player
		CurrentWeapon.attempt_to_fire(global_position, direction_to_player) # Call weapons attempt to fire method

func drop_xp():
	var xp_drop_chance := 0.25  # 25% chance to drop XP
	var xp_drop_range := Vector2i(1, 1)  # Drop between 1 and 1 XP pickups
	# Check if XP should drop at all, we might not want all enemies to drop it
	if randf() > xp_drop_chance:
		return

	# Determine how many XP pickups to drop, using above var's
	var xp_amount = randi_range(xp_drop_range.x, xp_drop_range.y)
	var screen_size = get_viewport_rect().size

	for i in xp_amount:
		var position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)

		var xp_pickup = PickupFactory.build_pickup("Xp", position)
		get_parent().add_child(xp_pickup)

func deal_damage(damage, from_position = null):
	Health -= damage

func _on_area_2d_body_entered(body: Node2D):
	if is_in_group("Enemy") and body.is_in_group("Player"):
		body.deal_damage(10)
		# Calculate bounce direction (opposite of movement)
		var Direction = (position - body.position).normalized()
		var bounce_target = global_position + (Direction * Speed * 0.3)  # Move back slightly
		
		# Use Tween for smooth movement
		var Inbe_tween = get_tree().create_tween()
		Inbe_tween.tween_property(self, "global_position", bounce_target, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		await Inbe_tween.finished  # Wait for the tween to finish
		return
		
	if is_in_group("Enemy") and (body.is_in_group("Bullet") or body.is_in_group("Minion")):
		body.queue_free()
		deal_damage(10)
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
