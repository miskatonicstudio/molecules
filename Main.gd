extends Node2D

onready var main_ball = $MainBall
onready var balls = $Balls
var test_ball = null


func _ready():
	var placeholder_balls = _generate_placeholder_balls(main_ball)
	var ball_scene = load("res://Ball.tscn")
	for pb in placeholder_balls:
		var ball = ball_scene.instance()
		ball.position = pb[0]
		ball.radius = pb[1]
		balls.add_child(ball)


func _input(_event):
	if Input.is_action_just_pressed("propell") and main_ball:
		var mouse_pos = get_viewport().get_mouse_position()
		main_ball.propel(mouse_pos - main_ball.position)


func _generate_placeholder_balls(main_ball):
	randomize()
	var balls = []
	balls.append([main_ball.position, main_ball.radius])
	var screen_size = OS.window_size
	
	for i in range(40):
		var r = null
		var p = null
		var found = false
		while not found:
			found = true
			r = rand_range(10, 100)
			var rand_x = rand_range(r, screen_size.x - r)
			var rand_y = rand_range(r, screen_size.y - r)
			p = Vector2(rand_x, rand_y)
			for ball in balls:
				if p.distance_to(ball[0]) <= r + ball[1]:
					found = false
					break
		balls.append([p, r])
	# Remove the main ball
	balls.pop_front()
	return balls
