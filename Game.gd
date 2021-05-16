extends Node2D

# Constants
const TILE_SIZE = 32
const NUM_ENEMIES = [15, 30, 8]

# Game state containers
var starting_level: int = 0
var starting_hp: int = 100
var starting_dmg: int = 30

var object_item_drop_chance: float = 0.2
var trap_countdown
var trap_active_time
var trap_is_active = false
var current_level = 0

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door, MapObject, Ladder, TrapOff, TrapOn}

# Scene instances
var level
onready var player = preload("res://Player/Player.tscn").instance()
onready var hud = preload("res://HUD.tscn").instance()
onready var sfx_player = $SFXPlayer

onready var tween = get_node("Tween")

func _ready():
    OS.set_window_size(Vector2(960, 540))
    # Start game at Level 0
    current_level = starting_level
    start_game(starting_level)
    # Connect to signals emitted by other
    # scenes in the game
    hud.connect("restart_game", self, "recv_restart_game")

func recv_restart_game():
    get_tree().change_scene("res://StartScreen.tscn")


func start_boss_level(current_hp, total_hp, current_dmg):
    BackgroundMusic.stop_all()
    BackgroundMusic.play(preload("res://music/boss.ogg"))
    level = LevelFactory.create_boss_level(self)
    trap_countdown = level.trap_countdown
    trap_active_time = level.trap_countdown
    player.init(current_hp, total_hp, current_dmg)

    hud.set_level(3)
    hud.set_hp(player.hp, player.total_hp)
    hud.set_dmg(player.damage)

    player.set_tile_coord(level.get_start_coord_boss_level()) 
    call_deferred("update_visuals")

    level.add_boss(self, 6, 4)

func start_game(
        lvl, 
        init=true, 
        current_hp=starting_hp, 
        total_hp=starting_hp, 
        current_dmg=starting_dmg
):

    BackgroundMusic.play_level(lvl)
    # Add the scenes so that they appear in
    # the Game tree
    if lvl == 0 && init:
        add_child(hud)
        add_child(player)

    # Generate level scene
    level = LevelFactory.create_level(self, lvl)
    trap_countdown = level.trap_countdown
    trap_active_time = level.trap_countdown
    player.init(current_hp, total_hp, current_dmg)

    hud.set_level(lvl)
    hud.set_hp(player.hp, player.total_hp)
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


func check_if_ladder_found(player):
    if player.ladder_found:
        return
    else:
        if level.ladder_exposed():
            player.sfx_player.get_node("LadderFound").play()
            player.ladder_found = true
        else:
            return


func check_for_traps(player):
    var curr_x = player.tile_coord.x
    var curr_y = player.tile_coord.y
    if level.get_tile_type(curr_x, curr_y) == Tile.TrapOn:
        player.take_damage(level.trap_damage)


