class_name LevelFactory

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door, MapObject, Ladder, TrapOff, TrapOn}


const ForestScene = preload("res://Level/Forest.tscn")
const CavernScene = preload("res://Level/Cavern.tscn")
const UnderworldScene = preload("res://Level/Underworld.tscn")

const LEVEL_CONFIG = [
    {
        "name": "Forest",
        "size": Vector2(30, 30),
        "scene": ForestScene,
        "room_count": 8,
        "min_room_dim": 5, 
        "max_room_dim": 8,
        "trap_countdown": 0,
        "trap_damage": 0
    },
    {
        "name": "Cavern",
        "size": Vector2(50, 50),
        "scene": CavernScene,
        "room_count": 15,
        "min_room_dim": 7, 
        "max_room_dim": 8, 
        "trap_countdown": 3,
        "trap_damage": 5
    },
    {
        "name": "Underworld",
        "size": Vector2(20, 50),
        "scene": UnderworldScene,
        "room_count": 15,
        "min_room_dim": 5, 
        "max_room_dim": 7, 
        "trap_countdown": 10,
        "trap_damage": 10
    }
]



static func create_level(game, level_num):
    var level_cfg = LEVEL_CONFIG[level_num]
    var level = Level.new(level_cfg.scene, game, level_cfg)
    return level
    

