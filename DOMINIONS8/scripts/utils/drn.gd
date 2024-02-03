class_name DRN extends Object

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
