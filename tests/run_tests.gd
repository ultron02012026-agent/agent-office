extends SceneTree

# Test runner — execute via: godot --headless --script tests/run_tests.gd

func _init():
	print("\n🧪 Agent Office Test Suite\n" + "=".repeat(40))
	
	var total_passed := 0
	var total_failed := 0
	
	var test_files = [
		["ChatUI", "res://tests/test_chat_ui.gd"],
		["RoomArea", "res://tests/test_room_area.gd"],
		["Player", "res://tests/test_player.gd"],
		["Settings", "res://tests/test_settings.gd"],
		["WelcomeOverlay", "res://tests/test_welcome_overlay.gd"],
		["Polish", "res://tests/test_polish.gd"],
		["VoiceChat", "res://tests/test_voice_chat.gd"],
		["SettingsMenu", "res://tests/test_settings_menu.gd"],
		["AgentAvatar", "res://tests/test_agent_avatar.gd"],
		["MinimapExtended", "res://tests/test_minimap_extended.gd"],
		["ProximityPrompt", "res://tests/test_proximity_prompt.gd"],
		["DayCycle", "res://tests/test_day_cycle.gd"],
		["Notification", "res://tests/test_notification.gd"],
		["DoorAnim", "res://tests/test_door_anim.gd"],
		["Immersion", "res://tests/test_immersion.gd"],
		["AgentSocial", "res://tests/test_agent_social.gd"],
		["CommandPalette", "res://tests/test_command_palette.gd"],
		["BulletinBoard", "res://tests/test_bulletin_board.gd"],
		["SprintTimer", "res://tests/test_sprint_timer.gd"],
		["Ambiance", "res://tests/test_ambiance.gd"],
		["Screenshot", "res://tests/test_screenshot.gd"],
		["DebugOverlay", "res://tests/test_debug_overlay.gd"],
	]
	
	for entry in test_files:
		var suite_name = entry[0]
		var script_path = entry[1]
		
		print("\n📋 " + suite_name)
		print("-".repeat(30))
		
		var script = load(script_path)
		if not script:
			print("  ❌ Could not load " + script_path)
			total_failed += 1
			continue
		
		var instance = Node.new()
		instance.set_script(script)
		root.add_child(instance)
		
		if instance.has_method("run"):
			var result = instance.run()
			total_passed += result.get("passed", 0)
			total_failed += result.get("failed", 0)
		else:
			print("  ❌ No run() method in " + script_path)
			total_failed += 1
		
		instance.queue_free()
	
	print("\n" + "=".repeat(40))
	print("📊 Results: %d passed, %d failed" % [total_passed, total_failed])
	
	if total_failed > 0:
		print("❌ SOME TESTS FAILED")
		quit(1)
	else:
		print("✅ ALL TESTS PASSED")
		quit(0)
