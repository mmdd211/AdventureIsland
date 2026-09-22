---
feature: ruins-rune-colossus-sprites
status: in-progress
updated: 2026-09-18
branch: master
commits: 
---

# 符文贤者 rune_colossus · 第五 Boss 素材

> 区域：**第五 Boss · 苔石遗迹 ruins**（`REGION_ORDER` 第 5 区）。  
> Boss：`rune_colossus`「符文贤者」— Form1 `statue` 苔石守卫像 / Form2 `sage` 符文贤者（一形态样图确认后再开）。  
> 本阶段交付：**仅一形态标准基础样图（母版）**，不做动画、不做七态。

## Report

## [S1] Problem

第五区 ruins 数据与技能已在，需 Form1 `statue` 引擎帧。母版 **v4 用户已确认**。

**当前阻塞：** 首轮七态引擎帧 **QC 未通过**（用户指出大量裁切/残缺；自检确认多帧贴边、网格错切、水印残留）。smoke 仅校验「文件可加载与张数」，**不能**代替目检。

用户约束（全程强制）：

1. 生成后处理/去掉「AI生成」等字样再入库。  
2. 提交前核对 `.gitignore`，禁止 raw/临时图误提交。  
3. 大范围更新后同步 `README.md`。  
4. **先计划、后实施**；交付前必须过视觉 QC，禁止只跑 smoke 就 present。

### 1.1 首轮失败根因（已定位，重做必须规避）

| # | 根因 | 对策 |
|---|------|------|
| R1 | AI 网格实际行列 ≠ 假设，`detect_grid` 硬切角色 | 切片前**肉眼打开源表数格子**，写死 `cols/rows` |
| R2 | 源格角色顶格、无安全边 | Prompt 强制每格四周 ≥15% 洋红留边 |
| R3 | 宽体 + `target_h` 过大 → 宽度贴边被裁 | `target_h≈140–150`；验收 `bbox` 宽 **≤230** 且 **edges 全为 -** |
| R4 | `largest_component` 丢拳/特效 | 目检「头+双臂拳+双腿」齐全 |
| R5 | 色键过宽误伤石材/高光 | 切后目检轮廓；异常则收容差或重抠 |
| R6 | 无强制视觉 QC 门 | 见 §2.8 门禁；**任一项不过不得交付/commit** |

## [S2] Design

### 2.1 项目契约

| 项 | 值 |
|----|-----|
| Boss id / prefix | `rune_colossus` |
| Region | `ruins` · 苔石遗迹 |
| Form1 | `statue` · 苔石守卫像 |
| Form2 | `sage` · 符文贤者（本阶段不做） |
| Form1 战斗 | basic `stone_smash`；skills `chain_burst`, `tomb_drop` |
| 帧数 | idle6/move6/attack7/skill8/hurt3/evolve8/death6 |
| 画布 | 256×256 透明留边 |
| 母版 | `data/monsters/raw/statue_identity_master_v4.png`（已锁定） |
| 输出 | `assets/sprites/monsters/rune_colossus/rune_colossus_statue_{state}_{ii}.png` |
| Animator | ruins statue scale `0.70` / aura `#a9d36d`（已写，帧合格后沿用） |
| 首轮帧 | **作废重做**；不得 commit 残缺帧 |

### 2.8 Form1 七态重做计划（先批后做）

#### 阶段 A — 规矩落地（不产帧）

| 步 | 内容 | 验收 |
|----|------|------|
| A1 | 本 spec 写入 §1.1/§2.8 | 文档含根因与门禁 |
| A2 | `AGENTS.md` 增加「Boss 素材视觉 QC 门禁」 | 仓库内可检索 |
| A3 | 首轮残缺帧移出 `assets/` → `.scratch/rejected_statue_v1/` | `assets/.../rune_colossus` 空或仅保留通过帧 |
| A4 | `tools/README` 注明：smoke ≠ 视觉合格 | 文档更新 |

#### 阶段 B — 单态生产循环（必须串行，一态一验）

对 **每一态** 重复：

