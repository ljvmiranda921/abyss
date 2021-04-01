extends Node2D

# Constants
const TILE_SIZE = 32
const LEVEL_SIZES = [
    Vector2(30, 30), 
    Vector2(35, 35),
    Vector2(40, 40)
]

# Game state containers
var starting_level: int = 0
var starting_hp: int = 100

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door }

# Scene instances
onready var level = preload("res://Level/Forest.tscn").instance()
onready var player = preload("res://Player/Player.tscn").instance()
onready var hud = preload("res://HUD.tscn").instance()

func _ready():
    OS.set_window_size(Vector2(1280, 720))

    # Add the scenes so that they appear in
    # the Game tree
    add_child(hud)
    add_child(level)
    add_child(player)

    # Start game at Level 0
    start_game(starting_level)

    # Connect to signals emitted by other
    # scenes in the game
    hud.connect("restart_game", self, "recv_restart_game")



func start_game(lvl):

    level.init(LEVEL_SIZES[lvl], 5, 5, 8)
    player.init(starting_hp)

    hud.set_level(lvl)
    hud.set_hp(player.hp)
    hud.set_dmg(player.damage)

    # Add player and place in level
    player.set_tile_coord(level.get_start_coord()) 
    call_deferred("update_visuals")

    # Add enemies and place in level
    level.add_enemies(self, lvl, 10)


func _input(event):
    if !event.is_pressed():
        return

    if event.is_action("Left"):
        handle_directional_input(-1, 0)
        player.get_node("AnimatedSprite").set_flip_h(true)
        player.get_node("SlashEffect").set_flip_h(true)
    elif event.is_action("Right"):
        handle_directional_input(1, 0)
        player.get_node("AnimatedSprite").set_flip_h(false)
        player.get_node("SlashEffect").set_flip_h(false)
    elif event.is_action("Up"):
        handle_directional_input(0, -1)
    elif event.is_action("Down"):
        handle_directional_input(0, 1)



func handle_directional_input(dx, dy):
    # Player turn 
    var dest_x = player.tile_coord.x + dx
    var dest_y = player.tile_coord.y + dy
    var tile_type = level.get_tile_type(dest_x, dest_y)
    match tile_type:
        Tile.Ground:
            var blocked = false
            for enemy in level.enemies:
                if enemy.tile_coord.x == dest_x && enemy.tile_coord.y == dest_y:
                    var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
                    combat_player_turn(player, enemy, pos_offset)
                    blocked = true
                    break
            if !blocked:
                player.move(dest_x, dest_y)
        Tile.Door:
            level.set_tile(dest_x, dest_y, Tile.Ground)

    # Enemy turn
    for enemy in level.enemies:
        enemy.act(level, player)

    call_deferred("update_visuals")

func combat_player_turn(player, enemy, anim_offset):
    player.attack(enemy, anim_offset)
    if enemy.dead:
        enemy.remove()
        level.enemies.erase(enemy)


func update_visuals():
    if player.dead:
        hud.lose.visible = true

    player.position = player.tile_coord * TILE_SIZE
    yield(get_tree(), "idle_frame")

    var space_state = get_world_2d().direct_space_state
    level.update_visibility_map(player.tile_coord, TILE_SIZE, space_state)
    level.update_enemy_positions(player.tile_coord, TILE_SIZE, space_state)

    # Update HUD
    hud.set_hp(player.hp)
    hud.set_dmg(player.damage)


func recv_restart_game():
    start_game(starting_level)
    hud.lose.visible = false
