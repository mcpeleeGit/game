extends Node
## Autoload: 전역 게임 상태

var language: String = "ko"
var current_region_id: String = ""
var player_hp: int = 100
var player_max_hp: int = 100
var gold: int = 0
## 세션 단위 1회 (앱 종료 시 리셋). 세이브 붙이면 SaveData로 옮기면 됨.
var world_map_first_click_done: bool = false
## 첫 전투(튜토리얼) 완료 후부터 랜덤 인카운터/자유 전투
var first_battle_done: bool = false
## 지금 들어온 전투가 첫 전투인지 (지역에서 true로 세팅 후 배틀 씬으로)
var is_first_battle: bool = false
## 숲 1회 클리어 여부 (월드맵/다음 지역 연출용)
var forest_cleared_once: bool = false
## 유적 1회 클리어 여부 (월드맵 클리어 표시용)
var ruins_cleared_once: bool = false
## 월드맵 떠날 때 골드 (복귀 시 증가 애니용, -1이면 미설정)
var world_map_last_gold: int = -1
## 유적 보상 아이템 (나중에 상점/강화 연동)
var ancient_fragments: int = 0
## 캐릭터 위 HP 게이지 표시 (옵션, 기본 ON)
var show_hp_gauge: bool = true
## 인벤토리: 아이템 ID → 개수 (상점 구매/사용 반영)
var inventory: Dictionary = {}
## 선술집 2048에서 2048점 달성 시 1회만 적용되는 업그레이드
var tavern_2048_upgraded: bool = false

## 새 게임 시작 시 상태 초기화 (타이틀에서 "시작" 선택 시 호출)
func reset_to_new_game() -> void:
	language = "ko"
	current_region_id = ""
	player_hp = 100
	player_max_hp = 100
	gold = 0
	world_map_first_click_done = false
	first_battle_done = false
	is_first_battle = false
	forest_cleared_once = false
	ruins_cleared_once = false
	world_map_last_gold = -1
	ancient_fragments = 0
	inventory = {}
	tavern_2048_upgraded = false

# ====================== 직렬화 (세이브/로드) ======================
func to_dict() -> Dictionary:
	return {
		"language": language,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"gold": gold,
		"current_region_id": current_region_id,
		"world_map_first_click_done": world_map_first_click_done,
		"first_battle_done": first_battle_done,
		"forest_cleared_once": forest_cleared_once,
		"ruins_cleared_once": ruins_cleared_once,
		"ancient_fragments": ancient_fragments,
		"show_hp_gauge": show_hp_gauge,
		"inventory": inventory.duplicate(),
		"tavern_2048_upgraded": tavern_2048_upgraded,
	}

func from_dict(data: Dictionary) -> void:
	language = data.get("language", "ko")
	player_hp = data.get("player_hp", 100)
	player_max_hp = data.get("player_max_hp", 100)
	gold = data.get("gold", 0)
	current_region_id = data.get("current_region_id", "")
	world_map_first_click_done = data.get("world_map_first_click_done", false)
	first_battle_done = data.get("first_battle_done", false)
	forest_cleared_once = data.get("forest_cleared_once", false)
	ruins_cleared_once = data.get("ruins_cleared_once", false)
	ancient_fragments = data.get("ancient_fragments", 0)
	show_hp_gauge = data.get("show_hp_gauge", true)
	inventory = data.get("inventory", {})
	tavern_2048_upgraded = data.get("tavern_2048_upgraded", false)