| 步 | 内容 | 验收（全过才进下一态） |
|----|------|------------------------|
| B1 | `image_edit` + **v4 母版** 出网格；prompt 写死格数、顺序、**每格安全边**、禁止文字水印 | 源表落到 `.scratch/raw_sheets/`，**不进根目录** |
| B2 | **打开源表目检**格子数与完整性 | 与 prompt 假设一致才继续；否则重生该态 |
| B3 | `process_boss_sheet.py`：`cols/rows`=目检值；`--size 256 --target-h 145`；`prefix=rune_colossus form=statue` | 帧写入 assets（或临时 out） |
| B4 | 像素审计脚本：张数、`edges` 无 LTRB、bbox 宽≤230、无空帧、水印扫描 | 全部 PASS |
| B5 | 拼该态 contact sheet（**≥128px/格**）并与 v4 idle 母版并排目检 | 头/双拳/双腿完整；同一只；动作可读 |
| B6 | 不过 → 回 B1 重生该态（每态最多 2 次额外尝试） | 记录失败原因 |

**建议顺序：** `idle` → `move` → `attack` → `skill` → `hurt` → `death` → `evolve`

#### 阶段 C — 全量与入库

| 步 | 内容 | 验收 |
|----|------|------|
| C1 | 七态全部过 B 门禁 | 全量 contact sheet 目检通过 |
| C2 | Godot `smoke_rune_colossus_statue_frames.gd` | `SMOKE_STATUE_ALL_STATES_OK` |
| C3 | 核对 animator / `.gitignore` | raw/scratch 不进库 |
| C4 | 更新 README 素材进度（仅在帧合格后） | 与磁盘一致 |
| C5 | 小步 commit：帧 + smoke + animator + spec + README | **不混**其它区脏文件 |
| C6 | 用户确认后 Form2 或收尾 | 另开批次 |

#### 门禁定义（交付前强制）

每帧必须同时满足：

1. 头部符文石碑可见（hurt/death/evolve 中后段按动作语义放宽，但不得「无主体空格」）  
2. **双拳**在画面内完整（attack 砸地帧允许一臂在下，但拳不可出画）  
3. 双腿/底座在 idle/move/attack 中完整  
4. `edges` 贴边检测 = 空  
5. 无「AI生成」字样  
6. 与 v4 母版身份一致（色/体量/碑头）  

**禁止：** 仅以 smoke 通过作为完成标准；禁止未目检 present。

### 2.10 第二轮 Form1 规划（2026-09-18 · **只规划，未实施**）

用户复检 `statue_qc_sheet_v2`：**整批不合格**。已停生成。

#### 2.10.1 失败现象（对照 v4 母版）

| 态 | 现象 | 与 v4 |
|----|------|--------|
| idle | 颜色偏浅青灰、胸核巨大菱形、轮廓更「石甲骑士」 | **不是 v4** 暗灰堆石+重苔藓+小核；等于用旧/漂移身份当待机 |
| move | 多帧像半截躯干/蹲团，有紫噪与横线，**无挪步姿势** | 肢体割裂，不能连成走路 |
| attack | 闪光碎片，砸地叙事不清 | 与 idle 不同一只 |
| skill | 小块特效/小人残片，**各格互不连续** | 技能释放割裂 |
| hurt | 三团暗块差异小 | 尚可辨认但不精 |
| evolve | 粉白光爆+竖线杂色，主体常消失 | 过程不可读 |
| death | 前几帧尚可，后段碎石 | 勉强 |

#### 2.10.2 方法根因（为何会「每次都割裂」）

1. **身份锁失效**：idle 用 `image_gen` 整表重生 → 漂到通用石像，**未从 v4 `image_edit`**。  
2. **AI 网格不是动画**：一格一个「点子」，不是同一姿势的中间张；`pick` 填帧只会制造假连贯。  
3. **2×2 复用 + 7/8 帧需求** → 数字上齐了，时间轴仍断。  
4. **特效态（skill/evolve）** 要么主体没了，要么白线/色块；缺「每帧同一只 + 可控 FX 增量」。  
5. QC 图 128px 仍能看出割裂，却曾把像素贴边审计当成合格。

#### 2.10.3 目标验收（第二轮必须同时满足）

1. **身份**：任意态任意帧与 `statue_identity_master_v4.png` 并排为同一只（堆石体量/暗灰+苔藓/小碑头/小胸核）。  
2. **idle**：仅微表情（符核亮度/苔藓微颤），**禁止**换盔甲、改胸核形状。  
3. **move**：可读出**沉重复步**（接触→下沉→过渡→抬起），6 帧无残肢、无紫线。  
4. **attack**：7 帧叙述完整 `stone_smash`（准备→抬臂→砸下→冲击→收）。  
5. **skill**：8 帧一条时间轴；FX 累进；主体始终在。  
6. **evolve/death/hurt**：同一只上变化，禁止「换游戏截图」。  
7. 相邻帧剪影差分可接受（idle/move 小；attack/skill 中；evolve/death 允许大但须连续）。  
8. 像素门禁仍要过（贴边/水印/空帧），但**不能代替 1–7**。

