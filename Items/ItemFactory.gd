class_name ItemFactory

const PotionScene = preload("res://Items/Potion.tscn")

const ITEM_CONFIG = [
    {
        "name": "HealingPotion",
        "description": "Heal small amount of HP upon pickup",
        "effect": "heal_hp",
        "scene": PotionScene,
        "spawn_probs": 1.0,
        "acc_weight": 0.0, 
    },
]

static func drop_item(game, x, y):
    var total_weight = init_probabilities(ITEM_CONFIG)
    var item_def = pick_some_object(ITEM_CONFIG, total_weight)
    var item = Item.new(game, item_def.scene, item_def, x, y, 32)
    return item

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


class Item extends Reference:

    var sprite_node
    var tile_coord
    var name
    var description
    var effect

    func _init(game, sprite_scene, item_config, x, y, tile_size):
        sprite_node = sprite_scene.instance()
        # Item metadata
        name = item_config.name
        description = item_config.description
        # Item function and logic
        effect = item_config.effect
        # Item position
        tile_coord = Vector2(x, y)
        sprite_node.position = tile_coord * tile_size
        game.add_child(sprite_node)
        game.level.items.append(self)

    func remove():
        sprite_node.queue_free()


    func use_effect(player):
        call(effect, player)


    func heal_hp(player, heal_value = 15):
        player.get_node("HealEffect").play("default")
        player.get_node("HealEffect").set_frame(0)
        var new_hp = player.hp + heal_value
        if new_hp > player.total_hp:
            player.hp = player.total_hp
        else:
            player.hp = new_hp



