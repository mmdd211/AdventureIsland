---
feature: pollen-queen-dancer-sprites
status: in-progress
updated: 2026-09-13
branch: master
commits: 78528f6..04a1dcc
---

# 花粉女爵·二形态（花冠舞姬）idle 舞步素材

## Report

**What was built** — 二形态「花冠舞姬」单次 3×3 舞步设定表锁定身份，绿幕抠图写入 `pollen_queen_dancer_{idle,move}_00..05.png`（224×224）。9→6 抽帧保留舞步弧线。管线修复：green 模式不再 key 奶白；LANCZOS 下采样 + despill + 补针孔。

**Verification** — 处理 6/6 OK；绿边 0；内洞 9–13；三段身体/奶白/金色均在；Godot `smoke_pollen_queen_dancer_frames.gd` → `SMOKE_PASS` / `SMOKE_IDLE_MOVE_OK`（idle=6, move=6）。

**Journey log**
- 绿幕模式 key near-white 会掏空奶白裙（内洞 120）→ green 只 key 纯绿。
- AI 软边带绿 → `despill_green`；LANCZOS 后需 alpha 再硬化 + `fill_pinholes`。
- 2× block + 限色会把细节压糊，比原图更糊 → 弃用。
- 单次 3×3 网格可锁同一只；分动作多次生图必换角。
- 用户确认后只替换 idle/move；其它动作仍旧帧，进游戏切换会新旧混用。

## [S1] Problem

现网 dancer 44 帧可进游戏，但形象偏旧，未体现「蜂腰长裙 + 花冠 + 花瓣扇 + 蜂类遗传」的二形态设定。需先用单次 3×3 舞步 idle 设定表锁定身份，再写入引擎 idle/move。

## [S2] Design

### 身份锁定（二形态）

同一次 `image_gen` 产出 3×3 舞步表，避免分格多次生图换角。身份锁写入 prompt 且逐字复用：

```text
Identity lock (EXACT):
- 3/4 side-view courtly dancer bee-queen, platformer side silhouette, faces slightly LEFT
- Extremely slim wasp waist
- Huge multi-layer petal gown (deep crimson, rose, pink, cream, dark gold) forming a large flower silhouette
- Large royal FLOWER CROWN (petals + stamens + central gold ornament; NOT a normal crown)
- Elegant cold haughty female bee-queen face, amber/gold eyes, slight bee heritage in hair
- Large petal folding fan (pink/scarlet/cream petals, gold ribs) held near body, never touching cell edge
- Tiny hex honeycomb motifs on waist/shoulders/skirt
- 16-bit SNES pixel art, hard edges, dark outline, high contrast, no AA/photo/3D
Background: solid pure #00FF00 green
```

### 用户已确认决策

| 项 | 值 |
|----|-----|
| 底色 | 绿幕 `#00FF00`（不用洋红，避免玫红/粉裙被掏空） |
| 范围 | 先 idle 身份设定表 + 舞步循环；其它动作后续再扩 |
| 画布 | 224×224 对齐现网 dancer |
| 工作区 | 继续 master；提交只 stage 舞姬相关 |
| 网格 | 3×3，9 帧舞步 idle |
| 锚点 | center |
| 安全区 | 主体约 60–65% 画布高，禁止贴边 |
| 朝向 | 非 bee 默认 `flip_h = direction > 0`，美术默认略朝左 |

### 管线契约

| 项 | 值 |
|----|-----|
| 源图 | `data/monsters/raw/dancer_idle_dance_3x3_v1.png` |
| 处理 | `tools/process_boss_sheet.py --key green --size 224 --target-h 150 --form dancer` |
| 绿幕规则 | `--key green` **不**把 near-white 当背景（奶白/粉是主体）；key 后 `despill_green` |
| 清晰度 | 源→目标高用 LANCZOS（禁 NEAREST 下采样）；最终 despill + 补针孔 |
| 引擎路径 | `assets/sprites/monsters/pollen_queen/pollen_queen_dancer_{idle,move}_{00..05}.png` |
| 9→6 抽帧 | 保留舞步弧线：cell 0,1,3,4,6,7（站立→左倾→旋转峰→滑动→收拢→回中） |
| move | 复用 idle 帧；引擎 fps 已有 idle=8 / move=10 |
| 禁止 | 改 `BOSS_FRAME_STATES`、碰撞、技能数值、其它动作帧 |

### 舞步 9 帧语义（源表）

1. 优雅站立，花扇垂于身侧  
2. 身体略左倾，裙摆展开  
3. 花扇微抬  
4. 身体小角度旋转，裙摆弧线  
5. 舞步最高点，花扇全开  
6. 向另一侧滑动  
7. 裙摆收拢，花扇回落  
8. 回正中  
9. 回到第 1 帧（循环闭合）

### 失败回退

- 身份漂/换角 → 仅重出该 3×3（≤2 次）
- 绿幕仍吃进粉裙 → 检查是否大面积近绿高光；必要时收紧 `is_key_color` green 阈值而非改角色配色
- **奶白被掏空** → 禁止 green 模式 key near-white（本 feature 已修）
- **绿边** → `despill_green` 把边缘 `g > max(r,b)+12` 钳到 `max(r,b)`
- 9→6 抽帧节奏不顺 → 只改 `--pick` 列表，不重生图
- 与现网 224 全幅旧帧比显得偏小 → 只调 `boss_animator` dancer scale/offset，不改碰撞