#### 2.10.4 工作流（禁止再批量糊一表）

**Phase 0 — 身份地基（不过不做动作）**

| 步 | 做法 | 出口 |
|----|------|------|
| D0 | 清空 `assets/.../rune_colossus` 草稿（或继续不入库） | 无残帧当交付 |
| D1 | **只做 idle**：`image_edit` **固定 v4**，一次 2×3，**只允许**核亮度/苔藓微颤；禁止换材质 | 6 帧 idle strip |
| D2 | 与 v4 并排 **用户签字** 后才开 move | 门禁 |

**Phase 1 — 动作按「关键帧剧本」单点生成**

每态先写 **beat 表**（几拍、每拍姿势描述、剪影变化量级），再：

| 步 | 做法 |
|----|------|
| K1 | **每拍单独** `image_edit`：输入 = **v4 + 上一张已接受帧**（identity-preserve / continuity） |
| K2 | 一次只出 **1 帧**（最多 1×2 极近姿势），**禁止**一张表塞 8 个不同点子 |
| K3 | 出一张 → 目检（完整+连续）→ 接受才做下一拍；漂了回炉该拍 |
| K4 | 凑满契约张数（可含 hold 帧：接受帧的安全微差/重复），**禁止**用残片填数 |
| K5 | 每态做完拼 **横向 strip** 自检连续，再进下一态 |

**Phase 2 — 态顺序与 beat 数（契约张数不变）**

| 顺序 | 态 | 张数 | beat 剧本（实施时写入本节附录） |
|------|----|------|--------------------------------|
| 1 | idle | 6 | 静止循环 2 拍 × 微变 |
| 2 | move | 6 | 复步 4 关键 + 2 hold |
| 3 | hurt | 3 | 受击→裂纹→回稳 |
| 4 | attack | 7 | stone_smash 全叙事 |
| 5 | skill | 8 | chain/tomb 能量一条轴 |
| 6 | death | 6 | 崩解到堆 |
| 7 | evolve | 8 | 同一只上的过载→解体 |

**Phase 3 — 全量**

像素门禁 + 全量 strip 目检 + smoke + 用户终检 → 才 commit/改 README。

#### 2.10.5 明确禁止

- 未 D2 签字就批量 move/attack  
- `image_gen` 无母版换角重生动作表  
- 一张网格 ≥4 个差异大姿势  
- 用 smoke 或贴边审计单独宣布合格  
- 把当前 `statue_qc_sheet_v2` 批次入库  

#### 2.10.6 本规划阶段 Out of Scope

- 实际出图/切帧  
- Form2  
- commit 草稿帧  

### 2.11 最小闭环（2026-09-18 用户拍板 · 优先于一切并行方案）

1. **只认 v4**；禁止多套母版并行。  
2. **一次 1 态、签字后才下一态**；顺序 idle → move → hurt → attack → skill → death → evolve。  
3. **禁止**多格不同姿势网格；宁可少帧假变化，不要换角。  
4. idle 优先：**v4 直接进引擎帧 + 仅核心亮度微变**（身份 100% 锁）；不够再逐张 `image_edit`。  
5. 动作态：单张完整角色；透明底优先，失败再洋红。  
6. 视频仅参考，不进主管线。  
7. 合格才 commit；`assets` 不留未签字草稿当「已完成」。

### 2.12 Out of Scope（本闭环）

- Form2、gate、视频抽帧入库、批量七态、push

### 2.13 move 六帧 beat（用户要求：脚姿 + 伏笔，禁止平滑滑步）

| 帧 | 名称 | 要求 |
|----|------|------|
| 00 | 蓄势下压 | 双膝微屈、重心下压、双拳略前合；**预备感** |
| 01 | 左脚提起 | 左足离地数格，右腿承重，身体微倾 |
| 02 | 左脚踩落 | 左足砸地接触，肩胯反向微扭，尘点 |
| 03 | 中段过 | 双脚皆近地，胯从右移向左 |
| 04 | 右脚提起 | 右足离地，左腿承重，臂随之摆 |
| 05 | 右脚踩落+回稳 | 右足踩实，回到宽站距，肩胯回正 |

