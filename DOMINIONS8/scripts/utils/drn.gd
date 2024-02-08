class_name DRN extends RefCounted

## Rolls 2d6 DRN
static func roll() -> int:
	return _roll_d6_drn() + _roll_d6_drn()

## Rolls two values with DRN bonuses against each other returning the difference
static func roll_vs(a: int, b: int) -> int:
	return (a + roll()) - (b + roll())

static func _roll_d6_drn() -> int:
	var result: int = randi_range(1, 6)
	if result == 6:
		result -= 1
		result += _roll_d6_drn()
	return result

## Like roll_vs, but returns a ChallengeResult with the full data of the roll.
static func challenge(attack: int, defense: int) -> ChallengeResult:
	return ChallengeResult.new(attack, roll(), defense, roll())


class ChallengeResult extends RefCounted:
	## The attacking value.
	var attack: int
	## The DRN bonus to attack.
	var attack_drn: int
	## The defending value.
	var defense: int
	## The DRN bonus to defense.
	var defense_drn: int
	## The raw difference in rolls.  Can be less than zero.
	var difference: int
	## The difference or 0, whichever is greater.
	var result: int

	func _init(atk: int = 0, atk_drn: int = 0, def: int = 0, def_drn: int = 0) -> void:
		attack = atk
		attack_drn = atk_drn
		defense = def
		defense_drn = def_drn
		difference = (atk + atk_drn) - (def + def_drn)
		result = max(0, difference)
