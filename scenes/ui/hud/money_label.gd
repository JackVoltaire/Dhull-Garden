extends Label
## Shows how much money the player has.


func _ready() -> void:
	Inventory.changed.connect(_show_money)
	_show_money()


func _show_money() -> void:
	text = tr("UI_MONEY") % Inventory.money
