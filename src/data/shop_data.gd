class_name ShopData
extends RefCounted
## 상점 상품 정의 (아이템 ID → name_key, desc_key, price)

const ITEMS: Dictionary = {
	"potion_small": {
		"name_key": "ITEM_POTION_SMALL",
		"desc_key": "ITEM_POTION_SMALL_DESC",
		"price": 20,
	},
	"potion_medium": {
		"name_key": "ITEM_POTION_MEDIUM",
		"desc_key": "ITEM_POTION_MEDIUM_DESC",
		"price": 50,
	},
	"antidote": {
		"name_key": "ITEM_ANTIDOTE",
		"desc_key": "ITEM_ANTIDOTE_DESC",
		"price": 30,
	},
}

static func list_ids() -> Array:
	return ITEMS.keys()


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})
