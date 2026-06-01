extends RigidBody2D

func _ready() -> void:
	# Enable contact monitoring to receive body_entered signals
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Only trigger respawn if the colliding body is the main CharacterBody2D itself, not the softbody bones
	var character = body as CharacterBody2D
	if character and character.has_method("respawn"):
		character.respawn()
