extends Node2D

onready var molecules = $Molecules
onready var main_menu = $MainMenu
onready var message_label = $Message/Label
onready var music = $Music

var molecule_scene = load("res://scenes/Molecule.tscn")
var screen_size = Vector2(
	ProjectSettings.get("display/window/size/width"),
	ProjectSettings.get("display/window/size/height")
)
var total_molecule_mass = 0


func _ready():
	# Pause the game for tutorial
	get_tree().paused = true
	randomize()
	main_menu.connect("request_new_level", self, "generate_molecules")
	main_menu.connect("request_music", self, "_on_request_music")
	global.connect("main_molecule_resized", self, "_on_main_molecule_resized")
	
	for molecule in molecules.get_children():
		total_molecule_mass += molecule.molecule_mass
	# In tutorial, ensure that the biggest molecule has to be absorbed too
	total_molecule_mass *= 1.5


func _input(_event):
	# Unpause the game in tutorial
	if len(message_label.text) > 20:
		if (
			Input.is_action_just_pressed("propel") or 
			Input.is_action_just_pressed("ui_cancel")
		):
			message_label.text = ""
			get_tree().paused = false


func generate_molecules():
	total_molecule_mass = 0
	message_label.text = ""
	
	for molecule in molecules.get_children():
		molecules.remove_child(molecule)
		molecule.queue_free()
	
	var main_molecule = molecule_scene.instance()
	main_molecule.is_main = true
	main_molecule.position = screen_size * 0.5
	
	var placeholder_molecules = _generate_placeholder_molecules(main_molecule)
	for pm in placeholder_molecules:
		var molecule = molecule_scene.instance()
		molecule.position = pm[0]
		molecules.add_child(molecule)
		molecule.radius = float(pm[1])
		total_molecule_mass += molecule.molecule_mass
	
	molecules.add_child(main_molecule)
	total_molecule_mass += main_molecule.molecule_mass


func _generate_placeholder_molecules(main_molecule):
	var generated_molecules = []
	# Add the main molecule, so it can be avoided
	generated_molecules.append([main_molecule.position, main_molecule.radius])
	
	for radius in range(72, 4, -1):
		var molecule = _generate_single_molecule(radius, generated_molecules)
		generated_molecules.append(molecule)
	
	# Remove the main molecule
	generated_molecules.pop_front()
	return generated_molecules


func _generate_single_molecule(radius, existing_molecules) -> Array:
	"""
	Generates a single molecule with the given radius, making sure
	that it doesn't overlap the existing ones. Results are returned
	as [position, radius]
	"""
	var position = null
	var found = false
	while not found:
		found = true
		var rand_x = rand_range(radius, screen_size.x - radius)
		var rand_y = rand_range(radius, screen_size.y - radius)
		position = Vector2(rand_x, rand_y)
		for molecule in existing_molecules:
			if position.distance_to(molecule[0]) <= radius + molecule[1]:
				found = false
				break
	return [position, radius]


func _on_main_molecule_resized() -> void:
	if global.main_molecule.radius <= 0:
		message_label.text = "You lost"
	else:
		if global.main_molecule.molecule_mass > total_molecule_mass * 0.5:
			message_label.text = "You won!"


func _on_request_music(enabled: bool) -> void:
	music.stream_paused = not enabled
