# scenes/

## main.tscn
Root scene. Contains the entire office environment.

### Node tree structure:
```
Main (Node3D)
├── DirectionalLight3D
├── Floor, Ceiling (CSGBox3D, collision)
├── HallWall[Left|Right]_[N|M|S] (CSGBox3D walls with doorway gaps)
├── HallWallEnd_N (north end wall)
├── Lobby_* (sign, walls, light)
├── Room[1-4]_* (per room: BackWall, FrontWall, SideWall, Desk, Chair1, Chair2, Whiteboard, TV_Main, TV_Secondary, Label, Light)
├── Room[1-4]_Area (Area3D → room_area.gd, room_name export)
├── [Agent]_Avatar (MeshInstance3D → agent_avatar.gd)
├── [Agent]_TTSPlayer (AudioStreamPlayer3D, max_distance=15)
├── Room[1-4]_DoorLabel (Label3D above doorways)
├── Player (instance of player.tscn, spawns at z=10 in lobby)
├── HUD (CanvasLayer layer=10)
│   ├── RoomHUD (Label)
│   └── MicIndicator (Label, hidden by default)
├── ChatUI (CanvasLayer → chat_ui.gd)
│   ├── Panel/VBoxContainer/RoomLabel, ChatLog, HBoxContainer/LineEdit+SendButton
│   └── HTTPRequest
├── VoiceChat (Node → voice_chat.gd)
└── SettingsMenu (CanvasLayer layer=20, process_mode=3 ALWAYS → works when paused)
```

### Room mapping:
| Room | Agent | Side | Z-center | Color |
|------|-------|------|----------|-------|
| 1 | Ultron | Left (x=-6) | -8 | Blue |
| 2 | Spinfluencer | Left (x=-6) | 0 | Pink |
| 3 | Dexer | Right (x=6) | -8 | Green |
| 4 | Architect | Right (x=6) | 0 | Gold |

## player.tscn
```
Player (CharacterBody3D → player.gd)
├── CollisionShape3D (CapsuleShape3D r=0.35 h=1.8)
├── MeshInstance3D (CapsuleMesh, blue)
└── CameraPivot (Node3D, y=1.6)
    └── Camera3D
```
