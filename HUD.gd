extends CanvasLayer

onready var level = $Level
onready var hp = $HP
onready var dmg = $Damage

func set_level(val):
    level.text =  "Level " + str(val+1)

func set_hp(val):
    hp.text = "HP " + str(val)
    # TODO: modulate red if less than 30

func set_dmg(val):
    dmg.text = "Dmg " + str(val)
