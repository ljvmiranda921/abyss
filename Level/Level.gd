extends Node2D

# Variables set by init
var level_size: Vector2
var room_count: int
var min_room_dim: int = 5
var max_room_dim: int = 8
var start_room: Rect2

# Containers
var map = []
var rooms = []

# Node references
onready var tile_map = $TileMap
onready var visibility_map = $VisibilityMap

# Tilemap reference
enum Tile { OuterWall, InnerWall, Ground, Door }

func _ready():
    randomize()
    build_level()
    

func init(size, room_count, min_room_dim, max_room_dim):
    self.level_size = size
    self.room_count = room_count
    self.min_room_dim = min_room_dim
    self.max_room_dim = max_room_dim


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


func build_level():
    # Clear containers first
    rooms.clear()
    map.clear()
    tile_map.clear()

    for x in range(level_size.x):
        map.append([])
        for y in range(level_size.y):
            map[x].append(Tile.OuterWall)
            set_tile(x, y, Tile.OuterWall)

    var free_regions = [Rect2(Vector2(2, 2), level_size - Vector2(4, 4))]
    for i in range(room_count):
        add_rooms(free_regions)
        if free_regions.empty():
            break

    connect_rooms()


func add_rooms(free_regions):
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
            set_tile(x, y, Tile.Ground)

    cut_regions(free_regions, room)


func cut_regions(free_regions, region_to_remove):
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


func connect_rooms():
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
    while ! is_everything_connected(room_graph):
        add_random_connection(stone_graph, room_graph)


func is_everything_connected(graph):
    var points = graph.get_points()
    var start = points.pop_back()
    for point in points:
        var path = graph.get_point_path(start, point)
        if ! path:
            return false
    return true


func add_random_connection(stone_graph, room_graph):
    var start_room_id = get_least_connected_point(room_graph)
    var end_room_id = get_nearest_unconnected_point(room_graph, start_room_id)

    # Pick door locations
    var start_position = pick_random_door_location(rooms[start_room_id])
    var end_position = pick_random_door_location(rooms[end_room_id])

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


func get_least_connected_point(graph):
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


func get_nearest_unconnected_point(graph, target_point):
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


func pick_random_door_location(room):
    var options = []
    for x in range(room.position.x + 1, room.end.x - 2):
        options.append(Vector3(x, room.position.y, 0))
        options.append(Vector3(x, room.end.y - 1, 0))

    for y in range(room.position.y + 1, room.end.y - 2):
        options.append(Vector3(room.position.x, y, 0))
        options.append(Vector3(room.end.x - 1, y, 0))

    return options[randi() % options.size()]


func set_tile(x, y, type):
    map[x][y] = type
    tile_map.set_cell(x, y, type, false, false, false, _get_subtile(type))


func _get_subtile(id) -> Vector2:
    var tiles = tile_map.tile_set
    var rect = tile_map.tile_set.tile_get_region(id)
    var x = randi() % int(rect.size.x / tiles.autotile_get_size(id).x)
    var y = randi() % int(rect.size.y / tiles.autotile_get_size(id).y)
    return Vector2(x, y)
