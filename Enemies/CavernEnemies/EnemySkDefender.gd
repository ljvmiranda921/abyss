extends AnimatedSprite

onready var los_effect = $LOSEffect

func _on_AnimatedSprite_animation_finished():
    if self.animation != "default" && self.animation != "death" && self.animation != "defend":
        self.play("default")
        self.set_offset(Vector2(0,0))
        self.z_index = 0
