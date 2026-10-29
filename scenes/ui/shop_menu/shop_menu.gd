class_name ShopMenu
extends PanelContainer
## Pebble's shop: buy what he sells, or sell him what's in your pockets, one at a time.

var _player: Player
var _selling := false

@onready var _items: Container = %Items
@onready var _buy: Button = %Buy
@onready var _sell: Button = %Sell


func _ready() -> void:
	hide()
	_buy.pressed.connect(_show_list.bind(false))
	_sell.pressed.connect(_show_list.bind(true))
	%Close.pressed.connect(close)
	Inventory.changed.connect(_refresh)


func open(player: Player) -> void:
	_player = player
	_player.busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	_show_list(false)


func close() -> void:
	hide()
	_player.busy = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# _input rather than _unhandled_input, so cancelling closes the shop before the pause menu opens
# on the same key.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()


func _show_list(selling: bool) -> void:
	_selling = selling
	_buy.button_pressed = not selling
	_sell.button_pressed = selling
	_refresh()


func _refresh() -> void:
	if not visible:
		return
	for child in _items.get_children():
		child.queue_free()
	if _selling:
		_list_for_selling()
	else:
		_list_for_buying()


func _list_for_buying() -> void:
	var definitions: Array[ItemDefinition] = []
	definitions.assign(Inventory.definitions.values())
	for item in ShopTrade.stock(definitions):
		var button := Button.new()
		button.text = tr("UI_PRICE") % [tr(item.display_name), item.buy_price]
		button.disabled = Inventory.money < item.buy_price
		button.pressed.connect(ShopTrade.buy.bind(item, Inventory))
		_items.add_child(button)


func _list_for_selling() -> void:
	var held := Inventory.held()
	if held.is_empty():
		var nothing := Label.new()
		nothing.text = tr("UI_NOTHING_TO_SELL")
		_items.add_child(nothing)
	for item in held:
		var button := Button.new()
		button.text = (
			tr("UI_SELL_PRICE") % [tr(item.display_name), Inventory.count(item.id), item.sell_price]
		)
		button.pressed.connect(ShopTrade.sell.bind(item, Inventory))
		_items.add_child(button)
