---
feature: gate-sky-whale-sprites
status: in-progress
updated: 2026-09-18
branch: master
commits: 
---

# 星门审判者 sky_gatekeeper · 第六 Boss 素材

> 区域：**第六 Boss · 天穹之门 gate**（`REGION_ORDER` 第 6 区）。  
> Form1 `whale` 虚空星鲸 / Form2 `judge` 星门审判者（后续）。  
> 本阶段：**Form1 标准样图**，不做动画。

## Report

## [S1] Problem

`gate.tres` / `world_maps.gd` 已有 `sky_gatekeeper` 两形态与技能（`tail_wave` / `void_whirl` / `star_tide` 等），但无 `assets/sprites/monsters/sky_gatekeeper/`，运行时回退 painter。需先锁 Form1 虚空星鲸身份样图。

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

### 2.2 最小闭环

样图签字 → 七态单帧+自检 → smoke → 小步 commit。不改 `BOSS_FRAME_STATES`。

## [S3] Out of Scope

- Form2 `judge` 七态、改技能数值、push

## Tasks

- [ ] W1: 本 spec — covers: S2
- [ ] W2: Form1 标准样图 + 自检 — acceptance: 鲸轮廓/核/星门/尾鳍完整；洋红底；无水印
- [ ] W3: 用户确认锁母版 — depends: W2
- [ ] W4: Form1 七态 — depends: W3
- [ ] W5: smoke + README + commit — depends: W4
