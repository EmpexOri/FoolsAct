extends Node2D

func _ready():
	$LevelSelect/Level1Button.grab_focus()

# Level Select screen variables
@onready var Level1Button = $LevelSelect/Level1Button
@onready var Level2Button = $LevelSelect/Level2Button

# Class Select screen variables
@onready var CommandoButton = $ClassSelect/CommandoButton
@onready var TechnomancerButton = $ClassSelect/TechnomancerButton
@onready var CommandoImage = $ClassSelect/Commando
@onready var TechnomancerImage = $ClassSelect/Technomancer


func _on_back_button_pressed() -> void:
	# Go to menu when back button is pressed
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
	
	$BackButton.focus_neighbor_top = $LevelSelect/Level1Button.get_path()
	$BackButton.focus_neighbor_left = $LevelSelect/Level1Button.get_path()
	$BackButton.focus_neighbor_right = $LevelSelect/Level2Button.get_path()


func _on_level_1_button_pressed() -> void:
	# Go to level one when level one button is pressed
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/PlaygroundScene.tscn")


func _on_class_select_button_pressed() -> void:
	# Remove the level select screen and display the class select screen 
	Level1Button.visible = false
	Level2Button.visible = false
	CommandoButton.visible = true
	TechnomancerButton.visible = true
	CommandoImage.visible = true
	TechnomancerImage.visible = true
	
	CommandoButton.grab_focus()
	$BackButton.focus_neighbor_top = $ClassSelect/CommandoButton.get_path()
	$BackButton.focus_neighbor_left = $ClassSelect/CommandoButton.get_path()
	$BackButton.focus_neighbor_right = $ClassSelect/TechnomancerButton.get_path()


func _on_level_select_button_pressed() -> void:
	# Remove the class select screen and display the level select screen 
	Level1Button.visible = true
	Level2Button.visible = true
	CommandoButton.visible = false
	TechnomancerButton.visible = false
	CommandoImage.visible = false
	TechnomancerImage.visible = false
	
	Level1Button.grab_focus()


func _on_commando_button_pressed() -> void:
	# Changes class to Commando
	GlobalPlayer.CurrentClass = "Commando"

	# Changes class to Technomancer
func _on_technomancer_button_pressed() -> void:
	GlobalPlayer.CurrentClass = "Technomancer"
