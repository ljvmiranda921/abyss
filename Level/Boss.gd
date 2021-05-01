extends Node2D

# Node references
onready var tile_map = $TileMap
onready var visibility_map = $VisibilityMap
onready var poof_effect = $PoofEffect
onready var cast_effect = $CastEffect

onready var statue1 = $StatueEffects/StatuePoof1
onready var statue2 = $StatueEffects/StatuePoof2
onready var statue3 = $StatueEffects/StatuePoof3
onready var statue4 = $StatueEffects/StatuePoof4

onready var statue_poof = [statue1, statue2, statue3, statue4]
