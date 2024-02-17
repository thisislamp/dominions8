extends GameMap

@onready var player_nexus = $PlayerNexus
@onready var enemy_nexus = $EnemyNexus

#func _ready() -> void:
	#super()
#

func _unhandled_key_input(event: InputEvent) -> void:
	super(event)

	if not event is InputEventKey:
		return
	event = event as InputEventKey
	if not event.pressed:
		return

	match event.keycode:
		KEY_1:
			player_nexus.spawn_unit(preload("res://scenes/unit/hurler.tscn"), $PlayerNexus/spawn_top)

		KEY_2:
			player_nexus.spawn_unit(preload("res://scenes/unit/hurler.tscn"), $PlayerNexus/spawn_mid)

		KEY_3:
			player_nexus.spawn_unit(preload("res://scenes/unit/hurler.tscn"), $PlayerNexus/spawn_bot)

		KEY_4:
			enemy_nexus.spawn_unit(preload("res://scenes/unit/test_mage.tscn"), $EnemyNexus/spawn_top)

		KEY_5:
			enemy_nexus.spawn_unit(preload("res://scenes/unit/test_mage.tscn"), $EnemyNexus/spawn_mid)

		KEY_6:
			enemy_nexus.spawn_unit(preload("res://scenes/unit/test_mage.tscn"), $EnemyNexus/spawn_bot)