禁止：六张仅整体水平位移；禁止脚不动只滑行。身份锁 v4。

### 2.14 朝向 / 玩家左右（实际战斗因素）

| 层 | 约定 |
|----|------|
| 美术默认 | **画面左侧为前方**（非 bee Boss 一律面向左） |
| 运行时 | `flip_h = (direction > 0)`（`boss_animator.compute_flip_h`） |
| 玩家在左 | `direction=-1`，不镜像；冲击画在原图**左前** |
| 玩家在右 | `direction=+1`，水平镜像；左前冲击自动到右侧，仍打向玩家 |
| `stone_smash` | 预告线 `global_position + Vector2(direction * 150, 0)`，始终在玩家一侧 |
| 弹幕 | 多数 `angle_to_point(player)`，左右皆可 |

**素材要求：** attack/skill 前摇与地面 FX 画在**原图左前**；禁止只画右后冲击（镜像后会砸向背对玩家侧）。

**已核：** 当前 attack 00–03 冲击尘在原图左下，与引擎 `direction` 约定一致。

**代码债（非本素材）：** `hawk_roar` 朝右扇形三元塌缩，属 `elite_boss` 逻辑问题。

## Tasks

- [x] Q1: 确认最小闭环方法  
- [x] Q2: idle 六张（v4 锁身份）— 用户认可「几乎一样」作 idle  
- [ ] Q3: move 六帧脚姿+伏笔 — acceptance: strip 用户签字（covers: 2.13）  
- [ ] Q4: hurt → attack → skill → death → evolve — 每态签字  
- [ ] P11–P12: 全量 smoke + commit 只 stage ruins  

（旧批量七态任务作废）

## Tasks

### 计划与规矩

- [x] P1: 更新本 spec 根因与重做计划 — acceptance: §1.1/§2.8 完整（covers: S2.8A）
- [x] P2: `AGENTS.md` 写入素材视觉 QC 门禁 — acceptance: 仓库指令含门禁摘要（covers: S2.8A）
- [x] P3: 首轮残缺帧迁出 assets — acceptance: 44 帧在 `.scratch/rejected_statue_v1/`（covers: S2.8A3）
- [x] P4: idle — acceptance: 6 帧 edges=- 宽≤230；源表 2×3 目检通过（covers: S2.8B）
- [x] P5: move — acceptance: 6 帧过像素门禁（covers: S2.8B）
- [x] P6: attack — acceptance: 7 帧过像素门禁（covers: S2.8B）
- [x] P7: skill — acceptance: 8 帧过像素门禁（covers: S2.8B）
- [x] P8: hurt — acceptance: 3 帧过像素门禁（covers: S2.8B）
- [x] P9: death — acceptance: 6 帧过像素门禁（covers: S2.8B）
- [x] P10: evolve — acceptance: 8 帧 edges=- 且宽≤230 — 复验通过（超宽帧已 LANCZOS 缩至 ≤227 并居中）（covers: S2.8B）
- [ ] P11: 全量 smoke + 门禁汇总 + 用户目检 — acceptance: smoke PASS 且用户认可 QC 图（covers: S2.8C）
- [ ] P12: README + 小步 commit — acceptance: 只 stage ruins 相关（covers: S2.8C）

### 单态重做（串行）

- [ ] P4: idle 网格+切帧+审计+目检 — acceptance: 6 帧过门禁（covers: S2.8B）
- [ ] P5: move — acceptance: 6 帧过门禁（covers: S2.8B; depends: P4）
- [ ] P6: attack — acceptance: 7 帧过门禁，砸地可读（covers: S2.8B; depends: P4）
- [ ] P7: skill — acceptance: 8 帧过门禁（covers: S2.8B; depends: P4）
- [ ] P8: hurt — acceptance: 3 帧过门禁（covers: S2.8B; depends: P4）
- [ ] P9: death — acceptance: 6 帧过门禁（covers: S2.8B; depends: P4）
- [ ] P10: evolve — acceptance: 8 帧过门禁（covers: S2.8B; depends: P4）

### 全量与提交

- [ ] P11: 全量 smoke + 门禁汇总 — acceptance: `SMOKE_STATUE_ALL_STATES_OK` 且审计表全 PASS（covers: S2.8C）
- [ ] P12: README + 小步 commit — acceptance: 只 stage ruins 相关；gitignore 已核（covers: S2.8C3–C5）

