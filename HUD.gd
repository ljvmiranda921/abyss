extends CanvasLayer

onready var level = $InfoBox/Level
onready var hp = $InfoBox/HP
onready var dmg = $InfoBox/Damage
onready var lose = $Screens/LoseScreen
onready var transition = $Screens/SceneTransitionRect
onready var transition_player = $Screens/SceneTransitionRect/AnimationPlayer

signal restart_game

func _input(event):
    if event is InputEventKey && lose.visible:
        if event.pressed:
            emit_signal("restart_game")

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

func play_fade_in():
    transition_player.play("Fade")
    yield(transition_player, "animation_finished")
    transition_player.play_backwards("Fade")
    # yield(transition_player, "animation_finished")
