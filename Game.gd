extends Node2D

const TILE_SIZE = 32

onready var level = preload("res://Level/Level.tscn").instance()

func _ready():
    OS.set_window_size(Vector2(1280, 720))
    level.init(Vector2(30, 30), 5, 5, 8)
    add_child(level)
