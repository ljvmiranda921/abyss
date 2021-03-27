extends CanvasLayer

onready var level = $Level
onready var hp = $HP
onready var dmg = $Damage

func set_level(val):
    level.text =  "Level " + str(val+1)

func set_hp(val):
    hp.clear()
    if val <= 50:
        var fatal_color = Color("#e64e4b")
        hp.push_color(fatal_color)
    hp.add_text("HP " + str(val))

func set_dmg(val):
    dmg.text = "Dmg " + str(val)
