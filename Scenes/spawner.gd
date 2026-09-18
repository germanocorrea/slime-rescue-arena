extends Node2D

#@export var slime_scene : PackedScene
var slime_scene = preload("res://Scenes/MiniSlime.tscn")

var slime_instance = null

func _ready():
	# Quem decide quando e onde nascem minislimes é o SpawnManager
	add_to_group("spawners")

func spawn_slime():
	print("Tentando spawnar")

	if slime_instance == null:
		print("Criando slime")
		slime_instance = slime_scene.instantiate()
		#slime_instance.global_position = global_position
		slime_instance.global_position = Vector2(0,0)
		slime_instance.spawner = self
		add_child(slime_instance)
		print(slime_instance)
		print("Slime criado")

func esta_livre() -> bool:
	return not is_instance_valid(slime_instance)

func slime_coletado():
	slime_instance = null
	get_tree().call_group("spawn_manager", "vaga_liberada", self)

#func esperar_area_livre():
	#while true:
		#await get_tree().create_timer(0.5).timeout
#
		#if $Area2D.get_overlapping_bodies().size() == 0:
			#spawn_slime()
			#break
			


func _on_camera_2d_ready() -> void:
	pass # Replace with function body.
