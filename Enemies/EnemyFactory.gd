class_name EnemyFactory

const MonkeyScene = preload("res://Enemies/ForestEnemies/EnemyMonkey.tscn")
const PlanteraScene = preload("res://Enemies/ForestEnemies/EnemyPlantera.tscn")
const BeeScene = preload("res://Enemies/ForestEnemies/EnemyBee.tscn")

const TILE_SIZE = 32


const FOREST_ENEMIES = [
    {
        "name": "WildMonkey",
        "scene": MonkeyScene,
        "spawn_probs": 0.35,
        "acc_weight": 0.0, 
        "line_of_sight": 3,
        "drop_chance": 0.6,
        "hp": 75, 
        "damage": 15
    },
    {
        "name": "Plantera",
        "scene": PlanteraScene, 
        "spawn_probs": 0.3,
        "acc_weight": 0.0, 
        "line_of_sight": 2,
        "drop_chance": 0.70,
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
        "hp": 60,
        "damage": 10
    },
]

const CAVERN_ENEMIES = {}
const UDRWLD_ENEMIES = {}

# Only for general mobs
const ENEMY_DEFINITIONS = [FOREST_ENEMIES, CAVERN_ENEMIES, UDRWLD_ENEMIES]


static func spawn_enemy(game, level_num, x, y):
    var mobs = ENEMY_DEFINITIONS[level_num]
    var total_weight = init_probabilities(mobs)
    var enemy_def = pick_some_object(mobs, total_weight)

    var enemy = Enemy.new(game, enemy_def.hp, enemy_def.damage, enemy_def.scene, enemy_def, x, y, 32)
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


class Enemy extends Reference:
    var sprite_node
    var tile_coord
    var dead = false
    var line_of_sight
    var full_hp
    var current_hp
    var attack_dmg
    var drop_chance
    var game_class

    # Status
    var in_pursuit

    func _init(game, hp, damage, sprite_scene, enemy_config, x, y, tile_size):
        sprite_node = sprite_scene.instance()
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
        
        game.add_child(sprite_node)

    func remove():
        sprite_node.play("death")
        if sprite_node.animation == "death" && sprite_node.frame == sprite_node.frames.get_frame_count("death")-1:
            sprite_node.queue_free()

    func act(level, player):
        if !sprite_node.visible:
            return

        var enemy_pos = level.enemy_pathfinding.get_closest_point(Vector3(tile_coord.x, tile_coord.y, 0))
        var player_pos = level.enemy_pathfinding.get_closest_point(Vector3(player.tile_coord.x, player.tile_coord.y, 0))
        var path = level.enemy_pathfinding.get_point_path(enemy_pos, player_pos)

        if path:
            assert(path.size() > 1)
            var move_tile = Vector2(path[1].x, path[1].y)
            if move_tile == player.tile_coord:
                self._attack(player, TILE_SIZE)
            else:
                var blocked = false
                for enemy in level.enemies:
                    if enemy.tile_coord == move_tile:
                        blocked = true
                        break
                if !blocked:
                    self._move(tile_coord, move_tile, sprite_node, player.tile_coord)

    func _attack(player, tile_size):
        # Update enemy animations
        var dx = (player.tile_coord.x - tile_coord.x) 
        var dy = (player.tile_coord.y - tile_coord.y)
        sprite_node.play("attack")
        sprite_node.set_offset(Vector2(dx * TILE_SIZE / 4, dy * TILE_SIZE / 4))
        # sprite_node.z_index = 100

        # Send damage to player
        player.take_damage(attack_dmg)


    func take_damage(dmg):
        if dead:
            return

        current_hp = max(0, current_hp - dmg)
        if current_hp == 0:
            dead = true

            # Drop item
            var probs = rand_range(0, 1)
            if probs > (1 - drop_chance):
                ItemFactory.drop_item(game_class, tile_coord.x, tile_coord.y)


    func _move(current_pos, dest_pos, enemy_node, player_tile):
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

    func _player_is_visible(player_tile):
        var dx = pow(player_tile.x - tile_coord.x, 2)
        var dy = pow(player_tile.y - tile_coord.y, 2)
        var r_2 = pow(line_of_sight, 2)
        if dx + dy <= r_2:
            return true
        else:
            return false
        

