extends Control

signal request_new_balls


func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_visibility()


func _on_Quit_pressed():
	get_tree().quit()


func _on_Back_pressed():
	toggle_visibility()


func toggle_visibility():
	visible = !visible
	get_tree().paused = visible


func _on_New_pressed():
	emit_signal("request_new_balls")
	toggle_visibility()