func handle_directional_input(dx, dy):
    # Player turn 
    if trap_is_active:
        trap_active_time -= 1
        if trap_active_time == 0:
            level.deactivate_traps()
            trap_is_active = false
            trap_active_time = level.trap_countdown

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
                if item && item.name == "HealingPotion": 
                    if player.hp != player.total_hp:
                        player.pickup(item)
                        level.items.erase(item)
                    else:
                        pass
                if item && item.name != "HealingPotion":
                    player.pickup(item)
                    level.items.erase(item)
        Tile.Door:
            sfx_player.get_node("OpenDoor").play()
            level.set_tile(dest_x, dest_y, Tile.Ground)

        Tile.MapObject:
            sfx_player.get_node("BreakObject").play()
            level.set_tile(dest_x, dest_y, Tile.Ground)
            level.play_effect("poof", dest_x * TILE_SIZE, dest_y * TILE_SIZE)
            var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
            player.destroy(dest_x, dest_y, object_item_drop_chance, pos_offset, self)

        Tile.Ladder:
            var blocked = false
            for enemy in level.enemies:
                if enemy.tile_coord.x == dest_x && enemy.tile_coord.y == dest_y:
                    var pos_offset = Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4)
                    combat_player_turn(player, enemy, pos_offset, level)
                    blocked = true
                    break
            if !blocked:
                player.move(dest_x, dest_y)
                call_deferred("update_visuals")
                sfx_player.get_node("ClimbLadder").play()
                hud.transition_player.play("Fade")
                yield(hud.transition_player, "animation_finished")
                level.remove()
                current_level += 1
                var new_hp = min(player.total_hp, int(player.hp + (0.5 * player.total_hp)))
                if current_level == 3:  # boss level
                    start_boss_level(new_hp, player.total_hp, player.damage)
                elif current_level == 4: # End credits
                    get_tree().change_scene("res://EndScreen.tscn")
                else:
                    start_game(current_level, false, new_hp, player.total_hp, player.damage)
                hud.transition_player.play_backwards("Fade")

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
                if item && item.name == "HealingPotion": 
                    if player.hp != player.total_hp:
                        player.pickup(item)
                        level.items.erase(item)
                    else:
                        pass
                if item && item.name != "HealingPotion":
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
                if item && item.name == "HealingPotion": 
                    if player.hp != player.total_hp:
                        player.pickup(item)
                        level.items.erase(item)
                    else:
                        pass
                if item && item.name != "HealingPotion":
                    player.pickup(item)
                    level.items.erase(item)

        Tile.InnerWall:
            sfx_player.get_node("BumpWall").play()

        Tile.OuterWall:
            sfx_player.get_node("BumpWall").play()



    # Enemy turn
    for enemy in level.enemies:
        enemy.act(level, player)

    # Update trap countdown
    if !trap_is_active:
        trap_countdown -= 1
        if trap_countdown == 0:
            level.activate_traps()
            trap_is_active = true
            trap_countdown = level.trap_countdown  # reset countdown

    call_deferred("update_visuals")


func scan_for_items(x, y):
    for item in level.items:
        if item.tile_coord == Vector2(x, y):
            return item

func combat_player_turn(player, enemy, anim_offset, level):
    player.attack(enemy, anim_offset, level)
    flicker_sprite(enemy.sprite_node)
    if enemy.dead:
        enemy.remove()
        level.enemies.erase(enemy)


func update_visuals():
    if player.dead:
        BackgroundMusic.stop_all()
        BackgroundMusic.play(preload("res://music/death.wav"))
        hud.lose.visible = true

    var destination = player.tile_coord * TILE_SIZE
    if current_level != 3:
        check_if_ladder_found(player)

    # Add tweening
    # var move_tween = get_node("Tween")
    tween.interpolate_property(
            player, 
            "position", 
            player.position, 
            destination, 
            0.20, 
            Tween.TRANS_QUAD, 
            Tween.EASE_IN_OUT
    )


    for enemy in level.enemies:
        tween.interpolate_property(
            enemy.sprite_node, 
            "position", 
            enemy.sprite_node.position, 
            enemy.tile_coord * TILE_SIZE, 
            0.20, 
            Tween.TRANS_QUAD, 
            Tween.EASE_IN_OUT
    )
    tween.start()

    yield(get_tree(), "idle_frame")

    var space_state = get_world_2d().direct_space_state
    level.update_visibility_map(player.tile_coord, TILE_SIZE, space_state)
    level.update_enemy_positions(player.tile_coord, TILE_SIZE, space_state)

    # Update HUD
    hud.set_hp(player.hp, player.total_hp)
    hud.set_dmg(player.damage)


func flicker_sprite(node, speed=0.6, 
        trans_type=Tween.TRANS_BOUNCE, ease_type=Tween.EASE_OUT_IN):
    tween.interpolate_property(node, "modulate:a", 1, 0, 
            speed, trans_type, ease_type)
    tween.start()
    yield(tween, "tween_completed")
    tween.interpolate_property(node, "modulate:a", 0, 1, 
            speed, trans_type, ease_type)
    tween.start()

