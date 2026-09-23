---
feature: gate-sky-whale-sprites
status: delivered
updated: 2026-09-19
branch: feat/male-hero-select
commits: 
---

# 星门审判者 sky_gatekeeper · 第六 Boss 素材

> 区域：**第六 Boss · 天穹之门 gate**（`REGION_ORDER` 第 6 区）。  
> Form1 `whale` 虚空星鲸 / Form2 `judge` 星门审判者。  
> 当前阶段：**Form2 `judge` 重复帧重做**（idle/move/attack 保留；hurt/skill/death/evolve 重生）。

## Report

- Form1 `whale` 44 帧已交付并 commit；smoke `SMOKE_WHALE_ALL_STATES_OK`。
- Form2 `judge` 44 帧：首版 MD5 审计失败后按 `gate-judge-frame-rework.md` 重做 hurt/skill/death/evolve；现网 **44 MD5 互异** + `SMOKE_JUDGE_ALL_STATES_OK`。
- 自检教训：smoke/贴边审计抓不住「跨态字节相同」；交付前必须跑 `tools/check_judge_frame_uniq.py`。

## [S1] Problem

### 1.1 原始缺口（已完成）

`gate.tres` / `world_maps.gd` 已有 `sky_gatekeeper` 两形态与技能（`tail_wave` / `void_whirl` / `star_tide` 等），但无 `assets/sprites/monsters/sky_gatekeeper/`，运行时回退 painter。Form1 身份样图与 44 帧已补齐。

### 1.2 Form2 `judge` 重复帧（本阶段要修）

MD5 审计证明 `judge` 多态为 **attack 的字节复制品**（批量 `image_edit` + 切片复用同一源文件导致）：

| 态 | 结论 |
|----|------|
| idle 00–05 | 6 唯一 — **保留** |
| move 00–05 | 6 唯一 — **保留** |
| attack 00–06 | 7 唯一（砸剑/冲击语义）— **保留，作对照** |
| skill 00–06 | **= attack 00–06**；skill07 唯一 |
| hurt 00–02 | **= attack 00–02** |
| death 00–02 | **= attack 00–02**；death 03–05 唯一 |
| evolve 00–02 | **= attack 00–02**；evolve 03–05 **= death 03–05**；evolve 06–07 唯一 |

须重生：**hurt3 + skill8 + death6 + evolve8 = 25 帧**，与 attack 语义/哈希均不同。

## [S2] Design

### 2.1 Form1 `whale` 身份（用户定稿）

| 项 | 要求 |
|----|------|
| 轮廓 | **巨型鲸鱼**：横向宽大、头大圆额宽嘴、躯干厚重、尾渐窄；非鱼/海怪/龙/飞船 |
| 头 | 宽圆鲸额、宽厚嘴；**两**小眼（淡金/淡蓝/冷白微光）；古老平静冷漠 |
| 材质 | 深蓝星云/黑曜/深海鲸皮；像素星点成「星河纹理」；禁照片星空 |
| **胸口星核** | 核心识别：中央偏前巨大多层同心核（白/淡金/青蓝），深蓝紫能量纹 + 发光裂纹；像封存的微型恒星 |
| **背部星门** | 第二识别：背中后小环门（体高 1/3–1/2），同心环、内虚空、细星、几何符文；属身体一部分，非巨型传送门 |
| 尾 | **鲸尾鳍**（非鱼叉尾），宽展开；星河裂纹；供「尾鳍三层星波」 |
| 胸鳍 | 宽大鲸鳍，边缘微透明+星尘；无额外翅膀 |
| 虚空 | 少量贴身星尘/黑粒/微扭曲；禁爆炸/大光环 |
| 姿态 | 缓慢悬浮微弧、头略朝镜头、核与星门可见、尾鳍后展、胸鳍展；禁攻击/下潜/开大星门 |
| 色 | 主深蓝/蓝黑/靛青/深紫；核星门淡金青蓝冷白；低饱和 |
| 画布 | 单帧 3/4 全身；主体 65–70%；**尾鳍/胸鳍/星门不裁切** |
| 底 | **100% `#FF00FF`**；禁宇宙场景/文字/UI/多帧 |
| 母版 | 确认后 `data/monsters/raw/whale_identity_master_v1.png` |
| 引擎帧（后续） | `sky_gatekeeper_whale_{state}_{ii}.png`；朝向 § Form1 ruins 2.14 同类（美术朝左+flip） |

### 2.2 最小闭环（Form1，已完成）

样图签字 → 七态单帧+自检 → smoke → 小步 commit。不改 `BOSS_FRAME_STATES`。

### 2.3 Form2 `judge` 重复帧重做设计

