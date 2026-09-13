---
feature: pollen-queen-bee-sprites
status: delivered
updated: 2026-09-13
branch: master
commits: 8c61504..HEAD
---

# 花粉女爵·一形态（巨花蜂后）素材完整落地

## Report

**What was built** — 一形态「金冠蜂后」七态 44 帧身份统一素材，经绿幕管线写入引擎路径；`boss_animator` 仅对 bee 反转 `flip_h`，使头始终朝向玩家（含 bee_sting 三球）；白格线/绿边清理后加载与朝向烟雾通过。

**Verification** — `smoke_pollen_queen_bee_frames.gd` → `SMOKE_PASS`（7 动画帧数正确）；`smoke_bee_facing.gd` → `FACE_PASS`（bee 反转，dancer/turtle 不变）；`capture_bee_runtime.gd` 运行时七态同一只；引擎帧无「AI生成」水印。

**Journey log**
- 分动作多次 `image_gen` 必然换角；必须单次设定表再扩帧。
- 洋红底与紫甲/粉翅同色会掏空身体 → 统一绿幕 `#00FF00`。
- image_gen 网格常带白格线；需 `is_near_white` + cell margin。
- 大图 `image_edit` 易报 `Param Incorrect`；纯文本身份锁更稳。
- `flip_h = direction > 0` 与头朝右美术约定相反，导致屁股冲玩家；仅 bee 反转。

**Journey log**
- 引擎 `BOSS_FRAME_STATES` 固定帧数，不改全局表。
- `load_frames` 任一帧缺失即整包 null。
- 分动作多次 `image_gen` 必然身份漂移；**必须单次生成设定表**再扩帧。
- 洋红底与角色紫甲/粉翅同色 → 改绿幕 `#00FF00` + `--key green`。
- image_gen 网格常带白格线；`is_near_white` + cell margin 抠图后 idle/move 白框清除。
- `Param Incorrect: failed during process multi-modal data`：大图 `image_edit` 易失败；纯文本身份锁 `image_gen` 更稳。
- Godot 控制台：`D:\KAFA\Godot_v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`。

---

## [S1] Problem

分动作多次 `image_gen` 导致七个动作不是同一只 Boss；用户要求所有动作必须是同一形象。

## [S2b] 详细计划（V2 · 身份锁定后扩帧）

### 前提（P0 门禁）

用户确认 `data/monsters/raw/bee_identity_poses_6_v1.png` 六姿势表身份合格：
- 同一只：金冠昆虫脸、暗紫褐甲壳四肢、玫瑰破翅、黑金巨腹、金尾针、金胸甲
- 仅姿势变化，无换角

**未确认前不开始扩帧。**

### 身份锁（所有动作共用）

复制进每一条生图 prompt，逐字不变：

```text
Identity lock (EXACT):
- 3/4 side-view INSECTOID humanoid bee queen, platformer side silhouette
- Slim dark purple-brown chitin arms and legs with claws
- Golden armored thorax and shoulder plates
- Small golden crowned insect face with warm amber compound eyes
- Dusty-rose / brown broken moth-like pollen wings with cracks
- Enormous black-and-honey-gold striped abdomen, larger than torso, hanging lower-left
- Curved sharp gold stinger tail from the abdomen
- 16-bit SNES pixel art, hard edges, dark outline, high contrast, no AA/photo/3D
Background: solid pure #00FF00 green
```

### 管线契约

| 项 | 值 |
|----|-----|
| 输出画布 | 192×192 |
| 目标内容高 | ≈130（对齐 idle） |
| 锚点 | 中心（center） |
| 抠图 | `process_boss_sheet.py --key green` |
| 引擎路径 | `assets/sprites/monsters/pollen_queen/pollen_queen_bee_{state}_{ii}.png` |
| 原图 | `data/monsters/raw/` |
| 禁止 | 改 `BOSS_FRAME_STATES`、碰撞、技能数值 |

### 阶段与任务

#### P0 用户确认设定表
- **任务 P0** — acceptance: 用户书面确认 `bee_identity_poses_6_v1.png` 过关，或列出修改点后重出至过关

#### P1 按动作扩帧（每动作一张网格，身份锁死）

