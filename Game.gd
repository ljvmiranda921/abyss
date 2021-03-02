extends Node2D


const TILE_SIZE = 32
const LEVEL_SIZES = [
        Vector2(30, 30),
        Vector2(35, 35),
        Vector2(40, 40),
]

const LEVEL_ROOM_COUNTS = [5, 7, 9]
const MIN_ROOM_DIMENSION = 5
const MAX_ROOM_DIMENSION = 8

enum Tile {OuterWall, InnerWall, Ground}

# Current Level
var level_num = 0
var map = []
var rooms = []
var level_size

# Node references

onready var tile_map = $TileMap
onready var player = $Player

# Game State

var player_tile
var score = 0


func _ready():
    OS.set_window_size(Vector2(1280, 720))
    randomize()
    build_level()

func _get_subtile_coord(id):
    var tiles = $TileMap.tile_set
    var rect = tile_map.tile_set.tile_get_region(id)
    var x = randi() % int(rect.size.x / tiles.autotile_get_size(id).x)
    var y = randi() % int(rect.size.y / tiles.autotile_get_size(id).y)
    return Vector2(x, y)


func build_level():

    # Clear-out everything first
    rooms.clear()
    map.clear()
    tile_map.clear()

    level_size = LEVEL_SIZES[level_num]  
    for x in range(level_size.x):
        map.append([])
        for y in range(level_size.y):
            map[x].append(Tile.OuterWall)
            tile_map.set_cell(x, y, Tile.OuterWall, false, false, false, _get_subtile_coord(Tile.OuterWall))

    var free_regions = [Rect2(Vector2(2,2), level_size - Vector2(4,4))]
    var num_rooms = LEVEL_ROOM_COUNTS[level_num]
    for i in range(num_rooms):
        add_rooms(free_regions)
        if free_regions.empty():
            break


func add_rooms(free_regions):
    var region = free_regions[randi() % free_regions.size()]

    var size_x = MIN_ROOM_DIMENSION
    if region.size.x > MIN_ROOM_DIMENSION:
        size_x += randi() % int(region.size.x - MIN_ROOM_DIMENSION)

    var size_y = MIN_ROOM_DIMENSION
    if region.size.y > MIN_ROOM_DIMENSION:
        size_y += randi() % int(region.size.y - MIN_ROOM_DIMENSION)

    size_x = min(size_x, MAX_ROOM_DIMENSION)
    size_y = min(size_y, MAX_ROOM_DIMENSION)

    var start_x  = region.position.x
    if region.size.x > size_x:
        start_x += randi() % int(region.size.x - size_x)

    var start_y  = region.position.y
    if region.size.y > size_y:
        start_y += randi() % int(region.size.y - size_y)

    var room = Rect2(start_x, start_y, size_x, size_y)
    rooms.append(room)

    for x in range(start_x, start_x + size_x):
        set_tile(x, start_y, Tile.InnerWall)
        set_tile(x, start_y + size_y - 1, Tile.InnerWall)

    for y in range(start_y +1, start_y + size_y - 1):
        set_tile(start_x, y, Tile.InnerWall)
        set_tile(start_x + size_x - 1, y, Tile.InnerWall)

        for x in range(start_x + 1, start_x + size_x -1):
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

            if leftover_left >= MIN_ROOM_DIMENSION:
                addition_queue.append(Rect2(region.position, Vector2(leftover_left, region.size.y)))
            if leftover_right >= MIN_ROOM_DIMENSION:
                addition_queue.append(Rect2(Vector2(region_to_remove.end.x + 1, region.position.y), Vector2(leftover_right, region.size.y)))
            if leftover_above >= MIN_ROOM_DIMENSION:
                addition_queue.append(Rect2(region.position, Vector2(region.size.x, leftover_above)))
            if leftover_below >= MIN_ROOM_DIMENSION:
                addition_queue.append(Rect2(Vector2(region.position.x, region_to_remove.end.y + 1), Vector2(region.size.x, leftover_below)))

    for region in removal_queue:
        free_regions.erase(region)

    for region in addition_queue:
        free_regions.append(region)
 

func set_tile(x, y, type):
    map[x][y] = type
    tile_map.set_cell(x, y, type, false, false, false, _get_subtile_coord(type))
