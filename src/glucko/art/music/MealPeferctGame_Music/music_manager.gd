extends Node
#classe autoload che gestisce la musica nel gioco, gestita come autolad per non avere interruzioni.
@onready var music := $Music

func play_music(): #autoplay gestito via codice
	if not music.playing:
		music.play()

func fade_out(duration := 0.6):
	var tween = create_tween()
	tween.tween_property(music, "volume_db", -20, duration)

func fade_in(duration := 0.6):
	music.volume_db = -40
	music.play()
	var tween = create_tween()
	tween.tween_property(music, "volume_db", -6, duration)
