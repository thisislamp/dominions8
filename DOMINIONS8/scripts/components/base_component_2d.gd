#@icon()  # TODO: make the icon a cog or something
class_name BaseComponent extends Node

var unit: BaseUnit:
	get: return get_parent()