### 历史（已确认事项）

- [x] M1: Form1 母版 v4 用户确认锁定
- [x] M2: 体量/符文方向经 v2–v4 迭代确认
- [ ] ~~首轮七态直接交付~~ — **QC 失败，不作为完成**

## Tasks（旧清单存档，以 P 系列为准）

### 2.2 身份铁律（用户定稿 · Form1 苔石守卫像 · v2 修订）

用户对 v1 样图反馈（必须落实）：

1. **不够笨重、无压迫感** — 轮廓更宽更低、堆石体量更大，像遗迹建筑而非人形装甲。  
2. **身体过干净** — 苔藓覆盖要明显增多（仍不淹没石材）。  
3. **脸不要人类特征** — 禁止人眼/口鼻/人脸；头部改为**石板/石碑面**，中央刻**发光符文**（青绿）。  
4. **身体颜色过蓝** — 按原提示词与参考图：**暖灰/岩灰/深灰/黑灰**为主，**不要蓝灰/青蓝身体**；能量只保留符核与符文的青绿。  
5. **体现古老与神秘** — 风化堆石、裂纹、垂落苔藓、石面方块迷宫符文；气质沉睡数百年。

**参考图规格（用户附概念图，只取造型/配色，不要场景与标题字）：**

- 体量：极宽肩、几乎无颈、双臂如石柱，拳/脚有**方形回纹（迷宫）符文**。  
- 头：顶部一块**竖立石碑/石板**，中央青绿几何符文，无五官。  
- 胸：圆形符核，周围碎石环。  
- 石色：偏暖的灰褐/青灰花岗岩堆叠块，不是发蓝涂装。  
- 苔藓：肩、臂、胸腹、腿大量深绿/黄绿苔与垂蔓。  
- 姿态：静止、沉重、微俯，压迫感来自体量而非表情。

**仍强制：**

- 洋红 `#FF00FF` 纯底、3/4 全身、像素硬边、无文字水印、无场景。  
- 无武器/披风/翅膀；悬浮碎石极少。  
- 后续战斗帧唯一身份参考 = 确认后的 v2 母版。

- 远古遗迹沉睡的**堆石巨像**；非人类战士、非纤细、非 Q 版、非光滑新雕像。
- **重量感优先**：肩极宽、胸巨大、双臂异常粗壮（轮廓核心）、腰厚、腿粗短、重心极低。
- **符文石碑头**（替代人脸）：石板中央发光符文；可另有眼部位置的细长符文缝，但**不得像人脸**。
- **石材**：暖灰/深灰/岩灰/黑灰花岗岩堆块；裂纹、风化、接缝、断裂；**禁止偏蓝身体**。
- **苔藓**（核心识别，v2 加强）：肩/背/臂/胸/腰/膝/腿/头缘明显覆盖，深绿/暗绿/黄绿，部分垂落。
- **胸口符核**：圆形古代符文核，青绿/蓝绿+冷白高光，克制发光。
- **方块迷宫符文**：拳面/脚面/前臂少量青绿回纹石刻（参考图），与符核同色系。
- **姿态**：静止站立、双拳垂握、头略低；禁止攻击/施法/跳/跑。

### 2.2c v3 体量硬指标（用户确认差距后实施）

v2 相对参考图仍不够笨重；v3 必须满足：

| 指标 | 目标 |
|------|------|
| 剪影 | 超宽超矮「遗迹石墙」，非石像人形 |
| 肩宽 | 约画幅 70–80%；角色总宽 85–90% |
| 拳 | 高度 ≥ 石碑头；外缘接近安全边下部 |
| 头/碑 | 约总高 15–20%，禁止大头碑 |
| 胸核 | 直径约拳宽 1/3–1/2，内嵌 |
| 腿 | 极短，脚如底座，埋进石堆 |
| 轮廓 | 允许不规则外凸碎石堆叠 |
| Form 反差 | Form1 超重 ↔ Form2 瘦人形（`sage`） |

色/苔藓/符文碑/洋红底沿用 v2 定稿；体量按 v3。

**v4 增量（用户）：** 在 v3 剪影上**适当增加古老符文元素**（拳/肩/胸石/腿/头碑边缘），增强古老与神秘；不得改成满身文字，不得破坏体量与暖灰石材。

### 2.3 美术输出要求（本阶段）

