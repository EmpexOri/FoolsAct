extends Node

@onready var ScrollBox: ScrollContainer = $"../PausedLayer/ScrollContainer"
@onready var ResumeButton: Button = $"../PausedLayer/ResumeButton"
@onready var ControlsButton: Button = $"../PausedLayer/ControlsButton"
@onready var QuitButton: Button = $"../PausedLayer/QuitButton"
@onready var BackButton: Button = $"../PausedLayer/BackButton"
@onready var Title: Label = $"../PausedLayer/Title"
@onready var Title2: Label = $"../PausedLayer/Title2"

func _on_resume_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	if get_tree().paused:
		get_tree().paused = false


func _on_controls_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing the options menu and displaying controls menu
	ResumeButton.visible = false
	ControlsButton.visible = false
	QuitButton.visible = false
	Title.visible = false
	Title2.visible = true
	ScrollBox.visible = true
	BackButton.visible = true


func _on_quit_button_pressed() -> void:
	# Play sound on button press and a timer so sound plays before game quits
	GlobalAudioController.ClickSound()
	var quitTimer = 0.15
	await get_tree().create_timer(quitTimer).timeout
	get_tree().quit()


func _on_back_button_pressed() -> void:
	# Play sound on button press
	GlobalAudioController.ClickSound()
	
	# Removing the controls menu and bringing up options menu
	ResumeButton.visible = true
	ControlsButton.visible = true
	QuitButton.visible = true
	Title.visible = true
	Title2.visible = false
	ScrollBox.visible = false
	BackButton.visible = false
