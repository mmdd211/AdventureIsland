---
feature: whisper-root-sprites
status: delivered
updated: 2026-09-18
branch: master
commits: 9541687de86eba5e3d036185fde1636dbb0d1fd1..43dd6581b06fc0687efaa62bf4cc6ce1648a72f8
---

# 低语主教 whisper_root 两形态七态全量素材

## Report

**What was built** — grove 第三 Boss「低语主教 whisper_root」两形态（nest 根须巢母 / bishop 低语主教）各七态全量引擎帧，共 88 张。洋红幕 + 身份锁 `image_edit` 流水线。首版引擎帧为 224×224；后续对齐 canyon/grove 新画布标准，**全量升级为 256×256 透明留边**（身份未变，仅安全边距）。`boss_animator` grove scale 为 **nest 0.95 / bishop 0.85**，光环 `#7ff4c9`（与 256 画布注释一致，已随 `75d315e` 入库）。move 复用 idle；hurt 为强受击三拍。

**Verification** —  
- `smoke_whisper_root_nest_frames.gd` → `SMOKE_NEST_ALL_STATES_OK`（exit 0）  
- `smoke_whisper_root_bishop_frames.gd` → `SMOKE_BISHOP_ALL_STATES_OK`（exit 0）  
- 工作区 88 帧全部 256×256；空帧 0；贴边 opaque>8 为 0  
- HEAD(224) vs 工作区(256) 并排目检：同一 nest/bishop 身份，仅留边扩大  

**Journey log**
1. 源表行列必须先目检：bishop idle 曾误按 2×3 切 3×2 表，opaque 正常仍缺头/倒置。
2. hurt 不能微姿态，需后仰/爆闪/碎片才读得出受击。
3. 洋红底上的 AI 角标会 key 成残影；交付前必须逐帧目检，不能只看贴边审计。
4. grove 主体青绿，绿幕会自伤 → 本 Boss 用洋红幕。
5. commit 后又出现的「88 张全变」不一定是乱改：224→256 透明 pad 会表现为字节全变、身份不变；先对尺寸与 bbox 再决定 revert 还是升级入库。

## [S1] Problem

第三区 grove「低语主教」数据与技能逻辑已就位，但曾缺 `assets/sprites/monsters/whisper_root/`，`load_frames` 回退 `boss_form_painter`。需按身份锁流水线补齐两形态七态；交付后另需把画布从 224 升到 256 并与 animator scale 对齐。

## [S2] Design

### 2.1 项目契约（硬约束 · 现行）

| 项 | 值 | 依据 |
|----|-----|------|
| Boss id | `whisper_root` | `grove.tres` |
| resource_prefix | `whisper_root` | 同上 |
| Form1 | `nest` · 根须巢母 | `BossFormData` |
| Form2 | `bishop` · 低语主教 | `BossFormData` |
| 帧数 | idle6 / move6 / attack7 / skill8 / hurt3 / evolve8 / death6 | `BOSS_FRAME_STATES`，**不改** |
| 画布 | **256×256**（透明留边；历史首版 224） | 与 canyon 同标准 |
| 底色 | 洋红 `#FF00FF`（抠图后已透明） | grove 主体青绿 |
| 朝向 | 美术默认朝左；`flip_h = direction > 0` | 非 bee 默认 |
| 输出路径 | `assets/sprites/monsters/whisper_root/whisper_root_{form}_{state}_{ii}.png` | `load_frames` 拼接规则 |
| Animator | grove nest scale `0.95` / bishop `0.85`；aura `#7ff4c9` | `boss_animator.gd` |
| 禁止 | 改 `BOSS_FRAME_STATES`、碰撞、技能数值、其它 Boss 帧 | 七态契约 |

### 2.2 身份锁（铁律）

- **禁止**纯文字 `image_gen` 换角重生后续动作。
- 母版：`data/monsters/raw/nest_identity_master_v1.png`、`bishop_identity_master_v1.png`（目录 gitignore，本地归档）。
- 动作表 `image_edit` + 母版；分形态各自母版。

### 2.3 一形态 nest 身份要点（已交付）

- 古老腐朽、有自我意识的巨树巢母；巨大中空树腔、裂纹面、6–8 根根须触须、根系扎地。
- 七态帧已在库；smoke 通过。

### 2.4 二形态 bishop 身份要点（已交付）

- 邪异人形主教：木质面具裂纹、主教冠、胸口符核、骨杖、悬浮符眼、根须血统。
- 七态帧已在库；smoke 通过。

### 2.5 管线契约

| 步 | 操作 |
|----|------|
| 母版 | `image_gen` 单帧 → 用户确认 → 存 raw |
| 动作表 | `image_edit` + 母版，单次网格 |
| 抠图 | `process_boss_sheet.py`；交付帧现为 **256** 画布 + 透明安全边 |
| animator | grove scale nest 0.95 / bishop 0.85；aura `#7ff4c9` |
| 验收 | 审计 → Godot smoke 七态 → 与 idle 并排同一只 → 只 stage 本 Boss 路径 |
| 提交 | 不混 canyon / 舞姬 / `edited-*.png` |

### 2.6 交付切分

| 批次 | 内容 | 状态 |
|------|------|------|
| P0–P5 | nest/bishop 七态 + smoke + animator | 已完成（`9541687` 及更早） |
| P6 | 224→256 留边升级入库 + spec 收口 | 本阶段 |
| Out | canyon / ruins / gate | 不在本 spec |

### 2.7 失败回退

- 身份漂 → 仅重出该动作网格；母版不动。
- 混提交 → 回退，只 stage `whisper_root` / 本 spec。
- 删帧 → **禁止**。

## [S3] Out of Scope

- 改 `BOSS_FRAME_STATES` / 技能数值 / 碰撞 / 区域主题色
- canyon / ruins / gate Boss
- 舞姬/菌王素材重做
- grove 新 optional 技能动画
- 程序化 `boss_form_painter` 重写

## Tasks

- [x] T1: 写入本 spec 并锁定契约 — acceptance: 文档含帧数/洋红/身份锁/路径/切分（covers: S2）
- [x] T2: nest 标准样图并存母版 — acceptance: 母版路径可达（covers: S2.2）
- [x] T3: nest 七态设定表 + 抠图 — acceptance: 帧数符合契约；身份为巢母（covers: S2.1）
- [x] T4: nest attack/skill 表 + 抠图 — acceptance: attack7 + skill8（covers: S2.1）
- [x] T5: nest hurt/evolve/death 表 + 抠图 — acceptance: 3+8+6 七态齐（covers: S2.1）
- [x] T6: nest smoke + animator 适配 — acceptance: `SMOKE_NEST_ALL_STATES_OK`；scale 见 2.1（covers: S2.1）
- [x] T7: nest/bishop 素材 commit — acceptance: 库内含 whisper_root 全帧；本阶段补提 256 升级且不混无关路径（covers: S2.5）
- [x] T8: bishop 标准样图并存母版 — acceptance: 母版路径可达（covers: S2.2）
- [x] T9: bishop 七态设定表 + 抠图 — acceptance: `whisper_root_bishop_*` 帧数符合契约（covers: S2.1）
- [x] T10: bishop smoke — acceptance: `SMOKE_BISHOP_ALL_STATES_OK`（covers: S2.1）
- [x] T11: 256 画布升级复验 — acceptance: 工作区 88 帧均 256；双形态 smoke PASS；身份与 HEAD 并排一致（covers: S2.1）
