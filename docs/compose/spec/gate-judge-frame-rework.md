---
feature: gate-judge-frame-rework
status: delivered
updated: 2026-09-19
branch: feat/male-hero-select
commits: 
---

# Form2 judge 动作帧去重重做

## Report

**What was built** — `sky_gatekeeper` Form2 `judge` 重复帧去重重做：保留 idle/move/attack 语义，重生 hurt3+skill8+death6+evolve8（25 帧，逐帧 `image_edit` + `process_boss_sheet` 256）。新增 `tools/check_judge_frame_uniq.py`。顺带对 idle/move/attack 清掉洋红残留并重居中（姿态未改）。

**Verification** — `CHECK_JUDGE_UNIQ_OK`（44 MD5 两两互异）；`audit_sprite_rect_borders` flagged=0；内容 bbox 宽 ≤230；BR 无水印；contact sheet 目检七态语义可分；`SMOKE_JUDGE_ALL_STATES_OK`。

## [S1] Problem

MD5 自检发现 `sky_gatekeeper_judge_*` **大面积跨态重复**，动画语义不成立：

| 路径 | 实际 |
|------|------|
| `skill_00..06` | 与 `attack_00..06` **同文件** |
| `hurt_00..02` | 与 `attack_00..02` **同文件** |
| `death_00..02` | 与 `attack_00..02` **同文件** |
| `evolve_00..02` | 同 attack 00–02 |
| `evolve_03..05` | 同 `death_03..05` |
| `idle` / `move` / `attack` | 各自独立，可保留 |

根因：批量出图后按「取前 N 张」入库，未做 **跨态 MD5 门禁**；smoke 只验张数，不能发现重复。

后果：受伤/技能/死亡/进化在游戏里会像同一套挥砍，**动作差异不成立**。

## [S2] Design

### 2.1 保留 / 重做

| 处理 | 内容 |
|------|------|
| **保留** | `idle_00..05`、`move_00..05`、`attack_00..06`（唯一挥砍/砸击源） |
| **移出** | 假 `hurt/skill/death/evolve` 全部移入 `.scratch/rejected_judge_dup/`（不删历史） |
| **重做** | hurt×3、skill×8、death×6、evolve×8 = **25 张**，每张独立生成 |

### 2.2 硬门禁（入库前脚本，不过不 commit）

1. **跨态 MD5 全局唯一**：44 张 `sky_gatekeeper_judge_*` 两两不同。  
2. 同态相邻帧 MD5 不同；与 `idle_00`/`attack_03` 的像素采样差 ≥ 阈值（防「换皮不换姿」）。  
3. `edges` 无贴边；内容 bbox 宽 ≤230；无空帧。  
4. 姿态语义目检：hurt≠attack 剪影；skill 有盘/链；death 有跪/堆；evolve 有过载/解体。

### 2.3 生产节奏（防再次串文件）

- **一次只生成 1 张**，落地后立刻改名到目标态文件名并记 MD5。  
- 禁止：一次出多张再 `fs[:N]` 分配。  
- 身份锁 `judge_identity_master_v3.png`；FX 偏左前（§2.14 同类）。  
- 每态完成即跑门禁脚本，再进下一态。

### 2.4 Beat 表（与 attack 00–06 必须不同剪影）

**hurt×3**  
00 前倾受击、披风后甩、碎屑向后 → 01 胸核闪裂、身体微蹲蜷 → 02 回稳半步、披风回落  

**skill×8**（星门裂隙 / 天穹光，非挥剑）  
00 低势蓄能、盘环暗 → 01 盘全亮 → 02 左前裂隙线 → 03 光柱落下 → 04 峰值盘爆 → 05 环冲击 → 06 碎光回落 → 07 收势  

**death×6**  
00 灯灭跪 → 01 头垂臂垮 → 02 剑脱手触地 → 03 胸核熄裂 → 04 甲片塌成堆 → 05 布甲与残盘余烬  

**evolve×8**  
00 双核全亮站定 → 01 过载光翼/盘环胀 → 02 甲片掀起 → 03 星屑剥离 → 04 光爆（暗核）→ 05 向内坍缩 → 06 重铸光团 → 07 回到近站姿收束  

### 2.5 与 gate 其它工作边界

- 不重做 idle/move/attack、whale、ruins。  
- 不改技能数值；smoke 文件可复用 `smoke_sky_gatekeeper_judge_frames.gd`。  
- 不 push。

## [S3] Out of Scope

- Form2 外观再改、视频抽帧、gate 改关、全文档大重构

## Tasks

- [x] R1: 移出重复 hurt/skill/death/evolve 到 `.scratch/rejected_judge_dupes/` — acceptance: assets 仅剩 idle+move+attack 25 帧（covers: 2.1）
- [x] R2: 写入 `tools/check_judge_frame_uniq.py` 门禁 — acceptance: 对现网 25 帧 PASS；对假全集会报 FAIL（covers: 2.2）
- [x] R3: hurt×3 独立生成+门禁 — acceptance: MD5 与 attack 全不同；hurt 剪影≠attack（covers: 2.3/2.4）
- [x] R4: skill×8 独立生成+门禁 — acceptance: 含盘/裂隙语义；全唯一（covers: 2.3/2.4）
- [x] R5: death×6 独立生成+门禁 — acceptance: 跪/塌/堆；全唯一（covers: 2.3/2.4）
- [x] R6: evolve×8 独立生成+门禁 — acceptance: 过载/剥离/重铸；全唯一（covers: 2.3/2.4）
- [x] R7: 全量 44 张门禁 + `SMOKE_JUDGE_ALL_STATES_OK` — acceptance: 0 重复；smoke PASS（covers: 2.2）
- [x] R8: 更新 README/gate spec 状态并 commit — acceptance: 只 stage judge 帧/工具/文档（covers: S3 边界）
