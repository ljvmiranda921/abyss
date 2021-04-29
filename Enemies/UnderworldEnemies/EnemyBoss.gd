extends AnimatedSprite

onready var los_effect = $LOSEffect
onready var slash_effect = $SlashEffect

func _on_AnimatedSprite_animation_finished():
    if self.animation != "default" && self.animation != "death" && self.animation != "walk":
        self.play("default")
        self.set_offset(Vector2(0,0))
        self.z_index = 0
