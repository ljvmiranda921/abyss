class_name EnemyFactory

const MonkeyScene = preload("res://Enemies/ForestEnemies/EnemyMonkey.tscn")
const PlanteraScene = preload("res://Enemies/ForestEnemies/EnemyPlantera.tscn")
const BeeScene = preload("res://Enemies/ForestEnemies/EnemyBee.tscn")

const SkeletonSwordsmanScene = preload("res://Enemies/CavernEnemies/EnemySkSword.tscn")
const SkeletonRogueScene = preload("res://Enemies/CavernEnemies/EnemySkRogue.tscn")
const SkeletonDefenderScene = preload("res://Enemies/CavernEnemies/EnemySkDefender.tscn")

const NecromancerScene = preload("res://Enemies/UnderworldEnemies/EnemyNecromancer.tscn")
const FamiliarScene = preload("res://Enemies/UnderworldEnemies/EnemyFamiliar.tscn")

const BossScene = preload("res://Enemies/UnderworldEnemies/EnemyBoss.tscn")
const BossFamiliarScene = preload("res://Enemies/UnderworldEnemies/EnemyBossFamiliar.tscn")

const TILE_SIZE = 32

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door, MapObject, Ladder, TrapOff, TrapOn}

const FOREST_ENEMIES = [
    {
        "name": "WildMonkey",
        "scene": MonkeyScene,
        "spawn_probs": 0.35,
        "acc_weight": 0.0, 
        "line_of_sight": 3,
        "drop_chance": 0.6,
        "defend_turns": 0,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 75, 
        "damage": 20
    },
    {
        "name": "Plantera",
        "scene": PlanteraScene, 
        "spawn_probs": 0.3,
        "acc_weight": 0.0, 
        "line_of_sight": 2,
        "drop_chance": 0.70,
        "defend_turns": 0,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 60,
        "damage": 25
    },
    {
        "name": "BeeSoldier",
        "scene": BeeScene,
        "spawn_probs": 0.50,
        "acc_weight": 0.0, 
        "line_of_sight": 5,
        "drop_chance": 0.3,
        "defend_turns": 0,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 35,
        "damage": 10
    },
]

const CAVERN_ENEMIES = [
    {
        "name": "SkeletonSword",
        "scene": SkeletonSwordsmanScene, 
        "spawn_probs": 0.2,
        "acc_weight": 0.0, 
        "line_of_sight": 4,
        "drop_chance": 0.30,
        "defend_turns": 0,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 90,
        "damage": 18
    },
    {
        "name": "SkeletonRogue",
        "scene": SkeletonRogueScene, 
        "spawn_probs": 0.5,
        "acc_weight": 0.0, 
        "line_of_sight": 6,
        "drop_chance": 0.60,
        "defend_turns": 8,
        "summon_probs": 0,
        "can_evade": true,
        "offset_divider": 2,
        "hp": 120,
        "damage": 15
    },
    {
        "name": "SkeletonDefender",
        "scene": SkeletonDefenderScene,
        "spawn_probs": 0.3,
        "acc_weight": 0.0, 
        "line_of_sight": 4,
        "drop_chance": 0.70,
        "defend_turns": 5,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 200,
        "damage": 12
    },
]

const UDRWLD_ENEMIES = [
    {
        "name": "Necromancer",
        "scene": NecromancerScene,
        "spawn_probs": 0.3,
        "acc_weight": 0.0, 
        "line_of_sight": 4,
        "drop_chance": 1.00,
        "defend_turns": 0,
        "summon_probs": 0.45,
        "can_evade": false,
        "offset_divider": 6,
        "hp": 200,
        "damage": 5
    },
]

const ENEMY_FAMILIARS = [
    {
        "name": "SkeletonSwordFamiliar",
        "scene": SkeletonSwordsmanScene, 
        "spawn_probs": 0.3,
        "acc_weight": 0.0, 
        "line_of_sight": 4,
        "drop_chance": 0.0,
        "defend_turns": 0,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 60,
        "damage": 10
    },
    {
        "name": "Familiar",
        "scene": FamiliarScene, 
        "spawn_probs": 0.7,
        "acc_weight": 0.0, 
        "line_of_sight": 4,
        "drop_chance": 0.005,
        "defend_turns": 0,
        "summon_probs": 0,
        "can_evade": false,
        "offset_divider": 4,
        "hp": 80,
        "damage": 15
    }
]

const BOSS_ROOM = [
    {
        "name": "Boss",
        "scene":BossScene, 
        "spawn_probs": 1.00,
        "acc_weight": 0.0,
        "line_of_sight": 5,
        "drop_chance": 0.0,
        "defend_turns": 0,
        "summon_probs": 0.1,
        "summon_turns": 8, 
        "can_evade": false,
        "offset_divider": 4,
        "aggro": 0.2,
        "hp": 300,
        "damage": 20
    }
]


