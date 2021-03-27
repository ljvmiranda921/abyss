extends KinematicBody2D

# Variables set by init
var hp: int = 100
var damage: int = 30
var dead: bool = false

# Containers
var tile_coord: Vector2

onready var sprite_anim = $AnimatedSprite

func _ready():
    pass

func init(hp):
    self.hp = hp
    self.damage = damage
    self.dead = false

func set_tile_coord(coord: Vector2):
    tile_coord = coord

func move(dest_x, dest_y):
    tile_coord = Vector2(dest_x, dest_y)


func attack(enemy, anim_offset):
    # Update animation
    sprite_anim.play("attack")
    sprite_anim.set_offset(anim_offset)
    self.z_index = 100

    # Apply actual damage to enemy
    enemy.take_damage(damage)


func take_damage(dmg):
    # Update animation
    if sprite_anim.animation == "walk": 
        # Only play damage when you're not attacking
        # If you're attacking just combat anim
        sprite_anim.play("take_damage")

    # Resolve damage encounter
    hp = max(0, hp - dmg)
    if hp == 0:
        dead = true


func _on_AnimatedSprite_animation_finished():
    if $AnimatedSprite.animation != "walk":
        $AnimatedSprite.play("walk")
        $AnimatedSprite.set_offset(Vector2(0,0))
        self.z_index = 0
