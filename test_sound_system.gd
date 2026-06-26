extends SceneTree

# 音效系统测试脚本
# 在 Godot 编辑器中运行此脚本进行测试

func _init():
	# 等待 SoundManager 初始化
	await get_tree().create_timer(0.1).timeout
	
	print("=== 音效系统测试 ===")
	
	# 测试 SFX 播放
	print("测试 SFX 播放...")
	SoundManager.play_sfx("ui_click_default")
	await get_tree().create_timer(0.5).timeout
	
	SoundManager.play_sfx_varied("ui_hover")
	await get_tree().create_timer(0.5).timeout
	
	# 测试 BGM 播放（应该会打印警告，因为 BGM 未添加）
	print("测试 BGM 播放（预期警告）...")
	SoundManager.play_bgm("bgm_menu")
	await get_tree().create_timer(1.0).timeout
	
	# 测试音效键检查
	print("检查音效键存在性...")
	print("ui_click_default 存在: ", SoundManager.has_sfx("ui_click_default"))
	print("bgm_menu 存在: ", SoundManager.has_bgm("bgm_menu"))
	
	print("=== 测试完成 ===")
	quit()