## [S3] Out of Scope

- dancer skill/hurt/evolve/death（attack 本阶段做）
- 一形态 bee 素材
- 蘑菇 Boss
- 改 `BOSS_FRAME_STATES`、技能数值、碰撞
- 洋红底管线
- 纯文字重新生成角色（必须 image_edit 身份锁）

## Tasks

- [x] T1: 写入本 spec 并锁定决策 — acceptance: 文档含身份锁、契约、9→6 映射（covers: S2）
- [x] T2: 生成 3×3 舞步设定表 — acceptance: `data/monsters/raw/dancer_idle_dance_3x3_v1.png` 存在；9 格同一只花冠舞姬；绿幕；无水印进引擎帧（covers: S2; depends: T1）
- [x] T3: 处理写入 idle/move — acceptance: 12 张 224×224，主体不贴边，n 足够；idle 与 move 内容一致（covers: S2; depends: T2）
- [x] T4: 用户确认身份 — acceptance: 书面确认设定表过关或列出修改点（covers: S2; depends: T2）— 「好，差不多了，注意抠图别抠掉重要部分」
- [x] T5: 加载烟雾 — acceptance: `load_frames("pollen_queen","dancer")` 在 idle/move 上帧数正确（其它动作仍用旧帧）（covers: S2; depends: T3）— `SMOKE_PASS` + `SMOKE_IDLE_MOVE_OK`

## [S2c] Attack 阶段（当前）

### 身份铁律

**禁止**用纯文字 `image_gen` 重画角色。必须 `image_edit` + 已过关身份参考图：
- 主参考：`data/monsters/raw/dancer_identity_ref_for_attack.png`（idle 源表 cell4，花扇展开）
- 备选：`data/monsters/raw/dancer_identity_ref_idle03_green.png`（引擎 idle_03 贴绿底）

与 idle 同一只：花冠、蜂腰、花瓣裙、花瓣扇、冷艳脸。

### 朝向契约（attack 必须遵守）

| 项 | 值 | 依据 |
|----|-----|------|
| 美术默认朝向 | **左侧视 3/4**，头/胸/扇主方向朝左 | `faces_head_right` 仅 bee；dancer `flip_h = direction > 0` |
| 引擎行为 | 攻击前 `direction` 转向玩家并 flip | `elite_boss.gd` 追踪玩家；`boss_animator` 每帧 flip |
| 花扇挥击 / 残影弧 | **向左扫出**（面朝方向） | `fan_strike` 弹幕朝玩家 |
| 禁止 | 正对镜头为主、残影对称绕头 | flip 后读向糊 |

idle 已按略朝左过关；attack 必须同一套，否则 idle↔attack 切换像换人/换轴。

### 项目契约 vs 用户文案

| 用户文案 | 项目落地 |
|----------|----------|
| 网格 2×3，6 帧 | **2×4 源表，pick 7 帧**（`BOSS_FRAME_STATES.attack=7`，不改表） |
| 底色 `#FF00FF` | **绿幕 `#00FF00`**（洋红会掏玫红/粉） |
| 画布未写 | **224×224**，target-h 150，与 idle 一致 |
| 三段横挥 | 7 帧：蓄力→挥1→挥2→峰值→峰值余韵→后摇→回姿 |

### Attack 7 帧语义（源 2×4 pick）

| out | 源 cell | 语义 |
|-----|---------|------|
| 00 | 0 | 准备：扇收一侧，裙垂，微侧转 |
| 01 | 1 | 第一段横挥，扇展开，短粉轨迹 |
| 02 | 2 | 第二段反向，扇全开，裙摆旋，花瓣散 |
| 03 | 4 | 第三段峰值：大弧残影，花瓣大量飞散 |
| 04 | 5 | 峰值余韵（力量延续） |
| 05 | 6 | 后摇：前倾回收，惯性摆，花粉消散 |
| 06 | 7 | 回战斗姿：居中，扇半开 |

### 处理

```
python tools/process_boss_sheet.py \
  --sheet data/monsters/raw/dancer_attack_2x4_v1.png \
  --state attack --form dancer --cols 2 --rows 4 \
  --pick 0,1,2,4,5,6,7 --key green \
  --size 224 --target-h 150 \
  --frame-template "pollen_queen_dancer_attack_{out_i:02d}.png"
```

### Attack Tasks

- [x] A1: image_edit 身份锁 2×4 攻击表 — acceptance: 源图在 raw；7 姿与 idle 同一只；绿幕（covers: S2c）
- [x] A2: 处理写入 attack 00..06 — acceptance: 7 张 224×224；无绿残留/贴边；奶白扇裙在（covers: S2c; depends: A1）
- [ ] A3: 用户目视确认同一只 — acceptance: 与 idle 并排无换角（covers: S2c; depends: A2）
- [x] A4: 烟雾 attack=7 — acceptance: SMOKE_PASS（covers: S2c; depends: A2）— attack=7, idle/move=6
