---
feature: canyon-eagle-sprites
status: delivered
updated: 2026-09-18
branch: master
commits: 9541687de86eba5e3d036185fde1636dbb0d1fd1..working-tree (uncommitted)
---

# 鹰哨统领 canyon_rock_eagle 两形态素材

> 区域：**第四 Boss · 风哨峡谷 canyon**（用户确认；`REGION_ORDER` 第 4 区）。  
> Boss：`canyon_rock_eagle`「鹰哨统领」— Form1 `eagle` 岩翼石鹰 / Form2 `hunter` 风哨猎手。

## Report

**What was built** — 第四 Boss 两形态七态引擎帧已齐（各 44 张、共 88 张，256×256，路径 `assets/sprites/monsters/canyon_rock_eagle/`）。`canyon.tres` / `world_maps.gd` 两形态数据与技能 id 已就位；`boss_animator` 为 canyon 配置 eagle scale `0.75` / hunter `0.85` 与光环 `#ffe066`。本阶段补齐 hunter 普攻 `blade_gale`（`elite_boss.gd`：面朝方向 60px 突进 + 3 道风刃，扇形 ±0.22 rad，攻速 480，伤害 `contact_damage-2`，色 `#ffe066`），避免落入通用 `_fire_projectiles` 回退。身份母版由引擎 `idle_00` 归档到 `data/monsters/raw/eagle_identity_master_v1.png` 与 `hunter_identity_master_v2.png`（该目录被 `.gitignore` 忽略，仅本地流水线盘点用）。

**Verification** —  
- `Godot headless tools/smoke_canyon_eagle_frames.gd` → `SMOKE_EAGLE_ALL_STATES_OK`（exit 0）  
- `Godot headless tools/smoke_canyon_hunter_frames.gd` → `SMOKE_HUNTER_ALL_STATES_OK`（exit 0）  
- grep：`blade_gale` 出现在 `scripts/monsters/elite_boss.gd:273`  
- 目视：两形态七态帧身份连贯；无贴边/空帧/洋红残留阈值超标  
- Independent review：spec AC 全 met，无 critical correctness bug  

**Journey log** —  
1. 素材主体在上一会话已完成，本阶段是「技能缺口 + 母版归档 + 文档/验证收口」，不是重做美术。  
2. `blade_gale` 必须写在 `_execute_basic_attack`；数据里的 `basic_attack` 字符串不能替代 match 分支。  
3. 不要复制 `hawk_roar` 的 `0.0 if direction > 0 else PI + offset` 三元写法——朝右时扇形会被吃掉；`blade_gale` 用具名 `face_angle` 先定朝向再加扇形偏移。  
4. `data/monsters/raw/` 整目录 gitignore，母版不会进 commit，属预期。  
5. `boss_animator.gd` 工作区同时含 canyon 与 grove scale 改动；canyon-only 提交时需注意 grove 行是否一并说明或拆分。

## [S1] Problem

一二形态引擎帧、数据、canyon 技能分支、animator 适配与 Godot smoke 已就位，但收口仍有缺口：

1. hunter 普攻 `blade_gale` 只写在数据里，`elite_boss.gd` 无 match 分支，会落到通用 `_fire_projectiles`
2. 身份母版未归档到 `data/monsters/raw/`（其它 Boss 有对应 master）
3. spec 状态过时、任务未收口
4. canyon 相关改动未 commit（主工作区另有 whisper_root / 临时图脏改动，不得混入）

工作区：用户明确 **在主工作区改、不建 worktree**；提交时只 stage canyon 相关路径。

## [S2] Design

### 2.1 项目契约

| 项 | 值 |
|----|-----|
| Boss id / prefix | `canyon_rock_eagle` |
| Form1 | `eagle` · 岩翼石鹰 |
| Form2 | `hunter` · 风哨猎手 |
| 帧数 | idle6/move6/attack7/skill8/hurt3/evolve8/death6（不改 `BOSS_FRAME_STATES`） |
| 画布 | 引擎帧实际 **256×256**（eagle 宽翼 + hunter 透明留边） |
| 朝向 | 美术默认朝左；`flip_h = direction > 0`（非 meadow bee） |
| 输出 | `assets/sprites/monsters/canyon_rock_eagle/canyon_rock_eagle_{form}_{state}_{ii}.png` |
| Animator | canyon eagle scale `0.75` / hunter `0.85`；aura `#ffe066` |
| Form1 战斗 | basic `talon_gust`；skills `stone_feathers`, `hawk_roar` |
| Form2 战斗 | basic `blade_gale`；skills `arrow_rain`, `dive_line` |

