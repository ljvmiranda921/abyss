extends Camera2D


func small_shake() -> void:
    $ScreenShake.start(0.1, 15, 4, 0)
