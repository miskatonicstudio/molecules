tool
extends RigidBody2D

export (float) var radius = 30.0 setget set_radius

onready var shape = $Shape
onready var area_shape = $Area/Shape
onready var sprite = $Sprite

var colliding_balls = []
const THRESHOLD = 10


func _ready():
	shape.shape = CircleShape2D.new()
	area_shape.shape = CircleShape2D.new()
	set_radius(radius)
	if name == "MainBall":
		add_to_group("main_ball")
	else:
		global.connect("main_ball_resized", self, "_on_main_ball_resized")
	_on_main_ball_resized(0)


func _on_main_ball_resized(new_radius):
	if name == "MainBall":
		return
	var main_ball = get_tree().get_nodes_in_group("main_ball")[0]
	if will_absorb(main_ball):
		modulate = Color("#ff816a")
	else:
		modulate = Color("#acfff7")


func set_radius(value):
#	print("set radius ", value)
	radius = value
	if is_inside_tree():
		shape.shape.radius = value
		area_shape.shape.radius = value
		sprite.scale = Vector2(value * 2 / 2000, value * 2 / 2000)
		
#		self.mass = PI * pow(value, 2)
		if name == "MainBall":
			global.main_ball_resized(radius)


func _process(_delta):
	for ball in colliding_balls:
#		print(name, " BALL NAMe ", ball.name)
		var absorb = will_absorb(ball)
		
#		print(self, " ABSORB ", absorb)
		var distance = self.position.distance_to(ball.position)
		var d = self.radius + ball.radius - distance
		
		var r = null
		var R = null
		if absorb:
			r = ball.radius
			R = self.radius
		else:
			r = self.radius
			R = ball.radius
		
		if d > r + THRESHOLD:
			d = r
		
		var delta_a = PI * d * (2 * r - d)
		
#		var new_a = PI * pow(r, 2) - (delta * 1000)
#		var new_r = sqrt(new_a/PI)
#		var new_A = PI * pow(R, 2) + (delta * 1000)
		var new_A = PI * pow(R, 2) + delta_a
		var new_R = sqrt(new_A/PI)
		
		if absorb:
			set_deferred("radius", new_R)
			print(self.linear_velocity)
#			self.linear_velocity *= 1 + self.linear_velocity.dot(ball.linear_velocity)
		else:
			if r - d <= 0:
				print("remove")
				call_deferred("remove_from_tree")
				return
#			set_deferred("radius", new_r)
			set_deferred("radius", r - d)


func remove_from_tree():
	self.queue_free()


func _on_Area_area_entered(area):
	var ball = area.get_parent()
	colliding_balls.append(ball)
	print("AREA ENTERED ", area, " ", area.get_rid().get_id(), " ", ball.radius)


func _on_Area_area_exited(area):
	var ball = area.get_parent()
	var index = colliding_balls.find(ball)
	if index >= 0:
		colliding_balls.remove(index)


func will_absorb(another_ball):
	var absorb = self.radius > another_ball.radius
	if self.radius == another_ball.radius:
		absorb = self.get_rid().get_id() > another_ball.get_rid().get_id()
	return absorb


func propel(direction: Vector2):
	direction = direction.normalized()
	var new_ball = load("res://Ball.tscn").instance()
	new_ball.radius = 5
	new_ball.position = self.position + direction * (self.radius + new_ball.radius)
	get_parent().add_child_below_node(self, new_ball)
	new_ball.apply_central_impulse(direction * 50)
	self.apply_central_impulse(-direction * 50)
