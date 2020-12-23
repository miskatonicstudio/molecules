extends Node

var main_ball = null

signal main_ball_resized


func main_ball_resized():
	emit_signal("main_ball_resized")
