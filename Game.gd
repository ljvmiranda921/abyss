extends Node2D

# Constants
const TILE_SIZE = 32
const NUM_ENEMIES = [15, 45]

# Game state containers
var starting_level: int = 0
var starting_hp: int = 100
var object_item_drop_chance: float = 0.08
var trap_countdown
var current_level = 0

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door, MapObject, Ladder, TrapOff, TrapOn}

# Scene instances
# onready var level = preload("res://Level/Forest.tscn").instance()
var level
onready var player = preload("res://Player/Player.tscn").instance()
onready var hud = preload("res://HUD.tscn").instance()

func _ready():
    OS.set_window_size(Vector2(1280, 720))

    # Start game at Level 0
    current_level = starting_level
    start_game(starting_level)

    # Connect to signals emitted by other
    # scenes in the game
    hud.connect("restart_game", self, "recv_restart_game")



func start_game(lvl):
    # Add the scenes so that they appear in
    # the Game tree
    add_child(hud)
    # -- add level scene
    level = LevelFactory.create_level(self, lvl)
    trap_countdown = level.trap_countdown
    add_child(player)
    player.init(starting_hp)

    hud.set_level(lvl)
    hud.set_hp(player.hp)
    hud.set_dmg(player.damage)

    # Add player and place in level
    player.set_tile_coord(level.get_start_coord()) 
    call_deferred("update_visuals")

    # Add enemies and place in level
    level.add_enemies(self, lvl, NUM_ENEMIES[lvl])


func _input(event):
    if !event.is_pressed():
        return

    if event.is_action_pressed("Left"):
        handle_directional_input(-1, 0)
        player.get_node("AnimatedSprite").set_flip_h(true)
        player.get_node("SlashEffect").set_flip_h(true)
    elif event.is_action_pressed("Right"):
        handle_directional_input(1, 0)
        player.get_node("AnimatedSprite").set_flip_h(false)
        player.get_node("SlashEffect").set_flip_h(false)
    elif event.is_action_pressed("Up"):
        handle_directional_input(0, -1)
    elif event.is_action_pressed("Down"):
        handle_directional_input(0, 1)

    check_for_traps(player)


func check_for_traps(player):
    var curr_x = player.tile_coord.x
    var curr_y = player.tile_coord.y
    if level.get_tile_type(curr_x, curr_y) == Tile.TrapOn:
        player.take_damage(level.trap_damage)


func handle_directional_input(dx, dy):
    # Player turn 
    level.deactivate_traps()
    var dest_x = player.tile_coord.x + dx
    var dest_y = player.tile_coord.y + dy
    var tile_type = level.get_tile_type(dest_x, dest_y)
    match tile_type:
        Tile.Ground:
            var blocked = false
            for enemy in level.enemies:
                if enemy.tile_coord.x == dest_x && enemy.tile_coord.y == dest_y:
                    var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
                    combat_player_turn(player, enemy, pos_offset, level)
                    blocked = true
                    break
            if !blocked:
                player.move(dest_x, dest_y)
                var item = scan_for_items(dest_x, dest_y)
                if item && player.hp != starting_hp:
                    player.pickup(item)
                    level.items.erase(item)
        Tile.Door:
            level.set_tile(dest_x, dest_y, Tile.Ground)
        Tile.MapObject:
            level.set_tile(dest_x, dest_y, Tile.Ground)
            level.play_effect("poof", dest_x * TILE_SIZE, dest_y * TILE_SIZE)
            var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
            player.destroy(dest_x, dest_y, object_item_drop_chance, pos_offset, self)
        Tile.Ladder:
            print_debug("yay!")
            level.remove()
            current_level += 1
            start_game(current_level)
        Tile.TrapOff:
            var blocked = false
            for enemy in level.enemies:
                if enemy.tile_coord.x == dest_x && enemy.tile_coord.y == dest_y:
                    var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
                    combat_player_turn(player, enemy, pos_offset, level)
                    blocked = true
                    break
            if !blocked:
                player.move(dest_x, dest_y)
                var item = scan_for_items(dest_x, dest_y)
                if item && player.hp != starting_hp:
                    player.pickup(item)
                    level.items.erase(item)
        Tile.TrapOn:
            player.take_damage(level.trap_damage)
            var blocked = false
            for enemy in level.enemies:
                if enemy.tile_coord.x == dest_x && enemy.tile_coord.y == dest_y:
                    var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
                    combat_player_turn(player, enemy, pos_offset, level)
                    blocked = true
                    break
            if !blocked:
                player.move(dest_x, dest_y)
                var item = scan_for_items(dest_x, dest_y)
                if item && player.hp != starting_hp:
                    player.pickup(item)
                    level.items.erase(item)


    # Enemy turn
    for enemy in level.enemies:
        enemy.act(level, player)

    # Update trap countdown
    trap_countdown -= 1
    if trap_countdown == 0:
        level.activate_traps()
        trap_countdown = level.trap_countdown  # reset countdown

    call_deferred("update_visuals")


func scan_for_items(x, y):
    for item in level.items:
        if item.tile_coord == Vector2(x, y):
            return item

func combat_player_turn(player, enemy, anim_offset, level):
    player.attack(enemy, anim_offset, level)
    if enemy.dead:
        enemy.remove()
        level.enemies.erase(enemy)


func update_visuals():
    if player.dead:
        hud.lose.visible = true


    # player.position = player.tile_coord * TILE_SIZE
    var destination = player.tile_coord * TILE_SIZE

    # Add tweening
    var move_tween = get_node("Tween")
    move_tween.interpolate_property(player, "position", player.position, destination, 0.20, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
    for enemy in level.enemies:
        move_tween.interpolate_property(enemy.sprite_node, "position", enemy.sprite_node.position, enemy.tile_coord * TILE_SIZE, 0.20, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

    move_tween.start()

    yield(get_tree(), "idle_frame")

    var space_state = get_world_2d().direct_space_state
    level.update_visibility_map(player.tile_coord, TILE_SIZE, space_state)
    level.update_enemy_positions(player.tile_coord, TILE_SIZE, space_state)

    # Update HUD
    hud.set_hp(player.hp)
    hud.set_dmg(player.damage)


func recv_restart_game():
    level.remove()
    current_level = starting_level
    start_game(starting_level)
    hud.lose.visible = false
