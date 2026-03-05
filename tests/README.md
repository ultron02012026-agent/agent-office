# tests/

## Running Tests
```bash
godot --headless --script tests/run_tests.gd
```
Exits with code 0 on success, 1 on failure.

## Test Files
| File | What it tests |
|------|---------------|
| `test_chat_ui.gd` | Empty message rejection, thinking state blocking, BBCode formatting, show/hide/clear |
| `test_room_area.gd` | Room name propagation, enter/exit state, wrong-room exit safety |
| `test_player.gd` | Camera pitch clamping, room state tracking, HUD location text (lobby vs hallway vs room) |
| `test_settings.gd` | Default values, ConfigFile save/load roundtrip, agent config editing |

## Adding a Test
1. Create `test_xxx.gd` extending `Node`
2. Implement `run() -> Dictionary` returning `{"passed": int, "failed": int}`
3. Use `_assert(condition, name)` pattern (see existing tests)
4. Add entry to `test_files` array in `run_tests.gd`

## Notes
Tests are logic-only (no scene instantiation). They test algorithms, state machines, and data flow in isolation.
