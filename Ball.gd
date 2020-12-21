tool
extends RigidBody2D

export (float) var radius = 30.0 setget set_radius
export (bool) var is_main_ball = false

onready var shape = $Shape
onready var area_node = $Area
onready var area_shape = $Area/Shape
onready var sprite = $Sprite

const MINIMAL_MAIN_BALL_RADIUS = 5
const PROPELLING_AREA = 0.001
const PROPELLING_FORCE = 100000
const PROPELLING_DAMP = 0.02
const MIN_PROPELLING = 0.01

const COLOR_VECTOR_MIN = Vector3(1, 0.25, 0)
const COLOR_VECTOR_MAX = Vector3(0, 0.75, 1)

var ball_scene = load("res://Ball.tscn")
var is_propelling = false


func _ready():
	shape.shape = CircleShape2D.new()
	area_shape.shape = CircleShape2D.new()
	set_radius(radius)
	if is_main_ball:
		global.main_ball = self
	else:
		global.connect("main_ball_resized", self, "adjust_color")
		if global.main_ball:
			adjust_color()


func _input(_event):
	if is_main_ball:
		self.is_propelling = Input.is_action_pressed("propel")


func adjust_color():
	var c = self.radius / (global.main_ball.radius * 2)
	c = clamp(c, 0, 1)
	var color_vector = COLOR_VECTOR_MIN * c + COLOR_VECTOR_MAX * (1 - c)
	modulate = Color(color_vector.x, color_vector.y, color_vector.z)


func set_radius(value):
	radius = value
	if is_inside_tree():
		shape.shape.radius = value
		area_shape.shape.radius = value
		# TODO: improve graphics or extract to a constant
		sprite.scale = Vector2(value * 2 / 2000, value * 2 / 2000)
	if is_main_ball:
		# TODO: improve resized signal
		global.main_ball_resized()


func absorbs(another_ball):
	# TODO: improve or simplify this
#	return radius <= self.radius
	var absorb = self.radius > another_ball.radius
	if self.radius == another_ball.radius:
		absorb = self.get_rid().get_id() > another_ball.get_rid().get_id()
	return absorb


func _area_to_radius(a: float) -> float:
	assert(a >= 0)
	return sqrt(a/PI)


func _radius_to_area(r: float) -> float:
	assert(r >= 0)
	return PI * pow(r, 2)


func add_area(area: float, area_linear_velocity: Vector2) -> void:
	assert(area >= 0)
	var current_area = _radius_to_area(self.radius)
	var new_area = current_area + area
	var new_velocity = (
		self.linear_velocity * current_area / new_area +
		area_linear_velocity * area / new_area
	)
	var new_radius = _area_to_radius(new_area)
	self.radius = new_radius
	self.linear_velocity = new_velocity


func _process(delta):
	if is_propelling:
		propel(
			get_viewport().get_mouse_position() - self.position,
			delta
		)
	if self.linear_damp > 0:
		self.linear_damp = max(0, self.linear_damp - delta)
	
	if (radius <= MINIMAL_MAIN_BALL_RADIUS and is_main_ball) or radius < 0:
		queue_free()


func _physics_process(delta):
	var overlapping_balls = []
	for a in area_node.get_overlapping_areas():
		overlapping_balls.append(a.get_parent())
	
	for ball in overlapping_balls:
		if ball.radius <= 0:
			continue
		var distance = self.position.distance_to(ball.position)
		var radius_difference = self.radius + ball.radius - distance
		if radius_difference <= 0:
			continue
		radius_difference *= 0.5
		
		var small = null
		var large = null
		
		if absorbs(ball):
			large = self
			small = ball
		else:
			large = ball
			small = self
		
		var small_area = _radius_to_area(small.radius)
		
		var small_radius_reduced = max(0, small.radius - radius_difference)
		
		var small_area_reduced = _radius_to_area(small_radius_reduced)
		var area_delta = small_area - small_area_reduced
		
		small.radius = small_radius_reduced
		large.add_area(area_delta, small.linear_velocity)
		
		if self.radius <= 0:
			return

func propel(direction: Vector2, delta: float = 1) -> void:
	direction = direction.normalized()
	var current_area = _radius_to_area(self.radius)
	var propelling_area = current_area * PROPELLING_AREA
	var new_area = current_area - propelling_area
	
	var propelling_ball = ball_scene.instance()
	propelling_ball.linear_damp = PROPELLING_DAMP
	propelling_ball.radius = _area_to_radius(propelling_area)
	propelling_ball.position = self.position + direction * (
		self.radius + propelling_ball.radius
	)
	self.radius = _area_to_radius(new_area)
	
	get_parent().call_deferred("add_child_below_node", self, propelling_ball)# (self, propelling_ball)
	
	propelling_ball.apply_central_impulse(
		direction * PROPELLING_FORCE * delta / propelling_area
	)
	self.apply_central_impulse(
		-direction * PROPELLING_FORCE * delta / new_area
	)
