extends KinematicBody2D

# Variables set by init
var hp: int = 100

# Containers
var tile_coord: Vector2

onready var sprite_anim = $AnimatedSprite

func _ready():
    pass

func init(hp):
    self.hp = hp

func set_tile_coord(coord: Vector2):
    tile_coord = coord

func move(dest_x, dest_y):
    tile_coord = Vector2(dest_x, dest_y)


func attack(offset):
    sprite_anim.play("attack")
    sprite_anim.set_offset(offset)
    self.z_index = 100


func _on_AnimatedSprite_animation_finished():
    if $AnimatedSprite.animation != "walk":
        $AnimatedSprite.play("walk")
        $AnimatedSprite.set_offset(Vector2(0,0))
        self.z_index = 0
