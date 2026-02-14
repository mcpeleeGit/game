# 나무성 이미지 생성 프롬프트 (ChatGPT / DALL·E)

아래 프롬프트를 ChatGPT 이미지 생성 또는 DALL·E에 입력하여 각 이미지를 생성한 뒤,  
해당 PNG 파일을 교체하면 됩니다.

---

## 1. tree_castle_intro.png  
**경로:** `assets/images/backgrounds/tree_castle_intro.png`  
**권장 크기:** 1280×720 px (또는 16:9 비율)

```
Fantasy RPG game background: A magical tree castle in the heart of an ancient forest. The castle is built around and inside giant intertwined trees, with wooden fortifications, moss-covered walls, and soft golden light filtering through the canopy. Peaceful, mystical atmosphere. Isometric or side-view perspective, suitable for a game hub screen. Soft, painterly art style, warm green and brown tones.
```

**한국어 버전:**
```
판타지 RPG 게임 배경: 고대 숲 한가운데 있는 마법의 나무성. 거대한 나무들이 뒤얽혀 만들어낸 성채, 나무 성벽, 이끼 낀 벽, 나뭇잎 사이로 비치는 부드러운 황금빛. 평화롭고 신비로운 분위기. 게임 허브 화면에 어울리는 아이소메트릭 또는 측면 뷰. 부드러운 회화풍, 따뜻한 녹색·갈색 톤.
```

---

## 2. tree_castle_td_bg.png  
**경로:** `assets/images/backgrounds/tree_castle_td_bg.png`  
**권장 크기:** 600×380 px (또는 16:10 비율)

```
Tower defense game map background: A forest path winding through ancient trees. Top-down or slightly angled view. Dirt path with grass borders, mossy stones, roots. Dark green forest floor, atmospheric lighting. Clear path for enemies to walk. Clean, readable design for a strategy game. Pixel art or low-poly style.
```

**한국어 버전:**
```
타워 디펜스 게임 맵 배경: 고대 나무 사이로 구불구불 이어진 숲길. 탑다운 또는 약간 각도가 잡힌 시점. 흙길과 풀 경계, 이끼 낀 돌, 뿌리. 어두운 녹색 숲 바닥, 분위기 있는 조명. 적이 걸을 경로가 분명한 구성. 전략 게임용으로 읽기 쉬운 디자인. 픽셀아트 또는 로우폴리 스타일.
```

---

## 3. tower_archer.png  
**경로:** `assets/images/tower_defense/tower_archer.png`  
**권장 크기:** 64×64 px 또는 128×128 px (정사각형)

```
Game icon, archer tower: A small wooden watchtower with a bow and arrow theme. Simple top-down or isometric view. Greenish brown wood, small roof, arrow notch. Cute, clean icon style for a tower defense game. Transparent or solid background.
```

**한국어 버전:**
```
게임 아이콘, 화살 탑: 활과 화살 테마의 작은 나무 망루. 심플한 탑다운 또는 아이소메트릭 뷰. 녹갈색 나무, 작은 지붕, 화살 노치. 타워 디펜스용 귀엽고 깔끔한 아이콘 스타일. 투명 또는 단색 배경.
```

---

## 4. tower_cannon.png  
**경로:** `assets/images/tower_defense/tower_cannon.png`  
**권장 크기:** 64×64 px 또는 128×128 px (정사각형)

```
Game icon, cannon tower: A small wooden cannon turret. Barrel pointed forward, stone or wood base. Brown and gray tones. Simple top-down or isometric view. Clear silhouette for a tower defense game icon. Cute, readable design.
```

**한국어 버전:**
```
게임 아이콘, 대포 탑: 작은 나무 대포 포대. 통통한 포신, 돌이나 나무 기단. 갈색·회색 톤. 심플한 탑다운 또는 아이소메트릭 뷰. 타워 디펜스 아이콘으로 읽기 쉬운 실루엣. 귀엽고 명확한 디자인.
```

---

## 5. tower_slow.png  
**경로:** `assets/images/tower_defense/tower_slow.png`  
**권장 크기:** 64×64 px 또는 128×128 px (정사각형)

```
Game icon, slow/freeze tower: A magical crystal or ice tower. Blue and light blue tones. Sparkles or frost effect. Simple top-down or isometric view. Conveys "slow" or "freeze" ability. Clean icon for a tower defense game.
```

**한국어 버전:**
```
게임 아이콘, 둔화/빙결 탑: 마법의 수정 또는 얼음 탑. 파란색·하늘색 톤. 반짝임 또는 서리 효과. 심플한 탑다운 또는 아이소메트릭 뷰. "둔화" 또는 "빙결" 능력을 연상시키는 디자인. 타워 디펜스용 깔끔한 아이콘.
```

---

## 사용 방법

1. ChatGPT 또는 DALL·E에서 위 프롬프트로 이미지 생성
2. PNG로 저장 (투명 배경이 필요하면 PNG 선택)
3. 해당 경로의 placeholder 파일을 생성된 이미지로 교체
4. Godot에서 프로젝트를 다시 열거나 `Project > Reload Current Project` 실행

## 코드 반영 (선택)

- **tree_castle_intro.png**: `region_tree_castle.gd`의 `BG_PATH`를  
  `res://assets/images/backgrounds/tree_castle_intro.png`로 변경하면 사용됩니다.
- **tower_archer/cannon/slow**: `tree_castle_td.gd`에서 ColorRect 대신 TextureRect로 타워를 그리도록 수정하면 적용됩니다.
- **tree_castle_td_bg**: TD `GameArea`에 배경 텍스처를 넣도록 코드 수정 후 적용할 수 있습니다.
