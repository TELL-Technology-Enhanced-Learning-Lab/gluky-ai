extends StaticBody3D
class_name store_object

@onready var objects: Node3D = $Objects
@onready var object_places: Node3D = $ObjectPlaces

@onready var glycemic_popup := get_tree().root.get_node("/root/Node3D/CanvasLayer/GlycemicPopup")
@onready var glycemic_popup_cena := get_tree().root.get_node("/root/Node3D/Panel")
@onready var glycemic_popup_colazione := get_tree().root.get_node("/root/Node3D/PanelClz")

@onready var panda_anim: AnimationPlayer = get_tree().root.get_node_or_null("/root/Node3D/Panda/AnimationPlayer") #prendo il riferimento della scena istanziata del pandas

var hud
var itemsPlaced: Array = []


func _ready() -> void:
	hud = get_tree().root.get_node("Node3D/HUD")
	for i in range(object_places.get_child_count()):
		itemsPlaced.append(null)
	add_to_group("plate")
	
# GLICEMIA
func get_food_glycemic_load(cibo: Node) -> float:
	var gi = cibo.get("indice_glicemico")
	var carbs = cibo.get("carbs")

	if gi == null or carbs == null:
		push_warning("Il cibo '" + str(cibo.name) + "' non ha indice_glicemico o carbs.")
		return 0.0

	return (gi * carbs) / 100.0 #formula calcolo indice glicemico per ciascuno cibo 100 gr


func calculate_plate_ratio() -> float:
	var total_load := 0.0
	var count := 0

	for cibo in itemsPlaced:
		if cibo != null:
			total_load += get_food_glycemic_load(cibo)
			count += 1

	if count == 0:
		return 0.0

	return total_load / count

#range piatto perfetto(da rendere più flessibile)
func is_perfect_plate(ratio: float) -> bool: 
	return ratio >= 15.0 and ratio <= 30.0

#suggerimenti per formare un piatto perfetto
func get_balance_suggestion(ratio:float) -> String:
	if ratio == 0:
		return "Aggiungi almeno un alimento per iniziare!"#non si verifica mai
	if ratio < 5:
		return "Piatto troppo leggero: aggiungi almeno una fonte di carboidrati!"
	if ratio < 15:
		return "Indice glicemico troppo basso: aggiungi un alimento con IG medio(Frutta)!"

	return "Piatto critico! Rimuovi un alimento molto glicemico."

# SPIEGAZIONI NUTRIZIONALI
func get_nutritional_explanation() -> String:
	var text := ""

	for cibo in itemsPlaced:
		if cibo == null:
			continue

		var nome = cibo.get("food_category")	#ispector name
		var info = cibo.get("nutrizione_info")	#ispector name

		if nome != null and info != null and info != "":
			text += "• %s:\n%s\n\n" % [nome, info]
	return text.strip_edges()

#PUNTEGGIO
func point_PerfectPlate() -> void:
	if hud:
		hud.update_score(GameState.perfect_plates + 1)
	
	GameState.register_perfect_plate()

# ANIMAZIONI SAFE PER 3D
# Riduce la scala dell'oggetto fino a scomparire e quindi lo libera(visivamente e logicamente)
func fade_and_remove(obj: Node3D) -> void:
	if not obj:
		return
		
	# verifica della scala di partenza
	var start_scale := obj.scale if obj.has_method("scale") else Vector3.ONE
	var end_scale := start_scale * 0.2

	var tween := create_tween()
	tween.tween_property(obj, "scale", end_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# quando finisce l'animazione libero gli slot
	tween.tween_callback(func():
		if obj and obj.get_parent():
			obj.queue_free()
	)


# Pulsing rapido del nodo 'objects' per dare feedback di pulizia
func plate_flash() -> void:
	# se objects esiste
	if not objects:
		return

	var orig := objects.scale
	var up := orig * 1.05

	var tween := create_tween()
	tween.tween_property(objects, "scale", up, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(objects, "scale", orig, 0.18).set_delay(0.12).set_trans(Tween.TRANS_SINE)

# CLEAR PLATE
func clear_plate() -> void:
	# avvia animazioni di fade per ciascun oggetto e svuota l'array logicamente
	for i in range(itemsPlaced.size()):
		var f = itemsPlaced[i]
		if f != null:
			fade_and_remove(f)
			itemsPlaced[i] = null

	# aspetta un attimo (lascia finire le tween) e poi fai il flash del piatto
	await get_tree().create_timer(0.45).timeout
	plate_flash()

# AGGIUNTA DEL CIBO
func add_object(object: Node3D) -> bool:
	# se non ci sono slot liberi
	if not itemsPlaced.has(null):
		return false

	# rimuovi dall'attuale parent e aggiungi sotto 'objects' container
	if object.get_parent():
		object.get_parent().remove_child(object)
	objects.add_child(object)

	# trova primo slot libero
	for i in range(itemsPlaced.size()):
		if itemsPlaced[i] == null:

			var slot_node = object_places.get_child(i)

			# disattivo fisica e collisione 
			if object is StaticBody3D:
				object.set_physics_process(false)

			var col := object.get_node_or_null("CollisionShape3D")
			if col:
				col.disabled = true

			# posiziona correttamente
			object.global_transform = slot_node.global_transform
			itemsPlaced[i] = object

			# se tutti e 3 gli slot sono pieni -> valuta il piatto
			if not itemsPlaced.has(null):
				print("cibi inseriti!") #debug
				var ratio := calculate_plate_ratio()
				var spiegazione := get_nutritional_explanation()
				
				if is_perfect_plate(ratio):
					
					if glycemic_popup: #popup pranzo
						glycemic_popup.show_popup("Piatto perfetto! Ottimo bilanciamento!\n\n" + spiegazione, ratio)
						
					if glycemic_popup_cena: #popup cena
						glycemic_popup_cena.show_popup("Piatto perfetto! Ottimo bilanciamento!\n\n" + spiegazione, ratio)
						
					if glycemic_popup_colazione:#popup colazione
						glycemic_popup_colazione.show_popup("Piatto perfetto! Ottimo bilanciamento!\n\n" + spiegazione, ratio)
					
					point_PerfectPlate() #richiama le due funzione piatto perfetto e pulisci piatto.
					clear_plate()
					
					if panda_anim:
						panda_anim.stop()
						panda_anim.play("Yes")
				else:
					if panda_anim:
						panda_anim.stop()
						panda_anim.play("No")
						
					var suggerimento := get_balance_suggestion(ratio)
					if glycemic_popup: #popup pranzo
						glycemic_popup.show_popup(suggerimento + "\n\n" + spiegazione, ratio)
						
					if glycemic_popup_cena:# popup cena
						glycemic_popup_cena.show_popup(suggerimento + "\n\n" + spiegazione, ratio)
					
					if glycemic_popup_colazione:# popup cena
						glycemic_popup_colazione.show_popup(suggerimento + "\n\n" + spiegazione, ratio)

			return true
			
	return false
	
#RIMOZIONE OGGETTO DAL PIATTO, collegato col segnale
func _on_objects_child_exiting_tree(node: Node) -> void:
	var idx := itemsPlaced.find(node)
	if idx != -1:
		itemsPlaced[idx] = null
