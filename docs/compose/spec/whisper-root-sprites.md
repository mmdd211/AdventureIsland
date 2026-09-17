---
feature: whisper-root-sprites
status: delivered
updated: 2026-09-17
branch: master
commits: 
---

# 低语主教 whisper_root 两形态七态全量素材

## Report

**What was built** — grove 第三 Boss「低语主教 whisper_root」两形态（nest 根须巢母 / bishop 低语主教）各七态全量 224×224 引擎帧，共 88 张。洋红幕 + 身份锁 `image_edit` 流水线；`boss_animator` 为 grove 配置 scale（nest 1.85 / bishop 0.85）与光环色 `#7ff4c9`。move 复用 idle；hurt 重做为强受击三拍；水印末帧用相邻干净帧顶替。

**Verification** — `smoke_whisper_root_nest_frames.gd` → `SMOKE_NEST_ALL_STATES_OK`；`smoke_whisper_root_bishop_frames.gd` → `SMOKE_BISHOP_ALL_STATES_OK`；七态帧数与 `BOSS_FRAME_STATES` 一致；贴边/洋红边审计 0。

**Journey log**
1. 源表行列必须先目检：bishop idle 曾误按 2×3 切 3×2 表，opaque 正常仍缺头/倒置。
2. hurt 不能微姿态，需后仰/爆闪/碎片才读得出受击。
3. 洋红底上的 AI 角标会 key 成残影；交付前必须逐帧目检，不能只看贴边审计。
4. grove 主体青绿，绿幕会自伤 → 本 Boss 用洋红幕。
5. master 上只 stage 本 Boss 路径，不混舞姬/其它脏文件。

## [S1] Problem

第三区 grove「低语主教」数据与技能逻辑已就位（`data/regions/grove.tres`、`elite_boss.gd` 的 `root_veins` / `dark_mist` / `whisper_judgment` / `root_prison`），但 **没有** `assets/sprites/monsters/whisper_root/`，`BossAssetLibrary.load_frames("whisper_root", form)` 返回 null，运行时回退 `boss_form_painter` 程序化像素，形象简陋且与舞姬/菌王完成度不齐。

需要按现行 **身份锁素材管线** 为两形态补齐七态全量帧。

## [S2] Design

### 2.1 项目契约（硬约束）

| 项 | 值 | 依据 |
|----|-----|------|
| Boss id | `whisper_root` | `grove.tres` |
| resource_prefix | `whisper_root` | 同上 |
| Form1 | `nest` · 根须巢母 | `BossFormData` |
| Form2 | `bishop` · 低语主教 | `BossFormData` |
| 帧数 | idle6 / move6 / attack7 / skill8 / hurt3 / evolve8 / death6 | `BOSS_FRAME_STATES`，**不改** |
| 画布 | 224×224 | 对齐 dancer |
| target-h | ~150 | 舞姬同参 |
| 底色 | **洋红 `#FF00FF`** | grove 主体青绿，绿幕会自伤 |
| 朝向 | 美术默认朝左；`flip_h = direction > 0` | 非 bee 默认 |
| 输出路径 | `assets/sprites/monsters/whisper_root/whisper_root_{form}_{state}_{ii}.png` | `load_frames` 拼接规则 |
| 禁止 | 改 `BOSS_FRAME_STATES`、碰撞、技能数值、其它 Boss 帧 | 七态契约 |

### 2.2 身份锁（铁律）

- **禁止**纯文字 `image_gen` 换角重生后续动作。
- 先 `image_gen` 出各形态 **单帧标准样图**（本阶段，用户已给完整词）。
- 用户过关后把样图存为母版：
  - `data/monsters/raw/nest_identity_master_v1.png`
  - `data/monsters/raw/bishop_identity_master_v1.png`
- 后续动作一律 **`image_edit` + 母版**，单次网格多格（2×4 等）一次锁同一只。
- 分形态各自母版；两形态可有共同主题色，但不互相当母版。

