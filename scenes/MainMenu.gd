extends Control

signal request_new_level
signal request_music

var music_enabled = true


func _input(_event):
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
	emit_signal("request_new_level")
	toggle_visibility()


func _on_Music_pressed():
	music_enabled = not music_enabled
	var text = "Music: On" if music_enabled else "Music: Off"
	$CenterContainer/VBoxContainer/Music.text = text
	emit_signal("request_music", music_enabled)
