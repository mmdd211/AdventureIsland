---
feature: project-standardization
status: delivered
updated: 2026-09-18
branch: master
commits: 0a0bdc819eaa89c80e1d8cc1000f6bd5ad3f3e21..b2f8737e87eb377996c7a4e33814a4eb9be40b41
---

# 工程规范化包

## Report

**What was built** — 为 AdventureIsland 落地「规格化工程」第一包：仓库根新增 `AGENTS.md`（用户八耻八荣 + 目录契约 + 提交/自测/任务清单工作流）；根目录 9 张 `generated-*.png` 与 `tmp_banbu`/`_cast_*`/`output` 等临时物迁入 gitignore 的 `.scratch/`；`.gitignore` 补 `.scratch/` 与 `output/`；根 `README.md` 纠正为「运行时像素 + 外部 Boss/角色帧」双轨描述；`tools/README.md` 标明推荐入口 `sprite_pipeline.py`、活跃 smoke 与 legacy 边界；入库审计/修复脚本；`output` 中 prompt 归档至 `docs/pipeline/`，版本库不再跟踪 `output/`。

**Verification** —  
- 根目录 `generated-*.png` 计数 = 0；`.scratch/generated` = 9  
- `AGENTS.md` 存在  
- Godot headless `smoke_canyon_eagle_frames.gd` → `SMOKE_EAGLE_ALL_STATES_OK`（exit 0）  
- commit `b2f8737` 仅含规范化相关路径  

**Journey log** —  
1. spec 负责验收账本，**task 工具**负责执行进度；两者都要用，不能只写 markdown 计划。  
2. 生成图堆在仓库根是最直观的「乱」；`.scratch/` 伞目录 + gitignore 比到处 `tmp_*` 可控。  
3. 有用工具未入库 = 换机器即丢（荣1/2）；一次性脚本应标明 legacy 而非沉默平铺。  
4. README 若仍写「无需外部美术」会误导后续协作；文档必须与当前管线一致（荣6）。  
5. 规范化只动文档/目录/工具入库，不借机大改游戏逻辑（荣4 最小变更）。

## [S1] Problem

主角与前 4 Boss 形象升级完成后，工程未同步「规格化」：根目录残留生成图与临时目录；`tools/` 一次性脚本平铺；无仓库内项目指令；根 README 与外部帧管线不符；执行层曾只写 spec 而未稳定使用 task 清单。

## [S2] Design

### 2.1 工程原则

用户「八耻八荣」全文写入 `AGENTS.md`，作为项目默认协作规则。

### 2.2 目录契约

| 类型 | 位置 | Git |
|------|------|-----|
| 运行时引擎帧 | `assets/sprites/monsters/<prefix>/` | 跟踪 |
| 生成原稿/母版/QA | `data/*/raw/` | 忽略 |
| 本地临时 | `.scratch/` | 忽略 |
| 管线说明/prompt | `docs/pipeline/` | 跟踪 |
| 功能 spec | `docs/compose/spec/*.md` | 跟踪 |
| 活跃工具 | `tools/` + `tools/README.md` | 跟踪 |

**禁止**项目根目录长期堆放 `generated-*.png` 与临时预览。

### 2.3 本轮文件收口

- 根 `generated-*.png` → `.scratch/generated/`
- `tmp_banbu/`、`_cast_*_temp/`、`output/` → `.scratch/`
- 移除空文件 `_screenshot_banbu.gd`
- prompt → `docs/pipeline/player-hero-prompt.txt`
- 审计/修复 tools 入库；README 分层说明

### 2.4 指令与文档

`AGENTS.md` + 根 README + `.gitignore` + `tools/README.md` 按契约更新。

### 2.5 工作方式

多步改动：spec（如需）→ **task 清单** → 技能优先 → 小步 commit → smoke 自测 → finalize。

### 2.6 Out of Scope

- ruins/gate 素材、dancer 关账、大文件拆分、`hawk_roar`、push

## Tasks

- [x] T1: 写入本 spec — acceptance: 目录契约与收口范围明确（covers: S2）
- [x] T2: 写入 `AGENTS.md` — acceptance: 含八耻八荣、目录表、验证与提交约定（covers: S2.1/2.4/2.5）
- [x] T3: 根目录与临时目录收口 — acceptance: 根无 `generated-*.png`；临时物在 `.scratch/`（covers: S2.2/2.3）
- [x] T4: tools 整理与 README — acceptance: 推荐入口清晰；有用脚本已入库（covers: S2.3）
- [x] T5: `.gitignore` + 根 README — acceptance: ignore 覆盖 scratch；README 与管线一致（covers: S2.4）
- [x] T6: 验收与 commit — acceptance: `b2f8737` 入库；根目录无生成图；smoke PASS（covers: S2.5）