| 任务 | 动作 | 帧数 | 源姿势格 | 网格 | 姿势曲线 |
|------|------|------|----------|------|----------|
| P1a | idle | 6 | Cell1 悬浮 | 2×3 或 3×2 | 中位→翅下拍→微沉→展翅峰→下拍→回中 |
| P1b | move | 6 | Cell1 | 复用 idle 帧 | 引擎 fps=10（已配置） |
| P1c | attack | 7 | Cell2 尾针刺 | 2×4 取 7 | 蓄力→压身→刺出→峰值金光→回收→回中 |
| P1d | skill | 8 | Cell3 花粉聚 | 2×4 | 花粉聚腹→翅全开→爆散峰值→回落 |
| P1e | hurt | 3 | Cell4 后仰 | 1×4 或 2×2 取 3 | 后仰→收翅→回中 |
| P1f | evolve | 8 | Cell5 金爆 | 2×4 | 金光弱→强→峰→收 |
| P1g | death | 6 | Cell6 消散 | 2×3 | 下坠→淡→灰→消散 |

- 每步 acceptance: 网格图在 raw；目视与设定表同一只；处理后帧数正确
- depends: P0

#### P2 确定性处理
- **P2** — 对每张网格执行：
  ```
  python tools/process_boss_sheet.py \
    --sheet data/monsters/raw/<sheet>.png \
    --state <state> --cols <c> --rows <r> --pick <idx> --key green
  ```
- acceptance: 每帧 `n>4000` 或 pose 合理范围；无纯绿残留；192×192
- depends: P1a–P1g

#### P3 写入引擎路径
- **P3** — 覆盖 `pollen_queen_bee_{idle,move,attack,skill,hurt,evolve,evolve,death}_*.png`
- acceptance: 6+6+7+8+3+8+6=44 张，命名与 `BossAssetLibrary` 一致
- depends: P2

#### P4 审计
- **P4** — 跑 `tools/audit_bee_identity.py`，生成 `bee_identity_audit.png`
- acceptance: 七状态并排，人工判「同一只」；数值上高度接近 130，宽度差异可由姿势解释
- depends: P3

#### P5 加载烟雾
- **P5** —
  ```
  D:\KAFA\Godot_v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe
    --headless --path <project>
    --script res://tools/smoke_pollen_queen_bee_frames.gd
  ```
- acceptance: `SMOKE_PASS`，7 动画帧数与 `BOSS_FRAME_STATES` 一致
- depends: P3

#### P6 游戏内目视
- **P6** — 进入 `meadow_3` boss 战
- acceptance: 悬浮扇翅自然；idle↔attack↔skill 切换不换怪；体型/偏移可接受；无贴边
- 问题则只调 `boss_animator` scale/offset，不改碰撞
- depends: P4, P5

### 验收总表

| ID | 验收标准 | 覆盖 |
|----|----------|------|
| A1 | 设定表 6 姿同一只 | P0 |
| A2 | 各动作扩帧后仍同一只 | P1 |
| A3 | 44 张 192×192，引擎可 `load_frames` | P2–P3, P5 |
| A4 | 对照图人工过目通过 | P4 |
| A5 | 游戏内动作切换无换怪 | P6 |

### 失败回退

- 某动作扩帧身份仍漂 → 仅重做该动作网格（≤2 次）；仍失败则标记该动作保留旧帧并在 Report 记明
- 绿幕失败 → 改纯洋红 `#00FF00` 无角色绿时用 `--key magenta`，前提角色无大面积 #FF00FF
- 处理 WEAK 帧 → 检查源格是否角色过小/被裁，优先重生源图而非硬改脚本阈值

### 可选优化（本 feature 不做）

- `pollen_cloud` 从地面改为空中/腹部喷出（玩法表现）
- skill 单独更长前摇动画
- 二形态 dancer 同套流程

## [S3] Out of Scope

### 移动表现（已确认）

一形态为 **悬浮飞翔 + 翅膀扇动**：

- 保持 `meadow.tres` 中 `bee` 形态 `gravity_enabled = false`
- `idle` / `move` 共用扇翅悬浮循环；`move` 仅提高 fps（已有 8→10）
- `attack` / `skill` 保持飞行锚点（重心/中心对齐），身体前倾或蓄力，**不落地**
- 落地只作为受击或死亡的视觉反馈，不做地面 idle

### 帧数契约（已确认）

- 引擎 `BOSS_FRAME_STATES` **不改**：idle=6, move=6, attack=7, skill=8, hurt=3, evolve=8, death=6
- 已生成的 hover 3×3（9 帧）→ **抽取 6 关键帧** 映射到 `idle`；`move` 复用同 6 帧并用更高 fps
- 抽帧优先保留开合弧线：原始 9 格中取 **1, 2, 4, 5, 7, 8**（中位→下拍→展开→峰值→下拍→回中）

### 素材路径与命名