- 16-bit 风高质量 **2D 像素** Boss 立绘；硬边、深色描边、像素级阴影与岩石纹理块。
- 禁止：抗锯齿、平滑渐变、3D/照片/油画/普通动漫/Q 版。
- 构图：单角色、3/4、全身（含双臂双腿头）、符核可见；居中约 **65–70%**；顶底安全边；不裁切。
- **背景 100% 纯 `#FF00FF`**。
- **禁止画面内任何文字/UI/边框/标签/场景/建筑/地面/其他角色/武器**；**禁止「AI生成」水印字样**。
- 只生成一张 Form1 标准样图；不要多帧/动作分镜/技能/设定卡。

### 2.4 水印与入库

| 步 | 操作 |
|----|------|
| 生成 | prompt 明确 no text / no watermark / no 「AI生成」 |
| 检查 | 目检右下角与四角 |
| 去除 | 若仍有平台字样：用 `tools/scrub_engine_watermark.py` / `scrub_ai_watermark.py` 或等价像素清理；**不得破坏主体与洋红底** |
| 归档 | 拷贝为 `data/monsters/raw/statue_identity_master_v3.png`（不进 git） |
| 临时图 | 会话生成文件不进仓库根；不 commit raw |

### 2.5 用户确认门

**已通过：** 用户确认 v4 可作为 Form1 身份母版 → 可开七态。

七态引擎帧契约（`BOSS_FRAME_STATES`，不改）：

| 状态 | 帧数 | Form1 `statue` 动作含义 |
|------|------|-------------------------|
| idle | 6 | 沉睡守卫待机：符核微明、苔藓轻颤、碎石微浮 |
| move | 6 | 沉重挪步/短距推进；可复用 idle 变体，强调质量 |
| attack | 7 | **stone_smash 单臂砸地**：抬臂→砸地→石波余震 |
| skill | 8 | 技能表现：**chain_burst 苔石锁链** 或 **tomb_drop 石棺压顶** 预告式爆发（一形态 skill 槽需兼顾两技能气质） |
| hurt | 3 | 受击：碎石飞溅/裂纹扩光/后仰微滞 |
| evolve | 8 | 符文全亮→形体解体重铸（过渡到 Form2 的仪式感） |
| death | 6 | 崩塌：跪落→堆石溃散→符核熄灭 |

输出：`assets/sprites/monsters/rune_colossus/rune_colossus_statue_{state}_{ii}.png`  
画布：**256×256**；流程：`image_edit`+v4 母版网格 → 抠图 → 去水印 → smoke → animator ruins scale。

### 2.5b 用户确认门

样图目检通过（身份/比例/符核/苔藓/无水印/洋红底）→ **用户点头** 后才锁母版并开七态/`image_edit` 网格。未确认前禁止批量动作表。

### 2.6 交付切分

| 批次 | 内容 | 状态 |
|------|------|------|
| P0 | 本 spec + task | 本阶段 |
| P1 | Form1 标准样图 + 去水印 + 归档 raw | 本阶段 |
| P2 | 用户确认后 Form1 七态 + smoke + animator | **进行中：用户选择直接全七态** |
| P3 | Form2 `sage` 样图与七态 | 更后 |
| P4 | 只 stage canyon 式 ruins 路径 commit；更新 README | 随引擎帧交付 |

### 2.7 本阶段 Out of Scope

- 七态切片、`process_boss_sheet` 批量、改技能数值/碰撞  
- Form2 `sage`  
- 将母图 commit 进 `assets/`  
- push（用户网络/时机自定）

## Tasks

- [x] T1: 写入本 spec — acceptance: 身份要点/水印/ignore/README 约束齐全（covers: S1/S2）
- [x] T2: 生成 Form1 标准样图 — acceptance: 单帧、洋红底、无动作分镜（covers: S2.3）
- [x] T3: 水印检查与去除 — acceptance: 磁盘像素无「AI生成」角标；主体完整（covers: S2.4）— 备注：MiMo 预览层可能仍叠加展示水印，**文件数据已清洗**
- [ ] T4: 归档母版并提交用户确认 — acceptance: `statue_identity_master_v1.png` 在 raw；present 给用户（covers: S2.4/2.5）
- [x] T5: Form1 七态管线（初版） — acceptance: 44 帧 256 + `SMOKE_STATUE_ALL_STATES_OK` + animator ruins 适配；**待用户目检后 commit**（covers: S2.6）
