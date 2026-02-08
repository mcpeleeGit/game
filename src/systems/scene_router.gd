extends Node
## Autoload: 씬 전환 유틸

func goto(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)
