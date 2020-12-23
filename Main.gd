extends Node2D

onready var balls = $Balls
onready var main_menu = $MainMenu
onready var message_label = $Message/Label

var ball_scene = load("res://Ball.tscn")
var screen_size = Vector2(
	ProjectSettings.get("display/window/size/width"),
	ProjectSettings.get("display/window/size/height")
)
# Total area of all balls
var total_ball_area = 0


func _ready():
	randomize()
	main_menu.connect("request_new_balls", self, "generate_balls")
	main_menu.connect("request_music", self, "_on_request_music")
	global.connect("main_ball_resized", self, "_on_main_ball_resized")
	
	for ball in balls.get_children():
		total_ball_area += ball.area
	# In tutorial, ensure that the biggest molecule has to be absorbed too
	total_ball_area *= 1.5


func generate_balls():
	total_ball_area = 0
	message_label.text = ""
	
	for child in balls.get_children():
		balls.remove_child(child)
		child.queue_free()
	
	var main_ball = ball_scene.instance()
	main_ball.is_main_ball = true
	main_ball.position = screen_size * 0.5
	
	var placeholder_balls = _generate_placeholder_balls(main_ball)
	for pb in placeholder_balls:
		var ball = ball_scene.instance()
		ball.position = pb[0]
		balls.add_child(ball)
		ball.radius = pb[1]
		total_ball_area += ball.area
	balls.add_child(main_ball)
	total_ball_area += main_ball.area


func _generate_placeholder_balls(main_ball):
	var generated_balls = []
	generated_balls.append([main_ball.position, main_ball.radius])
	
	for radius in range(72, 4, -1):
		var ball = _generate_single_ball(float(radius), generated_balls)
		generated_balls.append(ball)
	
	generated_balls.pop_front()
	return generated_balls


func _generate_single_ball(r, existing_balls):
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


func _on_main_ball_resized() -> void:
	if global.main_ball.radius <= 0:
		message_label.text = "You lost"
	else:
		if global.main_ball.area > total_ball_area * 0.5:
			message_label.text = "You won"


func _on_request_music(enabled: bool) -> void:
	$AudioStreamPlayer.stream_paused = not enabled
