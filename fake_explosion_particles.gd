extends Node2D

@export var min_particles_number: int = 200
@export var max_particles_number: int = 400

@export var min_particles_gravity: float = 200.0
@export var max_particles_gravity: float = 600.0

@export var min_particles_velocity: float = 200.0
@export var max_particles_velocity: float = 600.0

@export var max_particles_position_x: int = ProjectSettings.get_setting("display/window/size/viewport_width")
@export var max_particles_position_y: int = ProjectSettings.get_setting("display/window/size/viewport_height")

@export var min_particles_size: int = 1
@export var max_particles_size: int = 4

@export var get_random_position: bool = false
@export var start_timer: bool = false
@export var timer_wait_time: float = 1.0
@export var particles_explode: bool = false
@export var group_name: String = "fake_explosion_particles"

var particles = []
var particles_number
var particles_initial_position

var particles_colors_with_weights = [
	[4, Color("#ffffff")],
	[2, Color("#000000")],
	[8, Color("#ff004d")],
	[8, Color("#ffa300")],
	[10, Color("#ffec27")]
]

var particles_timer

func _ready():
	# Add to a group so it can be found from anywhere.
	add_to_group(group_name)

	# Create the initial particles.
	_create_particles()

	# Create a timer.
	particles_timer = Timer.new()
	particles_timer.one_shot = false
	particles_timer.wait_time = timer_wait_time
	particles_timer.set_timer_process_callback(1)
	particles_timer.connect("timeout", Callable(self, "_on_particles_timer_timeout"))

	add_child(particles_timer, true)

	if start_timer: particles_timer.start()


func _process(delta):
	# If there are particles in the particles array and
	# 'particles_explode' is 'true', make them explode.
	if particles.size() > 0 and particles_explode == true:

		_particles_explode(delta)

		# Redraw the particles every frame.
		queue_redraw()

	# If there are no particles in the particles array, free the node.
	if particles.size() == 0 and not start_timer:
		queue_free()


func _draw():
	for particle in particles:
		# Draw the particles.
		draw_rect(Rect2(particle.position, particle.size), particle.color)


func _particles_explode(delta):
	for particle in particles:
		particle.velocity.x *= particle.velocity_increment.x
		particle.velocity.y *= particle.velocity_increment.y
		particle.position += (particle.velocity + particle.gravity) * delta

		particle.time += delta

		if particle.time > _get_random_time():
			# Fade out the particles.
			if particle.color.a > 0:
				particle.color.a -= particle.alpha * delta
	
				if particle.color.a < 0:
					particle.color.a = 0

		# If the particle is invisible...
		if particle.color.a == 0:
			# ... if there are particles in the particles array...
			if particles.size() > 0:
				# ... find the particle in the particles array...
				var i = particles.find(particle)
				# ... and remove it from the particles array.
				particles.remove_at(i)


func _create_particles():
	# Set the node's position to (0,0) to get proper random position values.
	if get_random_position: position = Vector2.ZERO

	# Set initial values.
	particles_initial_position = _get_random_position() if get_random_position else Vector2.ZERO
	particles_number = _get_random_number()

	# Empty the particles array.
	particles.clear()

	for i in particles_number:
		# Create the particle object.
		var particle = {
			alpha = null,
			color = null,
			gravity = null,
			position = particles_initial_position,
			size = null,
			time = 0,
			velocity = null
		}

		# Assign random variables to the particle object.
		particle.alpha = _get_random_alpha()
		particle.color = _get_random_color()
		particle.gravity = _get_random_gravity()
		particle.size = _get_random_size()
		particle.velocity = _get_random_velocity()
		particle.velocity_increment = _get_random_velocity_increment()

		# Push the particle to the particles array.
		particles.push_back(particle)


func _get_random_alpha():
	randomize()
	var random_alpha = randf_range(2, 10)
	return random_alpha


func _get_random_color():
	randomize()
	var random_color = _rand_array(particles_colors_with_weights)
	return random_color


func _get_random_gravity():
	randomize()
	var random_gravity = Vector2(
							randf_range(
								-randf_range(min_particles_gravity, max_particles_gravity),
								randf_range(min_particles_gravity, max_particles_gravity)
							),
							randf_range(
								randf_range(min_particles_gravity * 2, max_particles_gravity * 2),
								randf_range(min_particles_gravity * 2, max_particles_gravity * 2)
							)
						)
	return random_gravity


func _get_random_number():
	randomize()
	var random_number = round(randf_range(min_particles_number, max_particles_number))
	return random_number


func _get_random_position():
	randomize()
	var random_position_x = randf_range(0, max_particles_position_x)
	var random_position_y = randf_range(0, max_particles_position_y)
	var random_position = Vector2(random_position_x, random_position_y)
	return random_position


func _get_random_size():
	randomize()
	var random_size = randi() % max_particles_size + min_particles_size
	random_size = Vector2(random_size, random_size)
	return random_size


func _get_random_velocity():
	randomize()
	var random_velocity = Vector2(
							randf_range(
								-randf_range(min_particles_velocity, max_particles_velocity),
								randf_range(min_particles_velocity, max_particles_velocity)
							),
							randf_range(
								-randf_range(min_particles_velocity * 2, max_particles_velocity * 2),
								-randf_range(min_particles_velocity * 2, max_particles_velocity * 2)
							)
						)
	return random_velocity


func _get_random_velocity_increment():
	randomize()
	var random_velocity_increment = Vector2(randf_range(0.991, 1.009), randf_range(0.991, 1.009))
	return random_velocity_increment


func _get_random_time():
	randomize()
	var random_time = randf_range(0.05, 0.1)
	return random_time


func _rand_array(array):
	# Code from @CowThing (https://pastebin.com/HhdBuUzT).
	# Arrays must be [weight, value].

	var sum_of_weights = 0
	for t in array:
		sum_of_weights += t[0]

	var x = randf() * sum_of_weights

	var cumulative_weight = 0
	for t in array:
		cumulative_weight += t[0]
 
		if x < cumulative_weight:
			return t[1]


func _on_particles_timer_timeout():
	# Create new particles every time the timer times out.
	_create_particles()
