# 트러블슈팅: 화면에 아무것도 안 보일 때

골격만 있을 때는 UI(Label/Button)만 있어서 글자+버튼만 보이는 게 자연스럽다.  
**완전 검은 화면**이면 아래를 순서대로 확인하자.

---

## 1) 씬에 그려질 노드가 있는지

**전투 씬(battle.tscn)**  
- 루트가 `Control`이면 Label/Button이 있으면 **반드시** 보여야 정상.
- 안 보이면: CanvasLayer/Control **앵커**(화면 밖), **테마/폰트 색**이 배경과 동일(검정 위 검정), **해상도/스케일** 문제 가능.

**확인:** Godot 에디터에서 `battle.tscn` 열고 **2D** 뷰에서 Label이 **파란 박스(뷰포트)** 안에 있는지 확인.

---

## 2) 이미지(맵/플레이어/적)는 직접 지정해야 함

**월드맵(world_map.tscn)**  
- `Sprite2D` (MapSprite)를 만들어도 **Texture가 비어 있으면** 아무것도 안 나온다.
- **해결:** `assets/`에 PNG 넣기 → MapSprite 선택 → Inspector → **Texture**에 그 PNG 드래그/선택.

---

## 3) Sprite2D 위치/스케일/카메라

- `Node2D`는 카메라 없이 **(0,0)이 화면 중심**.
- MapSprite가 너무 멀리 있으면 화면 밖, 너무 크면 일부만 보이거나 위치가 애매함.
- **해결:** `MapSprite.position = Vector2(0,0)`, `centered = true`. 필요하면 **Camera2D** 추가 후 **Current** 체크.

---

## 4) PNG 임포트

- 임포트가 꼬이면 투명처럼 보일 수 있음.
- **해결:** 파일 선택 → **Import** 탭 → **Reimport**. Filter/Mipmaps는 일단 기본값.

---

## 5) 테스트용 코드 (경로 확인)

월드맵에서 텍스처/경로 확인용:

```gdscript
func _ready():
	$MapSprite.texture = load("res://assets/world_map.png")
```

에러 나면 **경로/파일명**이 틀렸거나, **프로젝트에 해당 파일이 없는 것**.

---

## 요약

| 증상 | 확인할 것 |
|------|-----------|
| 완전 검은 화면 | Control/Label/Button 앵커·색상, 배경 ColorRect |
| 맵 이미지 안 보임 | MapSprite에 Texture 지정(에디터에서 드래그) |
| 스프라이트가 안 보임 | 위치(0,0), centered, 카메라, 스케일 |
| 투명/이상함 | Import → Reimport |