### 2.3 一形态 nest 身份要点（用户已定稿）

- 古老腐朽、有自我意识的巨树巢母；非普通树怪/树人/章鱼。
- 核心识别：**巨大中空树腔**（内部幽紫/暗青微光、菌丝、孢子、眼状光点）。
- 树腔上方 **裂纹面**：树皮裂纹发光眼，表情冷漠空洞，非人类头颅。
- **6–8 根**粗壮根须触须，非对称，末端可分裂尖刺（对应 `root_veins`）。
- 下半身无双腿，根系扎地支撑。
- 主色黑褐/深棕/灰黑/暗绿；辅色苔藓绿/腐败黄绿/幽紫/暗青；发光焦点在树腔与裂纹。
- 3/4 视角，静止单帧，全身完整，安全边距，主体约 65–70%。
- 背景 100% `#FF00FF`；无文字/UI/边框/场景/其它角色。

### 2.4 二形态 bishop 身份要点（用户已定稿）

- 由巢母蜕变的 **邪异人形主教**：瘦高修长，约普通人形 1.2–1.3 倍高；非普通牧师/骑士/巫师。
- **木质身体**：全木质皮肤（黑褐/深棕/灰黑），树皮裂纹、年轮、细小根须；手指末端化根。
- **木质面具**（核心识别）：细长无五官，两细长黑暗眼孔发幽紫/暗青光；中央纵向裂纹 **继承一形态裂纹面**；额头年轮纹。
- **主教冠**：面具顶部弯曲树枝自然成冠，挂干枯藤蔓与苔藓，非普通皇冠。
- **长袍**：石木混合，深黑/深棕/暗紫/灰绿；边缘破损；下摆分裂成根须；根系纹路低调。
- **胸口符核**（核心）：树眼/根系交错核心，幽紫/暗青/冷白，四周裂纹 — **对应一形态中空树腔**。
- **骨杖**（第二识别）：骨+枯枝+根+暗金属，杖顶纵向骨质结构嵌紫色符眼；右手持杖。
- **悬浮符眼 2–4 枚**：木质碎片+根须+紫色符文+眼状光核，至少一枚近肩 — **对应一形态孢子巢穴**。
- **根须血统**：袖口/肩/腰/袍背少量根须，明显少于一形态；根须变形成服装与肢体。
- **暗息**：幽紫/暗青薄雾粒子，安静危险，无大爆炸光环。
- **站姿**：直立微前倾，骨杖竖靠，左臂垂，面具朝镜头，符眼悬浮；禁止攻击/挥杖/跳跃/施法。
- **视觉血统表**：树腔→符核；裂纹面→面具裂纹；根须触须→袍/袖根须；古枝→冠与杖；孢子巢→符眼；内部幽紫能量→暗息。
- 3/4、全身、洋红 `#FF00FF`、安全边距、像素硬边；单帧标准样图，不做动画。
- 对应技能：`dark_wave` / `whisper_judgment` / `root_prison`。

### 2.5 管线契约

| 步 | 操作 |
|----|------|
| 母版 | `image_gen` 单帧 → 用户确认 → 存 raw |
| 动作表 | `image_edit` + 母版，单次 2×3 / 2×4 网格 |
| 抠图 | `process_boss_sheet.py --key magenta --size 224 --target-h 150 --prefix whisper_root --form {nest\|bishop} --out-dir assets/sprites/monsters/whisper_root --frame-template whisper_root_{form}_{state}_{out_i:02d}.png` |
| magenta 注意 | 现网 magenta 模式会 key near-white；若主体出现白/浅青高光被掏空 → 收紧/关闭 near-white，**不改角色配色** |
| 清晰度 | LANCZOS 下采样 + alpha 硬化；必要时补针孔 |
| 水印 | 右下「AI生成」格避开 pick；以引擎帧为准 |
| 验收 | 像素审计（贴边/色边/内洞）→ Godot `load_frames("whisper_root", form)` 七态帧数 → 与 idle 并排同一只 → 用户确认后 commit |
| animator | grove 现 `visual_scale=2.1` 为 painter 回退；自定义 224 帧后 **只调 scale/offset/aura**，不改碰撞与朝向规则 |
| 提交 | master 上严格只 stage `whisper_root` / 本 spec / raw 母版 / smoke 脚本 |

