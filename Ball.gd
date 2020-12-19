tool
extends RigidBody2D

export (float) var radius = 30.0 setget set_radius
export (bool) var is_main_ball = false

onready var shape = $Shape
onready var area_node = $Area
onready var area_shape = $Area/Shape
onready var sprite = $Sprite

const MINIMAL_RADIUS = 5
var ball_scene = load("res://Ball.tscn")


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
	if Input.is_action_just_pressed("propel") and is_main_ball:
		var mouse_pos = get_viewport().get_mouse_position()
		propel(mouse_pos - position)


func adjust_color():
	if absorbs(global.main_ball):
		modulate = Color("#ff816a")
	else:
		modulate = Color("#acfff7")


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


func _process(_delta):
	if self.radius <= MINIMAL_RADIUS:
		queue_free()


func _physics_process(_delta):
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
		
		var small_radius = small.radius
		
		var small_area = _radius_to_area(small.radius)
		
		var small_radius_reduced = small.radius - radius_difference
		if small_radius_reduced < MINIMAL_RADIUS:
			small_radius_reduced = 0
		
		var small_area_reduced = _radius_to_area(small_radius_reduced)
		var area_delta = small_area - small_area_reduced
		
		small.radius = small_radius_reduced
		large.add_area(area_delta, small.linear_velocity)
		
		if self.radius <= 0:
			return

func propel(direction: Vector2):
	direction = direction.normalized()
	var new_ball = ball_scene.instance()
	var new_area = _radius_to_area(self.radius) * 0.05
	new_ball.radius = _area_to_radius(new_area)
	new_ball.position = self.position + direction * (
		self.radius + new_ball.radius
	)
	self.radius = _area_to_radius(_radius_to_area(self.radius) * 0.95)
	get_parent().add_child_below_node(self, new_ball)
	new_ball.apply_central_impulse(direction * 50)
	self.apply_central_impulse(-direction * 50)
