# 이미지 역할 정리

## 1️⃣ 픽셀 기사 캐릭터 이미지 → 플레이어 / 전투 캐릭터

| 항목 | 내용 |
|------|------|
| **용도** | 지역 씬에서 플레이어, 전투 씬에서 아군 캐릭터 |
| **스타일** | 픽셀 + 캐릭터 중심 → 조작감/게임성 담당 |
| **위치** | `assets/images/characters/player.png` |
| **Godot** | `Sprite2D` 또는 `AnimatedSprite2D` (걷기/공격 프레임 확장 가능) |

```gdscript
# 플레이어 Sprite2D
texture = load("res://assets/images/characters/player.png")
```

---

## 2️⃣ 4분할 판타지 일러스트 세트 → 월드관 / 배경 / 연출용

**캐릭터 스프라이트가 아니라** Sprite2D 배경 / UI 배경 / 컷신용.

| 파일 | 용도 |
|------|------|
| `world_forest.png` | 지역(FOREST) 배경 |
| `world_desert.png` | 다음 지역(DESERT) |
| `battle_forest.png` | 전투 씬 배경 |
| `battle_boss.png` | 보스/스토리 연출 |

**위치:** `assets/images/backgrounds/`

```gdscript
# 전투 배경 Sprite2D
texture = load("res://assets/images/backgrounds/battle_forest.png")
z_index = -10
```

---

## 왜 이 조합이 좋은가

- **플레이 조작** → 픽셀 캐릭터 (명확, 가독성)
- **몰입/세계관** → 고퀄 일러스트 (RPG 감성)
- Octopath / Sea of Stars / 모바일 RPG에서 많이 쓰는 구조.

---

## 3️⃣ 픽셀 아트 애니메이션 (Idle / Walk / Attack)

**규격:** 프레임 64×64, 방향 Down 1종.

| 애니메이션 | 프레임 | 파일 (1행 N열) | FPS |
|-----------|--------|----------------|-----|
| idle_down | 1 | `player.png` | 5 |
| walk_down | 4 | `player_walk_down.png` (1×4) | 9 |
| attack_down | 3 | `player_attack_down.png` (1×3) | 11 |

**위치:** `assets/images/characters/`

- `player.png` 없으면 애니가 비어 있고, 있으면 walk/attack 시트가 없을 때 idle로 폴백.

### (중요) Godot 픽셀 아트 Import

캐릭터 이미지 선택 → **Import** 탭에서:

- **Filter:** Off  
- **Mipmaps:** Off  
- **Compression:** Lossless(또는 기본)

그다음 **Reimport**. 이렇게 해야 픽셀이 흐리지 않음.

### 스프라이트 시트 생성 프롬프트 예시

- **걷기 4프레임 (1×4):**  
  "Pixel art sprite sheet, transparent background. Chibi knight, red hair, blue-silver armor, shield and sword. 1-row 4-column, each frame 64x64. Walking down (toward camera). Clean pixel art, no blur, no text, centered in each frame."
- **공격 3프레임 (1×3):**  
  "Pixel art sprite sheet, transparent background. Same knight. 1-row 3-column, 64x64 each. Sword attack down: wind-up, strike, recover. No blur, no text, centered."

---

## 다음 단계 (선택)

1. **4방향 확장** – Up/Down/Left/Right 걷기·공격 시트 + 시트 규격/자동 슬라이스
2. **월드맵에 일러스트 연결** – 숲/사막 클릭 시 해당 배경
3. **전투 연출 강화** – 데미지 숫자, 화면 흔들림
