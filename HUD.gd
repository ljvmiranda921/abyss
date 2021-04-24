extends CanvasLayer

onready var level = $Level
onready var hp = $HP
onready var dmg = $Damage
onready var lose = $LoseScreen

signal restart_game

func set_level(val):
    level.text =  "Act " + str(val+1)

func set_hp(current, total):
    hp.clear()
    if current <= total * 0.5:
        var fatal_color = Color("#e64e4b")
        hp.push_color(fatal_color)
    hp.add_text(str(current) + "/" + str(total) )

func set_dmg(val):
    dmg.text = str(val)

func _on_Button_pressed():
    emit_signal("restart_game")
