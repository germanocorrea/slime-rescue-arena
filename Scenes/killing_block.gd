extends RigidBody2D

func _ready() -> void:
	# Enable contact monitoring to receive body_entered signals
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Check if the colliding body is the CharacterBody2D or one of the softbody bones
	var character = null
	if body is CharacterBody2D:
		character = body
	elif body.name.begins_with("Bone"):
		# Bones are children of SoftBody2D, which is a sibling of CharacterBody2D under SlimeCharacter
		var parent = body.get_parent()
		if parent:
			var grandparent = parent.get_parent()
			if grandparent:
				character = grandparent.get_node_or_null("CharacterBody2D")
	
	if character and character.has_method("respawn"):
		character.respawn()
