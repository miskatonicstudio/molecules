extends RigidBody2D

export (float) var radius = 30.0 setget set_radius
export (bool) var is_main_ball = false

onready var shape = $Shape
onready var area_node = $Area
onready var area_shape = $Area/Shape
onready var sprite = $Sprite

const MIN_PROPELLING_AREA = 0.0004
const MAX_PROPELLING_AREA = 0.0008
const SMALL_PROPELLING_FORCE = 150
const LARGE_PROPELLING_FORCE = 3
const COLOR_VECTOR_MIN = Vector3(1, 0.25, 0)
const COLOR_VECTOR_MAX = Vector3(0, 0.75, 1)

var area
var ball_scene = load("res://Ball.tscn")
var is_propelling = false


func _ready():
	shape.shape = CircleShape2D.new()
	area_shape.shape = CircleShape2D.new()
	if is_main_ball:
		global.main_ball = self
		set_radius(radius)
	else:
		global.connect("main_ball_resized", self, "adjust_color")
		set_radius(radius)
		adjust_color()


func _input(_event):
	if is_main_ball:
		self.is_propelling = Input.is_action_pressed("propel")


func adjust_color():
	var c = 1
	if global.main_ball and global.main_ball.radius > 0:
		c = self.radius / (global.main_ball.radius * 2)
		c = clamp(c, 0, 1)
	var color_vector = COLOR_VECTOR_MIN * c + COLOR_VECTOR_MAX * (1 - c)
	modulate = Color(color_vector.x, color_vector.y, color_vector.z)


func set_radius(value):
	radius = value
	area = _radius_to_area(value)
	if is_inside_tree():
		shape.shape.radius = value
		area_shape.shape.radius = value
		# TODO: improve graphics or extract to a constant
		var scale = value * 2 / 2000
		sprite.scale = Vector2(scale, scale)
		
		if is_main_ball:
			# TODO: improve resized signal
			global.main_ball_resized()
	
	if radius <= 0:
		queue_free()
		if is_main_ball:
			global.main_ball = null


func _area_to_radius(a: float) -> float:
	assert(a >= 0)
	return sqrt(a/PI)


func _radius_to_area(r: float) -> float:
	assert(r >= 0)
	return PI * pow(r, 2)


func add_area(added_area: float, area_linear_velocity: Vector2) -> void:
	if added_area <= 0:
		return
	var new_area = self.area + added_area
	var new_velocity = (
		self.linear_velocity * self.area / new_area +
		area_linear_velocity * added_area / new_area
	)
	var new_radius = _area_to_radius(new_area)
	self.radius = new_radius
	self.linear_velocity = new_velocity


func _physics_process(_delta):
	# TODO: fix performance during long clicks
	if is_propelling:
		self.propel(get_viewport().get_mouse_position() - self.position)


func _process(_delta):
	var overlapping_balls = []
	for a in area_node.get_overlapping_areas():
		var ball = a.get_parent()
		if ball.radius < self.radius and ball.radius >= 0:
			overlapping_balls.append(ball)
	
	for small in overlapping_balls:
		var distance = self.position.distance_to(small.position)
		var radius_difference = self.radius + small.radius - distance
		# TODO: this should not happen, but it happens sometimes
		if radius_difference < 0:
			continue
		
		var small_radius_reduced = max(
			0, small.radius - radius_difference
		)
		
		var small_area_reduced = _radius_to_area(small_radius_reduced)
		var area_delta = small.area - small_area_reduced
		
		small.radius = small_radius_reduced
		self.add_area(area_delta, small.linear_velocity)


func propel(direction: Vector2) -> void:
	if self.radius <= 0:
		return
	
	direction = direction.normalized()
	var propelling_area = self.area * rand_range(
		MIN_PROPELLING_AREA, MAX_PROPELLING_AREA
	)
	var new_area = self.area - propelling_area
	
	self.radius = _area_to_radius(new_area)
	
	var propelling_ball = ball_scene.instance()
	propelling_ball.radius = _area_to_radius(propelling_area)
	propelling_ball.position = self.position + direction * (
		self.radius + propelling_ball.radius + 5
	)
	
	propelling_ball.apply_central_impulse(
		direction * SMALL_PROPELLING_FORCE
	)
	self.apply_central_impulse(
		-direction * LARGE_PROPELLING_FORCE
	)
	get_parent().call_deferred(
		"add_child_below_node", self, propelling_ball
	)
