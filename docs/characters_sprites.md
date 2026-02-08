# 기사 스프라이트 시트 배치

## 현재 프로젝트에 들어간 시트

| 파일 | 용도 | 프레임 |
|------|------|--------|
| `player.png` | idle_down (정면 대기) | 1 |
| `player_walk_down.png` | walk_down (정면 걷기) | 4 (128×341) |
| `player_attack_down.png` | attack_down (정면 공격) | 1 |
| `player_walk_up.png` | walk_up (등 걷기) | 3 (170×341) |
| `player_idle_up_2f.png` | idle_up (등 대기) | 2 (256×341) |
| `player_idle_up.png` | idle_up 대체 | 1 (512×341) |
| `player_walk_side.png` | walk_side | 4 |
| `player_walk_left.png` | walk_left | 4 |
| `player_attack_up.png` | attack_up | 2 |

원본 합본: `knight_sheets_source.png`, `knight_down_up_source.png`.

---

## Godot 쪽 동작

- **PlayerFramesBuilder**: 위 파일이 있으면 자동 슬라이스 → idle/walk/attack (down, up, side).
- **플레이어**: 방향별로 walk_up, walk_down, walk_side, walk_left / idle_up, idle_down / attack_up, attack_down 사용.
