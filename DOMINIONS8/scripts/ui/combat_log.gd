extends Control


@onready var label = %log_label

func _ready() -> void:
	visible = false

func log_message(message: String) -> void:
	label.append_text("\n" + message)

func log_attack(attacker, target, weapon, challenge: DRN.ChallengeResult) -> void:
	var message := "{} hits {} with {} for {} damage."
	var args = [
		attacker.object_name if attacker is BaseUnit else attacker,
		target.object_name if target is BaseUnit else target,
		weapon.object_name if "get_class" in weapon else weapon,
		challenge.result
	]
	log_message(message.format(args, "{}"))

# "Damage roll {atk}+{atk_drn} vs prot roll {def}+{def_drn} of {target} = {damage} damage"
