class_name RegionData
extends RefCounted
## 지역 카드/씬 데이터 (region_id → name, level, flavor, scene_path)
## 확장: 월드맵 핫스팟 추가 시 여기만 추가하면 카드·전환 자동 적용

const REGIONS: Dictionary = {
	"forest": {
		"name": "FOREST",
		"level": 1,
		"flavor": "발견: 고블린 흔적",
		"scene": "res://src/regions/region_forest.tscn",
		"toast": "숲으로 이동합니다",
	},
	"ruins": {
		"name": "RUINS",
		"level": 3,
		"flavor": "고대 유적이 남아 있다",
		"scene": "res://src/regions/region_forest.tscn",
		"toast": "유적으로 이동합니다",
	},
	"volcano": {
		"name": "VOLCANO",
		"level": 6,
		"flavor": "보스: 화산의 드래곤",
		"scene": "res://src/regions/region_forest.tscn",
		"toast": "화산으로 이동합니다",
	},
}

static func get_region(region_id: String) -> Dictionary:
	return REGIONS.get(region_id, {})

static func has_region(region_id: String) -> bool:
	return region_id in REGIONS

static func get_scene_path(region_id: String) -> String:
	var r: Dictionary = get_region(region_id)
	return r.get("scene", "")