const BOSS_FAMILIARS = [
    {
        "name": "BossFamiliar",
        "scene":BossFamiliarScene, 
        "spawn_probs": 1.00,
        "acc_weight": 0.0,
        "line_of_sight": 4,
        "drop_chance": 0.0,
        "defend_turns": 0,
        "summon_probs": 0,
        "summon_turns": 0, 
        "can_evade": false,
        "offset_divider": 4,
        "hp": 90,
        "damage": 5
    }
]


# Only for general mobs
const ENEMY_DEFINITIONS = [
    FOREST_ENEMIES, 
    CAVERN_ENEMIES, 
    UDRWLD_ENEMIES,
    BOSS_ROOM
]


static func spawn_familiar(game, x, y, boss = false):
    var mobs
    if !boss:
        mobs = ENEMY_FAMILIARS
    else:
        mobs = BOSS_FAMILIARS

    var total_weight = init_probabilities(mobs)
    var enemy_def = pick_some_object(mobs, total_weight)
    var enemy = Enemy.new(game, enemy_def.hp, enemy_def.damage, enemy_def.scene, enemy_def, x, y, 32)
    return enemy


static func spawn_enemy(game, level_num, x, y):
    var mobs = ENEMY_DEFINITIONS[level_num]
    var total_weight = init_probabilities(mobs)
    var enemy_def = pick_some_object(mobs, total_weight)
    var enemy

    if enemy_def.name == "Boss":
        enemy = Boss.new(game, enemy_def.hp, enemy_def.damage, enemy_def.scene, enemy_def, x, y, 32)
    else:
        enemy = Enemy.new(game, enemy_def.hp, enemy_def.damage, enemy_def.scene, enemy_def, x, y, 32)

    return enemy


static func init_probabilities(basket) -> float:
    var total_weight = 0.0
    for item in basket:
        total_weight += item.spawn_probs
        item.acc_weight = total_weight
    return total_weight


static func pick_some_object(basket, total_weight) -> Dictionary:
    var roll: float = rand_range(0.0, total_weight)
    for item in basket:
        if (item.acc_weight > roll):
            return item

    return {}

