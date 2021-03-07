extends KinematicBody2D

# Variables set by init
var hp: int = 100

# Containers
var tile_coord: Vector2

# Node references
onready var player = $Player

func _ready():
    pass

func init(hp):
    self.hp = hp

func set_tile_coord(coord: Vector2):
    tile_coord = coord


