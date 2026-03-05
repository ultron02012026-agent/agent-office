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