class Boss extends Reference:
    var name
    var sprite_node
    var tile_coord
    var dead = false
    var line_of_sight
    var full_hp
    var current_hp
    var attack_dmg
    var drop_chance
    var game_class
    var can_summon
    var summon_probs
    var starting_summon
    var aggro = 0.2

    # Status
    var in_pursuit
    var can_evade = false
    var dmg_counter = 0
    var summon_turns = 0

    # Display
    var offset_divider = 4

    func _init(game, hp, damage, sprite_scene, enemy_config, x, y, tile_size):
        sprite_node = sprite_scene.instance()
        name = enemy_config.name
        # Setup enemy movement
        tile_coord = Vector2(x, y)
        sprite_node.position = tile_coord * tile_size
        line_of_sight = enemy_config.line_of_sight
        # Setup enemy HP and logic
        dead = false
        full_hp = hp
        current_hp = full_hp
        drop_chance = enemy_config.drop_chance
        game_class = game
        # Setup enemy combat
        attack_dmg = damage
        can_evade = enemy_config.can_evade
        can_summon = enemy_config.summon_probs > 0
        summon_probs = enemy_config.summon_probs
        starting_summon = enemy_config.summon_turns
        aggro = enemy_config.aggro
        # Setup display
        offset_divider = enemy_config.offset_divider
        
        game.add_child(sprite_node)

    func remove():
        sprite_node.play("death")
        if sprite_node.animation == "death" && sprite_node.frame == sprite_node.frames.get_frame_count("death")-1:
            sprite_node.queue_free()

        # Add ladder
        game_class.level.level_node.sfx_player.get_node("PlaceLadder").play()
        game_class.level.set_tile(6, 6, Tile.Ladder)
        game_class.level.statue_countdown = [1000, 1000, 1000, 1000]
        BackgroundMusic.stop_all()

    func act(level, player):
        level.statue_countdown()

        if !sprite_node.visible:
            return

        if current_hp < (full_hp * 0.5): 
            aggro = 0.85
            sprite_node.play("walk")

        var enemy_pos = level.enemy_pathfinding.get_closest_point(Vector3(tile_coord.x, tile_coord.y, 0))
        var player_pos = level.enemy_pathfinding.get_closest_point(Vector3(player.tile_coord.x, player.tile_coord.y, 0))
        var path = level.enemy_pathfinding.get_point_path(enemy_pos, player_pos)

        if path:
            # If path exists between enemy and player
            assert(path.size() > 1)
            var move_tile = Vector2(path[1].x, path[1].y)


            if can_summon:
                var probs = rand_range(0, 1)
                if probs > (1 - summon_probs):
                    sprite_node.play("summon")
                    # level.summon_familiar(tile_coord.x, tile_coord.y, player.tile_coord, summon_probs)
                    level.summon_statues()
                else:
                    pass

            if move_tile == player.tile_coord:
                self._attack(player, TILE_SIZE)

            else:
                var blocked = false
                for enemy in level.enemies:
                    if enemy.tile_coord == move_tile:
                        blocked = true
                        break
                if !blocked:
                    self._move(tile_coord, move_tile, sprite_node, player.tile_coord, level)


    func _get_evade_pos(current_pos, default_pos, level):
        # Choose a position around the enemy while avoiding the player
        var offsets = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]

        for idx in offsets.size():
            if current_pos + offsets[idx] == default_pos:
                offsets.remove(idx)
                break

        var unblocked_tiles = []
        for offset in offsets:
            var test_tile  = current_pos + offset
            var blocked = true

            for enemy in level.enemies:
                if enemy.tile_coord == test_tile:
                    blocked = true
                    break

                var tile_type = level.get_tile_type(test_tile.x, test_tile.y)
                match tile_type:
                    Tile.Ground:
                        blocked = false

                if !blocked:
                    unblocked_tiles.append(test_tile)

        if unblocked_tiles.size() == 0:
            return default_pos
        else:
            var move_tile = unblocked_tiles[randi() % unblocked_tiles.size()]
            return move_tile


    func _attack(player, tile_size):
        # Update enemy animations
        var dx = (player.tile_coord.x - tile_coord.x) 
        var dy = (player.tile_coord.y - tile_coord.y)
        sprite_node.play("attack")
        sprite_node.slash_effect.play("default")
        sprite_node.slash_effect.set_frame(0)
        var offset = Vector2(dx * TILE_SIZE / offset_divider, dy * TILE_SIZE / offset_divider)
        sprite_node.set_offset(offset)
        sprite_node.slash_effect.set_offset(offset * 1.824)

        # Send damage to player
        player.take_damage(attack_dmg)

    func take_damage(dmg, level, player_pos):
        if dead:
            return

        current_hp = max(0, current_hp - dmg)
        if current_hp == 0:
            dead = true

            # Drop item
            var probs = rand_range(0, 1)
            if probs > (1 - drop_chance):
                ItemFactory.drop_item(game_class, tile_coord.x, tile_coord.y)


    func _move(current_pos, dest_pos, enemy_node, player_tile, level):
        # Set enemy sprite orientation
        if current_pos.x - dest_pos.x > 0:
            enemy_node.set_flip_h(true)
        if current_pos.x - dest_pos.x < 0:
            enemy_node.set_flip_h(false)

        # Move if player is within line of sight
        if self._player_is_visible(player_tile):

            if !in_pursuit:
                in_pursuit = true
                enemy_node.los_effect.set_frame(0)
                enemy_node.los_effect.play("default")

            tile_coord = dest_pos

            var probs = rand_range(0, 1)
            if probs > aggro:
                dest_pos = self._get_evade_pos(current_pos, dest_pos, level)

            tile_coord = dest_pos

    func _player_is_visible(player_tile):
        var dx = pow(player_tile.x - tile_coord.x, 2)
        var dy = pow(player_tile.y - tile_coord.y, 2)
        var r_2 = pow(line_of_sight, 2)
        if dx + dy <= r_2:
            return true
        else:
            return false
        


# Generic enemy


