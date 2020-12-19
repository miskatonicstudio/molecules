extends Node2D

onready var balls = $Balls
onready var main_menu = $MainMenu

var ball_scene = load("res://Ball.tscn")


func _ready():
#	generate_balls()
	main_menu.connect("request_new_balls", self, "generate_balls")


func generate_balls():
	for child in balls.get_children():
		balls.remove_child(child)
		child.queue_free()
	
	var main_ball = ball_scene.instance()
	main_ball.is_main_ball = true
	main_ball.position = OS.window_size * 0.5
	balls.add_child(main_ball)
	
	var placeholder_balls = _generate_placeholder_balls(main_ball)
	for pb in placeholder_balls:
		var ball = ball_scene.instance()
		ball.position = pb[0]
		ball.radius = pb[1]
		balls.add_child(ball)


func _generate_placeholder_balls(main_ball):
	randomize()
	var generated_balls = []
	generated_balls.append([main_ball.position, main_ball.radius])
	
	for _i in range(4):
		var r = rand_range(100, 130)
		var b = _generate_single_ball(r, generated_balls)
		generated_balls.append(b)
	
	for _i in range(4):
		var r = rand_range(70, 90)
		var b = _generate_single_ball(r, generated_balls)
		generated_balls.append(b)
	
	for _i in range(10):
		var r = rand_range(30, 60)
		var b = _generate_single_ball(r, generated_balls)
		generated_balls.append(b)
	
	for _i in range(50):
		var r = rand_range(5, 20)
		var b = _generate_single_ball(r, generated_balls)
		generated_balls.append(b)
	
	generated_balls.pop_front()
	return generated_balls


func _generate_single_ball(r, existing_balls):
	var screen_size = OS.window_size
	var p = null
	var found = false
	while not found:
		found = true
		var rand_x = rand_range(r, screen_size.x - r)
		var rand_y = rand_range(r, screen_size.y - r)
		p = Vector2(rand_x, rand_y)
		for ball in existing_balls:
			if p.distance_to(ball[0]) <= r + ball[1]:
				found = false
				break
	return [p, r]