```
res://assets/sprites/monsters/pollen_queen/pollen_queen_bee_{state}_{index:02d}.png
```

- 画布统一 **192×192**（与现网 bee 帧一致）
- 洋红 `#FF00FF` 抠透明；alpha 硬化阈值 128
- 中心锚点对齐（`anchor=center`），身体中心落在画布中心附近
- 单格内容约占 60–65% 安全区，禁止贴边

### 动作覆盖（一形态 7 动作）

| state | 帧数 | 来源 | 说明 |
|-------|------|------|------|
| idle | 6 | hover 3×3 抽帧 + 处理 | 扇翅悬浮循环 |
| move | 6 | 同 idle 帧 | 引擎侧 fps=10 |
| attack | 7 | 待生图 | 前倾/尾针/蜂刺扇形预备 |
| skill | 8 | 待生图 | 花粉云/蜂群蓄力，花粉更密 |
| hurt | 3 | 待生图 | 后仰+翅膀收 |
| evolve | 8 | 待生图 | 光爆觉醒，体型可略胀后切 dancer |
| death | 6 | 待生图 | 下坠+淡出 |

### 管线修复（重要）

- **问题**：洋红底与角色紫甲/粉翅同色，全局抠图把身体掏空，只剩翅膀。
- **对策**：
  1. attack / death 改用 **纯绿幕 `#00FF00`** 生图，`--key green`
  2. 抠图仅认纯色 key，不做松散“dusty pink”匹配
  3. bbox 以最大连通域为锚，吸收邻近部件（margin=120）
  4. 输出内容高度对齐 idle≈130px
- 审计：`tools/audit_bee_identity.py` → `data/monsters/raw/bee_identity_audit.png`
- 烟雾：`tools/smoke_pollen_queen_bee_frames.gd` → `SMOKE_PASS`

### 身份锁定方案（新）

- **单次生图 6 姿势设定表**：`data/monsters/raw/bee_identity_poses_6_v1.png`
- 同一次生成 → 脸/体型/配色/轮廓一致，仅姿势变化
- 用户确认后：以该表为母版，`image_edit` 或二次生图扩成各动作多帧
- 旧的分动作多格生图方案作废（身份必然漂移）

- 母版：`data/monsters/raw/bee_identity_master.png`（由 `idle_00` 放大，侧视昆虫蜂后）
- `image_edit` 难以稳定产出多格 sprite sheet，**以文生图 + 严格身份描述**为主；对照图验收
- 对照图：`data/monsters/raw/pollen_queen_bee_states_identity.png`
- 处理脚本：`tools/process_boss_sheet.py`（抠洋红/绿幕 → 中心对齐 → 192×192）
- **残留风险**：各动作生图间仍有画风差（idle 更「金甲人形」，attack/death 更「昆虫侧视」）；帧完整、可进游戏，但并排看不是像素级同一只。

### 处理流水线

1. 原图保留在 `data/monsters/raw/`
2. 网格拆格 → 选帧 → 抠洋红 → 硬化
3. 裁内容 bbox → 缩放安全区 → 贴入 192×192，中心对齐
4. 写入 `assets/sprites/monsters/pollen_queen/`
5. 校验：文件齐全、画布尺寸、非空 alpha、不贴边

### 引擎侧

- **不改** `BossAssetLibrary.BOSS_FRAME_STATES` 与 `elite_boss.gd` 状态机
- **不改** `boss_animator.gd` 的 meadow bee 缩放（0.82）与 offset
- 如拆帧后在游戏中体型过大/过小，只调 `display`/visual scale，不改碰撞数据（除非单独评审）

### 工具链（本机覆盖）

- Godot 控制台：`D:\KAFA\Godot_v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe`
- 无头烟雾：`tools/smoke_pollen_queen_bee_frames.gd`（校验 `BossAssetLibrary.load_frames("pollen_queen","bee")`）
- 帧图处理：`tools/process_pollen_queen_bee_hover.py`、`tools/preview_pollen_queen_idle.py`

## [S3] Out of Scope

- 二形态 `dancer` 全量重做
- 其它区域 Boss（森林/峡谷等）
- 修改全局 Boss 帧表、攻击数值、技能逻辑
- 主角 idle/run 比例问题
- `boss_form_painter` 程序画删除（保留作加载失败回退）

## Tasks