class Enemy extends Reference:
    var name
    var sprite_node
    var tile_coord
    var dead = false
    var line_of_sight
    var full_hp
    var current_hp
    var attack_dmg
    var drop_chance
    var game_class
    var can_summon
    var summon_probs

    # Status
    var in_pursuit
    var defend = false
    var can_evade = false
    var starting_defend
    var dmg_counter = 0
    var defend_turns = 0

    # Display
    var offset_divider = 4

    func _init(game, hp, damage, sprite_scene, enemy_config, x, y, tile_size):
        sprite_node = sprite_scene.instance()
        name = enemy_config.name
        # Setup enemy movement
        tile_coord = Vector2(x, y)
        sprite_node.position = tile_coord * tile_size
        line_of_sight = enemy_config.line_of_sight
        # Setup enemy HP and logic
        dead = false
        full_hp = hp
        current_hp = full_hp
        drop_chance = enemy_config.drop_chance
        game_class = game
        # Setup enemy combat
        attack_dmg = damage
        starting_defend = enemy_config.defend_turns
        can_evade = enemy_config.can_evade
        can_summon = enemy_config.summon_probs > 0
        summon_probs = enemy_config.summon_probs
        # Setup display
        offset_divider = enemy_config.offset_divider
        
        game.add_child(sprite_node)

    func remove():
        sprite_node.play("death")
        if sprite_node.animation == "death" && sprite_node.frame == sprite_node.frames.get_frame_count("death")-1:
            sprite_node.queue_free()

    func act(level, player):

        if !sprite_node.visible:
            return

        if defend:
            sprite_node.play("defend")
            sprite_node.set_offset(Vector2(0,0))

        var enemy_pos = level.enemy_pathfinding.get_closest_point(Vector3(tile_coord.x, tile_coord.y, 0))
        var player_pos = level.enemy_pathfinding.get_closest_point(Vector3(player.tile_coord.x, player.tile_coord.y, 0))
        var path = level.enemy_pathfinding.get_point_path(enemy_pos, player_pos)

        if path:
            # If path exists between enemy and player
            assert(path.size() > 1)
            var move_tile = Vector2(path[1].x, path[1].y)


            if can_summon:
                var probs = rand_range(0, 1)
                if probs > (1 - summon_probs):
                    level.summon_familiar(tile_coord.x, tile_coord.y, player.tile_coord, summon_probs)
                else:
                    pass

            if move_tile == player.tile_coord:
                if defend:  # 30% chance to attack when defending
                    var probs = rand_range(0, 1)
                    if probs > 0.7:
                        self._attack(player, TILE_SIZE)
                    else:
                        pass
                else:
                    self._attack(player, TILE_SIZE)
            else:
                var blocked = false
                for enemy in level.enemies:
                    if enemy.tile_coord == move_tile:
                        blocked = true
                        break
                if !blocked:
                    self._move(tile_coord, move_tile, sprite_node, player.tile_coord, level)


    func _attack(player, tile_size):
        # Update enemy animations
        var dx = (player.tile_coord.x - tile_coord.x) 
        var dy = (player.tile_coord.y - tile_coord.y)
        sprite_node.play("attack")
        sprite_node.set_offset(Vector2(dx * TILE_SIZE / offset_divider, dy * TILE_SIZE / offset_divider))

        # In case enemy can defend, apply attack reduction
        # to even things out for the player
        if defend:
            attack_dmg = attack_dmg * 0.5
            self._reduce_defend()

        # Send damage to player
        player.take_damage(attack_dmg)

    func take_damage(dmg, level, player_pos):
        if dead:
            return

        # If enemy can defend, apply damage reduction
        if defend && can_evade:
            var dest_pos = self._get_evade_pos(player_pos, tile_coord, level)
            tile_coord = dest_pos
            dmg = 0
        elif defend:
            dmg = dmg * 0.7
        else:
            dmg_counter += 1
            if dmg_counter == floor(starting_defend * 0.3):
                defend = true
                defend_turns = starting_defend
                dmg_counter = 0

        current_hp = max(0, current_hp - dmg)
        if current_hp == 0:
            dead = true

            # Drop item
            var probs = rand_range(0, 1)
            if probs > (1 - drop_chance):
                ItemFactory.drop_item(game_class, tile_coord.x, tile_coord.y)

    func _reduce_defend():
        defend_turns -= 1
        if defend_turns < 0:
            defend_turns = 0
        if defend_turns == 0:
            defend = false

    func _move(current_pos, dest_pos, enemy_node, player_tile, level):
        # Set enemy sprite orientation
        if current_pos.x - dest_pos.x > 0:
            enemy_node.set_flip_h(true)
        if current_pos.x - dest_pos.x < 0:
            enemy_node.set_flip_h(false)

        # Move if player is within line of sight
        if self._player_is_visible(player_tile):

            if !in_pursuit:
                in_pursuit = true
                enemy_node.los_effect.set_frame(0)
                enemy_node.los_effect.play("default")

            if defend && can_evade:
                dest_pos = self._get_evade_pos(current_pos, dest_pos, level)
                self._reduce_defend()
            else:
                self._reduce_defend()

            tile_coord = dest_pos

    func _get_evade_pos(current_pos, default_pos, level):
        # Choose a position around the enemy while avoiding the player
        var offsets = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]

        for idx in offsets.size():
            if current_pos + offsets[idx] == default_pos:
                offsets.remove(idx)
                break

        var random_offset = offsets[randi() % offsets.size()]
        var move_tile = current_pos + random_offset
        var blocked = true

        for enemy in level.enemies:
            if enemy.tile_coord == move_tile:
                blocked = true
                break

        var tile_type = level.get_tile_type(move_tile.x, move_tile.y)
        match tile_type:
            Tile.Ground:
                blocked = false

        if blocked:
            return default_pos
        else:
            return move_tile

    func _player_is_visible(player_tile):
        var dx = pow(player_tile.x - tile_coord.x, 2)
        var dy = pow(player_tile.y - tile_coord.y, 2)
        var r_2 = pow(line_of_sight, 2)
        if dx + dy <= r_2:
            return true
        else:
            return false
