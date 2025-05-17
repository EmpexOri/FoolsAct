extends Node

# Preload materials (used only for prewarm trick)
var materials = [
	preload("res://Prefabs/Particles/Preloaded/TumourExplosionGore.tres"),
	preload("res://Prefabs/Particles/Preloaded/DeathExplosionGore.tres")
]

# Preload particle scenes for instancing
var TumourParticlesScene = preload("res://Prefabs/Particles/TumourExplosionGore.tscn")
var DeathParticlesScene = preload("res://Prefabs/Particles/DeathGore.tscn")

# Pools for reusing particle nodes
var tumour_particle_pool: Array = []
var death_particle_pool: Array = []

var POOL_SIZE := 128  # Customize based on how many can be active at once

# A global variable for the particle options index
var graphics_quality_index: int = 1 

func _ready() -> void:
	# Prewarm GPU shaders by creating dummy instances briefly
	for material in materials:
		var dummy = GPUParticles2D.new()
		dummy.process_material = material
		dummy.modulate = Color(1, 1, 1, 0)
		dummy.emitting = true
		add_child(dummy)

	# Wait 3 frames before removing dummy nodes
	await get_tree().create_timer(0.05).timeout
	for child in get_children():
		if child is GPUParticles2D:
			child.queue_free()

	# Fill the pools
	_fill_pool(TumourParticlesScene, tumour_particle_pool, POOL_SIZE)
	_fill_pool(DeathParticlesScene, death_particle_pool, POOL_SIZE)

func _fill_pool(scene: PackedScene, pool: Array, count: int) -> void:
	for i in count:
		var instance = scene.instantiate()
		instance.visible = false
		add_child(instance)
		pool.append(instance)

# -- Spawning Logic --

func spawn_death_particles(position: Vector2) -> void:
	_spawn_particles(position, death_particle_pool)

func spawn_tumour_particles(position: Vector2) -> void:
	_spawn_particles(position, tumour_particle_pool)

func _spawn_particles(position: Vector2, pool: Array) -> void:
	var instance: Node2D = null

	# Try to find an invisible particle from the pool
	for p in pool:
		if not p.visible and not p.get_node("Particles").emitting:
			#print("Found free particle.")
			instance = p
			break
		else:
			#print("Checked particle — Visible:", p.visible, ", Emitting:", p.get_node("Particles").emitting)
			break

	# If no particle is available, print a warning
	if instance == null:
		print("No free particles available! Consider increasing POOL_SIZE.")
		return

	# Set position and make the particle visible
	instance.global_position = position
	instance.visible = true

	# Get the particle system and start emitting, THIS CAUSES ISSUES IF CHANGED WAAAAAAAAAAAAAAAA
	var particles = instance.get_node("Particles") as GPUParticles2D
	particles.emitting = false  # Stop it cleanly
	particles.restart()         # Reset its state
	particles.emitting = true   # Start new emission

	# Calculate the total time for the reset (use lifetime + 0.0 to ensure a float value)
	var total_time: float = particles.lifetime + 0.1

	# Reset particle after its lifetime expires
	_reset_particle_after_delay(instance, particles, total_time)

# Reset particle after its lifetime expires
func _reset_particle_after_delay(instance: Node2D, particles: GPUParticles2D, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	
	if is_instance_valid(instance):
		# Only hide after next frame to give time for `emitting` flag to stop properly
		await get_tree().process_frame
		particles.emitting = false
		instance.visible = false

func spawn_blood_splatter(position: Vector2):
	var blood_sprite = Sprite2D.new()
	blood_sprite.texture = preload("res://Assets/Art/PlaceHolders/Splat.png") 
	blood_sprite.position = position
	blood_sprite.z_index = -2
	get_tree().current_scene.add_child(blood_sprite)

func spawn_meat_chunk(position: Vector2):
	var meat_scene = preload("res://Prefabs/Particles/MeatChunks.tscn")
	var num_chunks = randi_range(8, 48)

	for i in range(num_chunks):
		var meat_chunk = meat_scene.instantiate()
		meat_chunk.global_position = position
		meat_chunk.z_index = -1
		get_tree().current_scene.call_deferred("add_child", meat_chunk)

# -- Blood Smear Tracking --

var MAX_BLOOD_SMEARS = 4000
var active_smeares := []

func register_smear(smear):
	active_smeares.append(smear)
	if active_smeares.size() > MAX_BLOOD_SMEARS:
		var oldest = active_smeares.pop_front()
		if oldest.is_inside_tree():
			oldest.queue_free()

func unregister_smear(smear):
	active_smeares.erase(smear)

#-- Settings Logic --
func apply_graphics_settings() -> void:
	# Resize particle pools
	_clear_and_refill_pool(tumour_particle_pool, TumourParticlesScene, POOL_SIZE)
	_clear_and_refill_pool(death_particle_pool, DeathParticlesScene, POOL_SIZE)
	print("Reinitialized particle pools to new POOL_SIZE:", POOL_SIZE)

func _clear_and_refill_pool(pool: Array, scene: PackedScene, size: int) -> void:
	# Remove old particles
	for p in pool:
		if is_instance_valid(p):
			p.queue_free()
	pool.clear()
	
	# Refill with new size
	_fill_pool(scene, pool, size)