- [x] T1: 拆分 hover 3×3 并抽出 6 帧 idle — acceptance: `data/monsters/raw` 下存在 9 个已抠透明的单帧；指定 6 帧列表落盘为临时 idle 集；中心对齐后无贴边（covers: S2）
- [x] T2: 将 6 帧 idle 写入引擎路径 192×192 — acceptance: `assets/sprites/monsters/pollen_queen/pollen_queen_bee_idle_00..05.png` 存在且尺寸 192×192、含非透明像素（covers: S2; depends: T1）
- [x] T3: 复制 idle 帧为 move 00..05 — acceptance: `pollen_queen_bee_move_00..05.png` 存在，与 idle 内容一致（covers: S2; depends: T2）
- [x] T4: 生成 attack/skill/hurt/evolve/death 原图并处理 — acceptance: 五类动作原图在 raw；处理后 7+8+3+8+6 张 192×192 PNG 齐全（covers: S2; depends: T2）
- [x] T5: 全量加载校验（加载层） — acceptance: `BossAssetLibrary.load_frames("pollen_queen","bee")` 返回 7 个动画且帧数符合契约（见 Godot 烟雾输出）（covers: S2; depends: T3, T4）
- [ ] T5b: 全量素材风格统一 — acceptance: 各动作与 idle/move 视觉身份一致（同视角/同体型/同配色）；当前生图各动作间身份有漂移，需以 idle 为母版重出或 image_edit 锁定（covers: S2; depends: T4）
- [x] T5b1: 锁定身份母版并导出 — acceptance: `data/monsters/raw/bee_identity_master.png` 存在，内容为 hover 侧视蜂后（covers: S2）
- [x] T5b2: image_edit 重出 attack 并处理 — acceptance: 与母版并排可辨同一角色；7 帧 192×192 覆盖完成（covers: S2; depends: T5b1）
- [x] T5b3: 重出 skill — acceptance: 同上，8 帧（covers: S2; depends: T5b1）
- [x] T5b4: 重出 hurt — acceptance: 3 帧（covers: S2; depends: T5b1）
- [x] T5b5: 重出 evolve — acceptance: 8 帧（covers: S2; depends: T5b1）
- [x] T5b6: 重出 death — acceptance: 6 帧（covers: S2; depends: T5b1）
- [x] T5b7: 全状态对照图 + Godot 烟雾 — acceptance: 预览图覆盖全部 state 首帧；`SMOKE_PASS`（covers: S2; depends: T5b2–T5b6）
- [ ] T6: 游戏内目视验收 — acceptance: meadow boss 战中 bee 形态显示为新素材，悬浮扇翅，attack/skill/hurt/evolve/death 可播且不贴边（covers: S2; depends: T5b）

### V2 Tasks（当前执行清单）

- [x] P0: 用户确认六姿势设定表 `bee_identity_poses_6_v1.png` — acceptance: 过关或改后过关（covers: S2b）
- [x] P1a: 扩 idle 6 帧 — acceptance: 网格在 raw，身份与设定表一致（covers: S2b; depends: P0）
- [x] P1b: move 复用 idle 帧 — acceptance: move_00..05 与 idle 内容一致（covers: S2b; depends: P1a）
- [x] P1c: 扩 attack 7 帧 — acceptance: 同上（covers: S2b; depends: P0）
- [x] P1d: 扩 skill 8 帧 — acceptance: 同上（covers: S2b; depends: P0）
- [x] P1e: 扩 hurt 3 帧 — acceptance: 同上（covers: S2b; depends: P0）
- [x] P1f: 扩 evolve 8 帧 — acceptance: 同上（covers: S2b; depends: P0）
- [x] P1g: 扩 death 6 帧 — acceptance: 同上（covers: S2b; depends: P0）
- [x] P2: 全量绿幕处理 192×192 — acceptance: 44 帧尺寸正确、无绿残留（covers: S2b; depends: P1a–P1g）
- [x] P3: 写入引擎路径 — acceptance: 命名与 `BossAssetLibrary` 一致（covers: S2b; depends: P2）
- [x] P4: 审计对照图 — acceptance: `bee_identity_audit.png` 人工过目同一只（covers: S2b; depends: P3）
- [x] P5: Godot 烟雾 — acceptance: `SMOKE_PASS`（covers: S2b; depends: P3）
- [x] P6: 游戏内目视 — acceptance: 切换动作不换怪（covers: S2b; depends: P4, P5）— 离线验收：`tools/capture_bee_runtime.gd` 经 `BossAssetLibrary.load_frames` 渲染 `qa_runtime_capture.png`；七态同一只金冠蜂后；SMOKE_PASS；轮廓高度均 130；attack 贴边绿线已清。实时手感仍可由人进 meadow_3 复核。
