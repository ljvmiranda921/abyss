extends Node2D

# Constants
const TILE_SIZE = 32
const LEVEL_SIZES = [
    Vector2(30, 30), 
    Vector2(35, 35),
    Vector2(40, 40)
]

# Game state containers
var level_num: int = 0

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door }

# Scene instances
onready var level = preload("res://Level/Forest.tscn").instance()
onready var player = preload("res://Player/Player.tscn").instance()

func _ready():
    OS.set_window_size(Vector2(1280, 720))
    level.init(LEVEL_SIZES[level_num], 5, 5, 8)
    player.init(100)
    add_child(level)
    add_child(player)

    # Add player and place in level
    var start_coord = level.get_start_coord()
    player.set_tile_coord(start_coord) 
    call_deferred("update_visuals")

    # Add enemies and place in level
    level.add_enemies(self, level_num, 10)


func _input(event):
    if !event.is_pressed():
        return

    if event.is_action("Left"):
        handle_directional_input(-1, 0)
        player.get_node("AnimatedSprite").set_flip_h(true)
    elif event.is_action("Right"):
        handle_directional_input(1, 0)
        player.get_node("AnimatedSprite").set_flip_h(false)
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
            player.move(dest_x, dest_y)
        Tile.Door:
            level.set_tile(dest_x, dest_y, Tile.Ground)


    # Enemy turn
    for enemy in level.enemies:
        enemy.act(level, player)


    call_deferred("update_visuals")


func update_visuals():
    player.position = player.tile_coord * TILE_SIZE
    yield(get_tree(), "idle_frame")


    var space_state = get_world_2d().direct_space_state
    level.update_visibility_map(player.tile_coord, TILE_SIZE, space_state)
    level.update_enemy_positions(player.tile_coord, TILE_SIZE, space_state)

