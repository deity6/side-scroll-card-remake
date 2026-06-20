extends Node
## 设置管理器
## 管理全局设置（音量、语言等），支持 JSON 持久化

signal settings_changed

var settings_path := "user://settings.json"

var defaults := {
	"master_volume": 100,
	"sfx_volume": 100,
	"bgm_volume": 100,
	"language": "zh"
}

var current := {}

func _ready() -> void:
	reload()

## 从文件加载设置，文件不存在时使用默认值
func reload() -> void:
	current = defaults.duplicate(true)
	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file:
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		file.close()
		if err == OK and json.data is Dictionary:
			for k in json.data:
				current[k] = json.data[k]
	apply_settings()

## 将当前设置保存到文件
func save() -> void:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(current, "  "))
	file.close()

## 应用当前设置到 AudioServer
func apply_settings() -> void:
	var master := clampi(int(current.get("master_volume", 100)), 0, 100)
	var sfx := clampi(int(current.get("sfx_volume", 100)), 0, 100)
	var bgm := clampi(int(current.get("bgm_volume", 100)), 0, 100)
	var master_linear := master / 100.0
	var sfx_linear := sfx / 100.0
	var bgm_linear := bgm / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_linear))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_linear))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(bgm_linear))
	settings_changed.emit()

## 设置单个配置项并自动保存
func set_setting(key: String, value) -> void:
	current[key] = value
	apply_settings()
	save()

## 获取单个配置项
func get_setting(key: String, default_value = null):
	return current.get(key, default_value)
