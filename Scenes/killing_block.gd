extends RigidBody2D

func _ready() -> void:
	# Enable contact monitoring to receive body_entered signals
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	var atual = body

	while atual:
		if atual is CharacterBody2D:
			if atual.has_method("respawn"):
				atual.respawn()
			return

		atual = atual.get_parent()
