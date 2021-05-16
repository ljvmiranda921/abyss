extends Node2D


func _ready():
    OS.set_window_size(Vector2(960, 540))
    BackgroundMusic.stop_all()    
    BackgroundMusic.play(preload("res://music/start.ogg"))

func _input(event):
    if event is InputEventKey:
        if event.pressed:
            get_tree().change_scene("res://StartScreen.tscn")


