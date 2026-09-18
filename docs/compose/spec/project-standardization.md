---
feature: project-standardization
status: in-progress
updated: 2026-09-18
branch: master
commits: 
---

# 工程规范化包

## Report

## [S1] Problem

主角与前 4 Boss 形象升级完成后，工程未同步「规格化」：根目录残留大量 `generated-*.png` 与临时目录；`tools/` 一次性脚本平铺；无仓库内项目指令（八耻八荣/目录约定）；根 README 仍描述「纯运行时像素、无需外部美术」，与 Boss 外部帧管线不符；执行层曾只写 spec 而未稳定使用 task 清单。

## [S2] Design

### 2.1 工程原则（写入 AGENTS.md）

用户「八耻八荣」全文入库，作为本项目默认协作规则；另附文件/资产/提交/验证约定。

### 2.2 目录契约（生成物必须归位）

| 类型 | 位置 | Git |
|------|------|-----|
| 运行时引擎帧 | `assets/sprites/monsters/<prefix>/…` | 跟踪 |
| 玩家运行时帧 | `assets/…`（现有结构） | 跟踪 |
| 生成原稿/母版/QA | `data/monsters/raw/`、`data/player/raw/` | **忽略** |
| 本地临时/一次性 | `.scratch/`（统一伞目录） | **忽略** |
| 管线说明与 prompt 归档 | `docs/pipeline/` | 跟踪 |
| 功能 spec | `docs/compose/spec/*.md` | 跟踪 |
| 活跃工具 | `tools/*.py|gd` + `tools/README.md` | 跟踪 |
| 历史一次性脚本 | `tools/legacy/` 或 `tools/_*.py` | 按 ignore 策略 |

**禁止**：项目根目录长期堆放 `generated-*.png`、临时预览、空脚本。

### 2.3 本轮文件收口

- 根目录 `generated-*.png` → `.scratch/generated/`
- 根级已 ignore 的临时目录（`tmp_banbu/`、`_cast_*_temp/` 等）→ `.scratch/` 下同名子目录
- 空的根文件 `_screenshot_banbu.gd`：从版本库移除（若无引用）
- `output/`：prompt/过程稿迁入 `docs/pipeline/` 或 `.scratch`；避免 `output/` 成为第二根目录
- 未跟踪但仍有用的 tools 审计/修复脚本入库；`tools/README.md` 标明推荐入口与 legacy

### 2.4 指令与文档

- 新增 `AGENTS.md`：八耻八荣 + 目录表 + commit/smoke/任务清单约定
- 根 `README.md`：纠正架构描述（运行时像素 + **外部 Boss/角色帧管线**），链到 `AGENTS.md` 与 `tools/README.md`
- `.gitignore`：补 `.scratch/`、`output/`（若不再作为正式产物）、保持 `generated-*.png` / raw / tmp 规则

### 2.5 工作方式（process）

后续多步改动必须：

1. compose spec（若属可交付功能）或轻量计划
2. **task 工具**建清单并 start/done
3. 优先走技能（imagegen / design-blueprint / skill-creator 等），不硬写散落脚本
4. 小步 commit；交付前 smoke/自测

### 2.6 Out of Scope（本包不做）

- ruins / gate Boss 素材
- dancer 内容完成度关账（另开任务）
- `elite_boss` / `boss_form_painter` 大拆分
- `hawk_roar` 修复
- push 远程

## Tasks

- [x] T1: 写入本 spec — acceptance: 目录契约与收口范围明确（covers: S2）
- [x] T2: 写入 `AGENTS.md` — acceptance: 含八耻八荣、目录表、验证与提交约定（covers: S2.1/2.4/2.5）
- [x] T3: 根目录与临时目录收口 — acceptance: 根无 `generated-*.png`；临时物在 `.scratch/`（covers: S2.2/2.3）
- [x] T4: tools 整理与 README — acceptance: 推荐入口清晰；有用未跟踪脚本已入库或说明（covers: S2.3）
- [x] T5: `.gitignore` + 根 README — acceptance: ignore 覆盖 scratch；README 描述与管线一致（covers: S2.4）
- [ ] T6: 验收与 commit — acceptance: `AGENTS.md` 等入库；工作区无根目录生成图；spec 勾选（covers: S2.5）