### 2.2 身份铁律

- 身份以已交付引擎帧为准；本阶段 **不重画、不 image_edit 动作表**
- 母版归档：`data/monsters/raw/eagle_identity_master_v1.png` / `hunter_identity_master_v2.png`
- 来源：由已通过 QC 的引擎 `idle_00` 复制归档（engine-derived archival）；目录 gitignore，不进 VCS

### 2.3 eagle 身份要点（已交付）

- 远古天空守卫巨鹰：岩石 + 天空 + 风暴；双翼岩骨石羽、岩胸甲 + 淡蓝风核、风刃尾羽、黑岩巨爪
- 七态帧已在 `assets/sprites/monsters/canyon_rock_eagle/`，smoke 通过

### 2.3b hunter 身份要点（已交付）

- 石鹰进化人形：鹰形战盔、岩胸甲风核、风披风、风刃弯刀、羽盾、腰侧风哨
- 头部按概念图修订后的 v2 形象已体现在七态帧中；本阶段不再改头
- 七态帧齐，smoke 通过

### 2.3c blade_gale 契约（已实现）

- 位置：`elite_boss.gd` → `_execute_basic_attack` match（与 `talon_gust` 同层）
- 行为：向面朝方向小幅突进；发射 **3** 道风刃弹幕，扇形角约 `±0.22 rad`，攻速 `480`，伤害 `contact_damage - 2`
- 颜色：`#ffe066`
- 数据文件保持 `basic_attack = "blade_gale"`；不改碰撞/HP

### 2.4 交付 QC

1. 两形态七态帧数符合 `BOSS_FRAME_STATES`
2. Godot smoke：`SMOKE_EAGLE_ALL_STATES_OK` + `SMOKE_HUNTER_ALL_STATES_OK`
3. `blade_gale` 在 `elite_boss.gd` 有显式分支
4. 母版文件存在于 `data/monsters/raw/`
5. 提交不混入 whisper_root / `edited-*.png` 等无关文件

### 2.5 交付切分

| 批次 | 内容 | 状态 |
|------|------|------|
| P0 | 本 spec | delivered |
| P1 | eagle 七态 + animator/smoke | 已完成 |
| P2–P3 | hunter 七态 + smoke | 已完成 |
| P3b | `blade_gale` + 母版归档 + 验证/review | 已完成 |
| P4 | 只 stage canyon 相关 commit | **待用户确认** |

## [S3] Out of Scope

- 改 `BOSS_FRAME_STATES` / 碰撞 / HP 数值
- 重绘或 image_edit 两形态动作帧
- push 远程
- 其它区域 Boss 与 whisper_root 未提交改动
- 隔离 worktree（用户选择主工作区）
- 修复 review 指出的既有 `hawk_roar` 朝右扇形塌缩（follow-up，非本阶段）

## Tasks

- [x] T1: 写入本 spec — acceptance: 契约与 QC 清单齐全（covers: S2）
- [x] T2: eagle 标准样图并存母版 — acceptance: 归档路径可达（covers: S2.2）
- [x] T3: eagle 七态处理 — acceptance: 44 帧符合契约；smoke 可加载（covers: S2.1）
- [x] T4: eagle smoke + animator 适配 — acceptance: `SMOKE_EAGLE_ALL_STATES_OK`；scale/aura 见 2.1（covers: S2.1）
- [x] T5: hunter 七态处理 — acceptance: 44 帧符合契约；smoke 可加载（covers: S2.1）
- [x] T6: hunter smoke — acceptance: `SMOKE_HUNTER_ALL_STATES_OK`（covers: S2.4）
- [x] T7: 实现 `blade_gale` — acceptance: `_execute_basic_attack` 含显式分支；3 道风刃、扇形、`#ffe066`（covers: S2.3c）
- [x] T8: 归档两形态母版 — acceptance: `data/monsters/raw/eagle_identity_master_v1.png` 与 `hunter_identity_master_v2.png` 存在且为引擎帧拷贝（covers: S2.2）
- [x] T9: 回归验证 — acceptance: 双形态 smoke 通过 + grep 确认 `blade_gale` 分支；独立 review 无 critical（covers: S2.4）
- [ ] T10: canyon 相关 commit — acceptance: 只 stage canyon 素材/spec/smoke/elite_boss；`boss_animator` 若含 grove 行需一并说明或拆分；不混 whisper_root/`edited-*.png`（covers: S2.4）
