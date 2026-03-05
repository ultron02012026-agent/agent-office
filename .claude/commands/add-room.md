# Add a New Room

## Steps

1. **main.tscn** — Add room geometry (copy Room4 pattern):
   - `Room5_BackWall`, `Room5_FrontWall`, `Room5_SideWall` (CSGBox3D, `use_collision=true`, wall_mat)
   - `Room5_Desk`, `Room5_Chair1`, `Room5_Chair2` (CSGBox3D with desk_mat/chair_mat)
   - `Room5_Whiteboard`, `Room5_WhiteboardLabel` (CSGBox3D + Label3D)
   - `Room5_TV_Main`, `Room5_TV_Secondary` (CSGBox3D, screen_mat)
   - `Room5_Label` (Label3D with agent name, colored)
   - `Room5_Light` (OmniLight3D, colored, energy=0.5, range=6)

2. **main.tscn** — Add room trigger:
   - `Room5_Area` (Area3D, script=room_area.gd, `room_name="AgentName"`)
   - `Room5_AreaShape` (CollisionShape3D, BoxShape3D size=6,4,6)
   - Connect `body_entered` and `body_exited` signals to itself

3. **main.tscn** — Add avatar + TTS:
   - `AgentName_Avatar` (MeshInstance3D, avatar_mesh, new colored material, script=agent_avatar.gd, `room_name="AgentName"`)
   - `AgentName_TTSPlayer` (AudioStreamPlayer3D at desk position, max_distance=15)

4. **main.tscn** — Add door label:
   - `Room5_DoorLabel` (Label3D at hallway wall gap, colored)

5. **main.tscn** — Cut doorway in hallway wall (add gap in wall segments)

6. **settings_manager.gd** — Add to `agent_configs` default:
   ```gdscript
   "AgentName": {"agent_name": "AgentName", "system_prompt": "You are AgentName, an AI agent."},
   ```

7. **Test** — Walk into the room, verify chat opens and API responds.