**保留不动**：`judge_identity_master_v3.png` 身份；idle / move / attack 全部引擎帧。

**必须重生**（与 attack 砸剑语义分离）：

| 态 | 帧数 | 语义节拍（禁止贴 attack 砸剑） |
|----|------|--------------------------------|
| hurt | 3 | 后仰护甲受击：00 甲面受击闪光+上身后折，01 剑臂外甩失衡，02 半回稳前倾 |
| skill | 8 | 星门蓄能→横扫/裁定波：00–02 低势蓄力（冠羽/披风上扬），03–04 门盘爆亮+剑举，05–06 横斩能量弧，07 收势 |
| death | 6 | 剑脱手→跪倒→消散：00–01 松剑前倾，02–03 单膝跪地甲裂，04–05 跪倒消散/门盘熄灭 |
| evolve | 8 | 升空重组：00–02 被光托起离地，03–05 门盘全开+甲片重排，06–07 悬浮归位握剑 |

**管线（强制）**：

1. 将现网重复帧备份至 `.scratch/rejected_judge_dupes/`（勿删资产目录历史对照）。
2. **每次工具调用只 `image_edit` 一帧**；源图恒为 `data/monsters/raw/judge_identity_master_v3.png`（1536×1024）。
3. 生成后立刻 `process_boss_sheet`/fit 到 256 画布（`target_h≈140–150`，内容 bbox 宽 ≤230），再进 `assets/sprites/monsters/sky_gatekeeper/`。
4. 禁止 `fs[:N]` 批量切片复用；禁止一次调用出多态。

**验收门禁（全过才允许 commit）**：

1. 全 44 个 `sky_gatekeeper_judge_*.png` **MD5 两两互异**（含与 attack/死亡对照）。
2. 贴边 `edges` 为空；无空帧；右下无「AI生成」水印。
3. 内容 bbox 宽 ≤230；与母版同一只（冠/剑/门盘/星核）。
4. 目检 contact sheet（格宽≥128）：hurt/skill/death/evolve 与 attack 动作语义可分。
5. `tools/smoke_sky_gatekeeper_judge_frames.gd` → `SMOKE_JUDGE_ALL_STATES_OK`。
6. README 与 spec Report 勾选一致。

## [S3] Out of Scope

- 改技能数值、push（默认不 push）
- Form1 `whale` 重做
- 重绘 `judge` 母版（cape 二次运动只在动作帧出现）

## Tasks

- [x] W1: 本 spec
- [x] W2: Form1 标准样图 + 自检
- [x] W3: 用户确认锁母版 `whale_identity_master_v1.png`
- [x] W4: Form1 七态
- [x] W5: smoke + README + commit
- [x] J1: Form2 `judge` 标准样图 — 鹰羽冠重甲骑士 + 巨剑 + 背后星门圆盘；胸口星核承 Form1
- [x] J2: 用户确认锁母版 `judge_identity_master_v3.png`
- [x] J3a: idle/move/attack 生成 + commit（31f28dc / c173927）
- [x] J3b: 先前七态批量提交（skill/hurt/death/evolve）— **MD5 失败，作废**
- [x] R1: 备份重复帧 → `.scratch/rejected_judge_dupes/`
- [x] R2: 重生 hurt3（逐帧 image_edit + fit256）
- [x] R3: 重生 skill8（逐帧）
- [x] R4: 重生 death6（逐帧；03–05 若语义可用可只换与 attack/death 相同的前 3 帧，但 MD5 仍须全局唯一）
- [x] R5: 重生 evolve8（逐帧；不得再与 attack/death 字节撞车）
- [x] R6: 全 44 帧 MD5 唯一 + 贴边/bbox/水印/目检
- [x] R7: smoke `SMOKE_JUDGE_ALL_STATES_OK` + README + 小步 commit（只 stage sky_gatekeeper 路径）

### Form2 `judge` 要点（用户定稿摘要）

高大重甲星门骑士（非刺客/轻甲）；**鹰羽金属冠**（承尾鳍流线）；面甲全遮+双星光裂目；星辰重甲+星云纹理；**胸口星核**（甲中开窗）；巨肩甲（鳍/翼感）；**双手星辰大剑**（近身高、剑格星门环、柄端小核）；**背后巨星门圆盘**（约肩宽 1.4–1.6 倍、虚空星海）；金属羽片背饰非真翼；重型腿甲；**剑尖朝下静立**；洋红底单帧。

母版：`data/monsters/raw/judge_identity_master_v3.png`。Prompt 注意：禁用易触发内容审查的措辞（如 judgment）；生成安全边（角色不贴格边）；`--size 1536x1024`。
