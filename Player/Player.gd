extends KinematicBody2D

# Variables set by init
var hp: int = 100

# Containers
var tile_coord: Vector2

func _ready():
    pass

func init(hp):
    self.hp = hp

func set_tile_coord(coord: Vector2):
    tile_coord = coord

func move(dest_x, dest_y):
    tile_coord = Vector2(dest_x, dest_y)