class Level extends Reference:

    var level_node
    var level_size
    var room_count
    var min_room_dim
    var max_room_dim
    var game_copy

    var map = []
    var rooms = []
    var enemies = []
    var items = []
    var map_objects = []
    var enemy_pathfinding
    var trap_countdown
    var trap_damage
    var trap_on = false

    func _init(scene, game, config):
        level_node = scene.instance()
        level_size = config.size
        room_count = config.room_count
        min_room_dim = config.min_room_dim
        max_room_dim = config.max_room_dim
        trap_countdown = config.trap_countdown
        trap_damage = config.trap_damage
        game_copy = game

        game.add_child(level_node)

        randomize()
        self.build_level()
        self.place_end_ladder()

    func remove():
        level_node.queue_free()

    func get_tile_type(x, y) -> int:
        var tile_type: int
        if x >= 0 && x < level_size.x && y >= 0 && y < level_size.y:
            tile_type = map[x][y]
        else:
            tile_type = Tile.OuterWall
        return tile_type


    func get_start_coord() -> Vector2:
        # Get starting coordinate when initializing player
        var start_room = rooms.front()
        var x = start_room.position.x + 1 + randi() % int(start_room.size.x - 3)
        var y = start_room.position.y + 1 + randi() % int(start_room.size.y - 3)
        return Vector2(x, y)

    func play_effect(effect, x, y):
        if effect == "poof":
            level_node.poof_effect.position = Vector2(x, y)
            level_node.poof_effect.play("default")
            level_node.poof_effect.set_frame(0)
        if effect == "cast":
            print_debug("playing cast")
            level_node.cast_effect.position = Vector2(x, y)
            level_node.cast_effect.play("default")
            level_node.cast_effect.set_frame(0)


    func set_tile(x, y, type):
        map[x][y] = type
        level_node.tile_map.set_cell(x, y, type, false, false, false, _get_subtile(type))

        if type == Tile.Ground:
            clear_path(Vector2(x, y))
        if type == Tile.TrapOn:
            clear_path(Vector2(x, y))
        if type == Tile.TrapOff:
            clear_path(Vector2(x, y))


    func activate_traps():
        for x in range(level_size.x):
            for y in range(level_size.y):
                var tile_type = get_tile_type(x, y)
                if tile_type == Tile.TrapOff:
                    set_tile(x, y, Tile.TrapOn)
                    trap_on = true

    func deactivate_traps():
        for x in range(level_size.x):
            for y in range(level_size.y):
                var tile_type = get_tile_type(x, y)
                if tile_type == Tile.TrapOn:
                    set_tile(x, y, Tile.TrapOff)
                    trap_on = false


    func place_end_ladder():
        var end_room = rooms.back()
        var ladder_x = end_room.position.x + 1 + randi() % int(end_room.size.x - 2)
        var ladder_y = end_room.position.y + 1 + randi() % int(end_room.size.y - 2)
        set_tile(ladder_x, ladder_y, Tile.Ladder)
        

    func update_visibility_map(player_tile: Vector2, tile_size: int, space_state):

        var player_center = _tile_to_pixel_center(player_tile.x, player_tile.y, tile_size)

        for x in range(level_size.x):
            for y in range(level_size.y):
                if level_node.visibility_map.get_cell(x, y) == 0:
                    var x_dir = 1 if x < player_tile.x else -1
                    var y_dir = 1 if y < player_tile.y else -1
                    var test_point = _tile_to_pixel_center(x, y, tile_size) + Vector2(x_dir, y_dir) * tile_size / 2

                    var occlusion = space_state.intersect_ray(player_center, test_point)
                    if !occlusion || (occlusion.position - test_point).length() < 1:
                        level_node.visibility_map.set_cell(x, y, -1)

    func update_enemy_positions(player_tile: Vector2, tile_size: int, space_state):

        var player_center = _tile_to_pixel_center(player_tile.x, player_tile.y, tile_size)

        for enemy in enemies:
            enemy.sprite_node.position = enemy.tile_coord * tile_size
            if !enemy.sprite_node.visible:
                var enemy_center = _tile_to_pixel_center(enemy.tile_coord.x, enemy.tile_coord.y, tile_size)
                var occlusion = space_state.intersect_ray(player_center, enemy_center)
                if !occlusion:
                    enemy.sprite_node.visible = true

    func summon_familiar(x, y, player_pos, summon_probs):
        var offsets = [Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(-1,0)]
        var summoner_position = Vector2(x,y)

        for offset in offsets:
            var test_position = offset + summoner_position
            var blocked = false
            for enemy in enemies:
                if enemy.tile_coord.x == test_position.x && enemy.tile_coord.y == test_position.y:
                    blocked = true
                    break
                if map[test_position.x][test_position.y] != Tile.Ground:
                    blocked = true
                    break

            if player_pos.x == test_position.x && player_pos.y == test_position.y:
                blocked = true
                break

            if !blocked:
                var probs = rand_range(0, 1)
                if probs > (1 - summon_probs):
                    play_effect("cast", test_position.x * 32, test_position.y * 32)
                    var enemy = EnemyFactory.spawn_familiar(game_copy, test_position.x, test_position.y)
                    enemies.append(enemy)


    func add_enemies(game, level_num, num_enemies):
        for i in range(num_enemies):
            var room = rooms[1 + randi() % (rooms.size() - 1)]
            var x = room.position.x + 1 + randi() % int(room.size.x - 2)
            var y = room.position.y + 1 + randi() % int(room.size.y - 2)

            var blocked = false
            for enemy in enemies:
                if enemy.tile_coord.x == x && enemy.tile_coord.y == y:
                    blocked = true
                    break
                if map[x][y] != Tile.Ground:
                    blocked = true
                    break

            if !blocked:
                var enemy = EnemyFactory.spawn_enemy(game, level_num, x, y)
                enemies.append(enemy)


    func clear_path(tile):
        var new_point = enemy_pathfinding.get_available_point_id()
        enemy_pathfinding.add_point(new_point, Vector3(tile.x, tile.y, 0))
        var points_to_connect = []

        if tile.x > 0 && map[tile.x - 1][tile.y] == Tile.Ground:
            points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x - 1, tile.y, 0)))
        if tile.y > 0 && map[tile.x][tile.y - 1] == Tile.Ground:
            points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y - 1, 0)))
        if tile.x < level_size.x - 1 && map[tile.x + 1][tile.y] == Tile.Ground:
            points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x + 1, tile.y, 0)))
        if tile.y < level_size.y - 1 && map[tile.x][tile.y + 1] == Tile.Ground:
            points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y + 1, 0)))

        for point in points_to_connect:
            enemy_pathfinding.connect_points(point, new_point)




    func _tile_to_pixel_center(x, y, tile_size: int):
        return Vector2((x + 0.5) * tile_size, (y + 0.5) * tile_size)

    func build_level():
        # Clear containers first
        rooms.clear()
        map.clear()
        level_node.tile_map.clear()

        for enemy in enemies:
            enemy.remove()
        enemies.clear()

        for item in items:
            item.remove()
        items.clear()


        enemy_pathfinding = AStar.new()


        for x in range(level_size.x):
            map.append([])
            for y in range(level_size.y):
                map[x].append(Tile.OuterWall)
                set_tile(x, y, Tile.OuterWall)
                level_node.visibility_map.set_cell(x, y, 0)

        var free_regions = [Rect2(Vector2(2, 2), level_size - Vector2(4, 4))]
        for i in range(room_count):
            _add_rooms(free_regions)
            if free_regions.empty():
                break

        _connect_rooms()


    func _add_rooms(free_regions):
        var region = free_regions[randi() % free_regions.size()]

        var size_x = min_room_dim
        if region.size.x > min_room_dim:
            size_x += randi() % int(region.size.x - min_room_dim)

        var size_y = min_room_dim
        if region.size.y > min_room_dim:
            size_y += randi() % int(region.size.y - min_room_dim)

        size_x = min(size_x, max_room_dim)
        size_y = min(size_y, max_room_dim)

        var start_x = region.position.x
        if region.size.x > size_x:
            start_x += randi() % int(region.size.x - size_x)

        var start_y = region.position.y
        if region.size.y > size_y:
            start_y += randi() % int(region.size.y - size_y)

        var room = Rect2(start_x, start_y, size_x, size_y)
        rooms.append(room)

        for x in range(start_x, start_x + size_x):
            set_tile(x, start_y, Tile.InnerWall)
            set_tile(x, start_y + size_y - 1, Tile.InnerWall)

        for y in range(start_y + 1, start_y + size_y - 1):
            set_tile(start_x, y, Tile.InnerWall)
            set_tile(start_x + size_x - 1, y, Tile.InnerWall)

            for x in range(start_x + 1, start_x + size_x - 1):
                var probs = rand_range(0, 1)
                if probs > (1-0.10) && _no_doors_around(x, y):
                    set_tile(x, y, Tile.MapObject)
                elif probs > (1-0.2) && trap_countdown > 0:
                    set_tile(x, y, Tile.TrapOff)
                else:
                    set_tile(x, y, Tile.Ground)

        _cut_regions(free_regions, room)


    func _no_doors_around(x, y):
        if map[x + 1][y] != Tile.Door && map[x - 1][y] != Tile.Door && map[x][y+1] != Tile.Door && map[x][y-1] != Tile.Door:
            return true
        else:
            return false


    func _cut_regions(free_regions, region_to_remove):
        var removal_queue = []
        var addition_queue = []

        for region in free_regions:
            if region.intersects(region_to_remove):
                removal_queue.append(region)

                var leftover_left = region_to_remove.position.x - region.position.x - 1
                var leftover_right = region.end.x - region_to_remove.end.x - 1
                var leftover_above = region_to_remove.position.y - region.position.y - 1
                var leftover_below = region.end.y - region_to_remove.end.y - 1

                if leftover_left >= min_room_dim:
                    addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
                if leftover_right >= min_room_dim:
                    addition_queue.append(
                        Rect2(
                            Vector2(region_to_remove.end.x + 1, region.position.y),
                            Vector2(leftover_right, region.size.y)
                        )
                    )
                if leftover_above >= min_room_dim:
                    addition_queue.append(
                        Rect2(region.position, Vector2(region.size.x, leftover_above))
                    )
                if leftover_below >= min_room_dim:
                    addition_queue.append(
                        Rect2(
                            Vector2(region.position.x, region_to_remove.end.y + 1),
                            Vector2(region.size.x, leftover_below)
                        )
                    )

        for region in removal_queue:
            free_regions.erase(region)

        for region in addition_queue:
            free_regions.append(region)


    func _connect_rooms():
        var stone_graph = AStar.new()
        var point_id = 0
        for x in range(level_size.x):
            for y in range(level_size.y):
                if map[x][y] == Tile.OuterWall:
                    stone_graph.add_point(point_id, Vector3(x, y, 0))

                    # Connect to left if also stone
                    if x > 0 && map[x - 1][y] == Tile.OuterWall:
                        var left_point = stone_graph.get_closest_point(Vector3(x - 1, y, 0))
                        stone_graph.connect_points(point_id, left_point)

                    # Connect to above if also stone
                    if y > 0 && map[x][y - 1] == Tile.OuterWall:
                        var above_point = stone_graph.get_closest_point(Vector3(x, y - 1, 0))
                        stone_graph.connect_points(point_id, above_point)

                    point_id += 1

        # Build an AStar graph of room connections
        var room_graph = AStar.new()
        point_id = 0
        for room in rooms:
            var room_center = room.position + room.size / 2
            room_graph.add_point(point_id, Vector3(room_center.x, room_center.y, 0))
            point_id += 1

        # Add random connections until everything is connected
        while ! _is_everything_connected(room_graph):
            _add_random_connection(stone_graph, room_graph)


    func _is_everything_connected(graph):
        var points = graph.get_points()
        var start = points.pop_back()
        for point in points:
            var path = graph.get_point_path(start, point)
            if ! path:
                return false
        return true


    func _add_random_connection(stone_graph, room_graph):
        var start_room_id = _get_least_connected_point(room_graph)
        var end_room_id = _get_nearest_unconnected_point(room_graph, start_room_id)

        # Pick door locations
        var start_position = _pick_random_door_location(rooms[start_room_id])
        var end_position = _pick_random_door_location(rooms[end_room_id])

        # Find a path to connect the doors to each other
        var closest_start_point = stone_graph.get_closest_point(start_position)
        var closest_end_point = stone_graph.get_closest_point(end_position)

        var path = stone_graph.get_point_path(closest_start_point, closest_end_point)

        # Add path
        set_tile(start_position.x, start_position.y, Tile.Door)
        set_tile(end_position.x, end_position.y, Tile.Door)

        for position in path:
            set_tile(position.x, position.y, Tile.Ground)

        room_graph.connect_points(start_room_id, end_room_id)


    func _get_least_connected_point(graph):
        var point_ids = graph.get_points()

        var least
        var tied_for_least = []

        for point in point_ids:
            var count = graph.get_point_connections(point).size()
            if ! least || count < least:
                least = count
                tied_for_least = [point]
            elif count == least:
                tied_for_least.append(point)

        return tied_for_least[randi() % tied_for_least.size()]


    func _get_nearest_unconnected_point(graph, target_point):
        var target_position = graph.get_point_position(target_point)
        var point_ids = graph.get_points()

        var nearest
        var tied_for_nearest = []

        for point in point_ids:
            if point == target_point:
                continue

            var path = graph.get_point_path(point, target_point)
            if path:
                continue

            var dist = (graph.get_point_position(point) - target_position).length()
            if ! nearest || dist < nearest:
                nearest = dist
                tied_for_nearest = [point]
            elif dist == nearest:
                tied_for_nearest.append(point)

        return tied_for_nearest[randi() % tied_for_nearest.size()]


    func _pick_random_door_location(room):
        var options = []
        for x in range(room.position.x + 1, room.end.x - 2):
            options.append(Vector3(x, room.position.y, 0))
            options.append(Vector3(x, room.end.y - 1, 0))

        for y in range(room.position.y + 1, room.end.y - 2):
            options.append(Vector3(room.position.x, y, 0))
            options.append(Vector3(room.end.x - 1, y, 0))

        return options[randi() % options.size()]


    func _get_subtile(id) -> Vector2:
        var tiles = level_node.tile_map.tile_set
        var rect = level_node.tile_map.tile_set.tile_get_region(id)
        var x = randi() % int(rect.size.x / tiles.autotile_get_size(id).x)
        var y = randi() % int(rect.size.y / tiles.autotile_get_size(id).y)
        return Vector2(x, y)


        
