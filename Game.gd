extends Node2D

const TILE_SIZE = 32

onready var level = preload("res://Level/Level.tscn").instance()
onready var player = preload("res://Player/Player.tscn").instance()

func _ready():
    OS.set_window_size(Vector2(1280, 720))
    level.init(Vector2(30, 30), 5, 5, 8)
    player.init(100)
    add_child(level)
    add_child(player)

    # Add player and place in level
    var start_coord = level.get_start_coord()
    player.set_tile_coord(start_coord) 
    player.position = player.tile_coord * TILE_SIZE  # TODO: put in update visuals

