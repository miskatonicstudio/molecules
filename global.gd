extends Node

signal main_ball_resized (radius)


func main_ball_resized(radius):
	emit_signal("main_ball_resized", radius)
