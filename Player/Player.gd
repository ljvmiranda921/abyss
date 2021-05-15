extends KinematicBody2D

# Variables set by init
var hp: int = 100
var total_hp: int = 100
var damage: int = 30
var dead: bool = false
var ladder_found: bool = false

# Containers
var tile_coord: Vector2

onready var sprite_anim = $AnimatedSprite
onready var sfx_player = $SFXPlayer

func _ready():
    pass

func init(current_hp, total_hp, damage=30, ladder_found=false):
    self.hp = current_hp
    self.total_hp = total_hp
    self.damage = damage
    self.dead = false
    self.ladder_found = ladder_found

func set_tile_coord(coord: Vector2):
    tile_coord = coord

func move(dest_x, dest_y):
    sfx_player.get_node("Move").play()
    tile_coord = Vector2(dest_x, dest_y)


func attack(enemy, anim_offset, level):
    sfx_player.get_node("Attack").play()
    # Update animation
    _animate_attack(sprite_anim, anim_offset)

    # Apply actual damage to enemy
    enemy.take_damage(damage, level, tile_coord)


func pickup(item):
    # Call effect
    item.use_effect(self)
    # Remove
    item.remove()


func destroy(x, y, drop_chance, anim_offset, game):
    _animate_attack(sprite_anim, anim_offset, false)
    var probs = rand_range(0, 1)
    if probs > (1 - drop_chance):
        ItemFactory.drop_item(game, x, y)

func _animate_attack(player, offset, slash_effect = true):
    player.play("attack")
    player.set_offset(offset)
    self.z_index = 100
    if slash_effect:
        $SlashEffect.play("default")
        $SlashEffect.set_frame(0)
        $SlashEffect.set_offset(offset * 1.824)
    $Camera2D.small_shake()


func take_damage(dmg):
    # Update animation
    if sprite_anim.animation == "walk": 
        # Only play damage when you're not attacking
        # If you're attacking just combat anim
        sprite_anim.play("take_damage")
        $Camera2D.small_shake()

    # Resolve damage encounter
    hp = max(0, hp - dmg)
    if hp == 0:
        dead = true


func _on_AnimatedSprite_animation_finished():
    if $AnimatedSprite.animation != "walk":
        $AnimatedSprite.play("walk")
        $AnimatedSprite.set_offset(Vector2(0,0))
        self.z_index = 0