### 2.6 交付切分（一形态做完再开二形态）

| 批次 | 内容 | 验收 |
|------|------|------|
| P0 | 本 spec | 文档齐全 |
| P1 | nest 标准样图 → 母版 | `nest_identity_master_v1.png`；继续一形态 |
| P2 | nest idle/move 表 + 抠图 | 12 帧 224，审计通过 |
| P3 | nest attack / skill / hurt | 帧数 7/8/3，同一只 |
| P4 | nest evolve / death | 七态齐 |
| P5 | nest animator + smoke | `load_frames("whisper_root","nest")` 七态 PASS |
| P6 | 用户确认后 nest 分批 commit | 只 stage nest 相关 |
| P7+ | bishop 标准样图及七态（nest 完成后） | 另开批次 |

可选：`skill_*` 若后续加 OPTIONAL 动画再扩，**本阶段不做**（无 optional 槽给 grove）。

### 2.7 失败回退

- 身份漂 → 仅重出该动作网格（≤2 次），母版不动。
- 洋红被 key 进暗红树皮 → 收宽 magenta 容差或改用边框 flood 优先；禁止改成绿幕。
- near-white 掏空高光 → magenta 路径关闭 `is_near_white`（针对性 patch，不伤舞姬旧管线）。
- 水印入帧 → 改 pick / 重生该格。
- 删「用不到」帧 → **禁止**；缺帧整包 null。
- 混提交 → 回退，只 stage 本 Boss 路径。

## [S3] Out of Scope

- 改 `BOSS_FRAME_STATES` / 技能数值 / 碰撞 / 区域主题色
- canyon / ruins / gate Boss
- 舞姬/菌王素材重做
- grove 新 optional 技能动画
- 程序化 `boss_form_painter` 重写（保留作加载失败回退）

## Tasks

- [x] T1: 写入本 spec 并锁定契约 — acceptance: 文档含帧数/洋红/身份锁/路径/切分（covers: S2）
- [x] T2: nest 标准样图并存母版 — acceptance: `data/monsters/raw/nest_identity_master_v1.png` 存在（covers: S2; depends: T1）
- [x] T3: nest idle/move 设定表 + 抠图写入 — acceptance: 12 张 224 帧，审计贴边/色边/内洞通过（covers: S2; depends: T2）
- [x] T4: nest attack/skill 表 + 抠图 — acceptance: attack7 + skill8，同一只巢母（covers: S2; depends: T3）
- [x] T5: nest hurt/evolve/death 表 + 抠图 — acceptance: 3+8+6 帧，七态齐（covers: S2; depends: T4）
- [x] T6: nest smoke + animator 适配 — acceptance: `load_frames("whisper_root","nest")` 七态帧数正确；scale/offset 合理（covers: S2; depends: T5）
- [ ] T7: nest 用户确认后 commit — acceptance: 仅 nest 素材/spec/工具相关（covers: S2; depends: T6）
- [x] T8: bishop 标准样图并存母版 — acceptance: `bishop_identity_master_v1.png` 存在（covers: S2; depends: T1）
- [x] T9: bishop 七态设定表 + 抠图写入 — acceptance: `whisper_root_bishop_*` 帧数符合契约，224×224（covers: S2; depends: T8）
- [x] T10: bishop smoke — acceptance: `load_frames("whisper_root","bishop")` 七态 PASS → `SMOKE_BISHOP_ALL_STATES_OK`（covers: S2; depends: T9）
