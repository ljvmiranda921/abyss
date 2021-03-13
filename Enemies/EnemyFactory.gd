class_name EnemyFactory

const MonkeyScene = preload("res://Enemies/ForestEnemies/EnemyMonkey.tscn")
const PlanteraScene = preload("res://Enemies/ForestEnemies/EnemyPlantera.tscn")
const BeeScene = preload("res://Enemies/ForestEnemies/EnemyBee.tscn")


const FOREST_ENEMIES = [
    {
        "name": "WildMonkey",
        "scene": MonkeyScene,
        "spawn_probs": 0.35,
        "acc_weight": 0.0, 
    },
    {
        "name": "Plantera",
        "scene": PlanteraScene, 
        "spawn_probs": 0.15,
        "acc_weight": 0.0, 
    },
    {
        "name": "BeeSoldier",
        "scene": BeeScene,
        "spawn_probs": 0.50,
        "acc_weight": 0.0, 
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

    var enemy = Enemy.new(game, enemy_def.scene, x, y, 32)
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

    func _init(game, sprite_scene, x, y, tile_size):
        sprite_node = sprite_scene.instance()
        tile_coord = Vector2(x, y)
        sprite_node.position = tile_coord * tile_size
        game.add_child(sprite_node)

    func remove():
        sprite_node.queue_free()
