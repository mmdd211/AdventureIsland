# AGENTS.md — AdventureIsland 协作与工程规范

本文件是本仓库的**项目级指令**。自动化代理与协作者默认遵守下列规则；与会话临时指令冲突时，以更具体、更新的用户指令为准，但不得违反「八耻八荣」。

## 八耻八荣（用户规定，必须遵守）

1. **以可复现的环境为荣，以本地能跑线上炸为耻**  
   锁定依赖版本、记录工具链（Godot 版本、Python、脚本入口）；禁止只依赖「本机碰巧存在」的路径或未写明的步骤。
2. **以小步提交、频繁版本备份为荣，以大堆代码一次性提交为耻**  
   一个功能/一个 Boss 一次 commit；message 写清范围；共享文件附带改动必须在 body 说明。
3. **以可控、可关闭的硬配置为荣，以到处写死常量为耻**  
   数值、路径、开关优先进资源/配置（如 `data/regions/*.tres`、明确常量表）；避免业务逻辑里散落无法检索的魔法数。
4. **以最小可运行单元为荣，以一次性堆砌完整功能为耻**  
   先打通核心路径（加载、一形态、一次攻击），再叠加；不要一次写完整套再修。
5. **以边界条件预判为荣，以只处理正常输入为耻**  
   缺帧、null 资源、朝向、空技能列表、非法 index 必须有安全回退；禁止理想路径假设。
6. **以有最小说明文档为荣，以只有代码没有说明为耻**  
   新流程写 `docs/` 或更新 `tools/README.md` / 本文件；spec 交付后账本与磁盘一致。
7. **以组件解耦、单一职责为荣，以一坨大函数为耻**  
   新代码避免再堆进超大文件；能拆则拆、能表驱动则表驱动；改一处勿牵动无关区。
8. **以主动验证自测为荣，以直接丢给别人测试为耻**  
   声称完成前必须跑相关 smoke/审计；输出命令与结果；不拿「应该没问题」代替验证。

## 工具与环境（可复现）

| 项 | 约定 |
|----|------|
| 引擎 | Godot **4.7+**（本机控制台版路径见会话/环境，不写死进游戏逻辑） |
| 打开项目 | 项目根目录 `project.godot` |
| 帧加载 smoke | `godot --headless --path <proj> --script res://tools/smoke_*.gd` |
| 素材管线入口 | **`tools/sprite_pipeline.py`**（详见 `tools/README.md`） |
| Boss 表处理 | `tools/process_boss_sheet.py`（洋红/绿幕） |

## 目录契约（生成物必须归位）

```
AdventureIsland/
  AGENTS.md                 # 本文件
  README.md
  project.godot
  assets/                   # 运行时资源（引擎帧等）— 进版本库
    sprites/monsters/<resource_prefix>/
      <prefix>_{form}_{state}_{ii}.png
  data/
    regions/*.tres          # 区域与 Boss 数据
    monsters/raw/           # 生成原稿/母版/QA — gitignore
    player/raw/             # 玩家原稿 — gitignore
  docs/
    compose/spec/*.md       # 功能 spec（就地修订）
    pipeline/               # 管线说明、prompt 归档 — 进版本库
  scenes/ scripts/ tools/   # 场景、逻辑、工具
  .scratch/                 # 本地临时与一次性产物 — gitignore
```

### 规则

- **禁止**在项目根目录堆放 `generated-*.png`、临时预览、空脚本。
- 引擎帧只进 `assets/sprites/...`，命名与 `BossAssetLibrary.load_frames` 拼接规则一致。
- 中间原稿进 `data/*/raw/` 或 `.scratch/`，**不要**进 `assets/`。
- 临时目录统一放 `.scratch/`，勿再在根目录新建 `tmp_*` / `_cast_*`。
- Compose spec：`docs/compose/spec/<feature>.md`；交付后 `status`/任务勾选/Report 与真实状态一致。

## 数据双源

Boss 数值同时出现在：

- `data/regions/<region>.tres`
- `scripts/world/world_maps.gd`（`BOSSES` 字典）

修改其一时必须同步另一处，或通过 `tools/generate_data_resources.gd` 等流程再生并在 PR/commit 中说明。

## 执行工作流（多步任务）

1. **设计**：需要交付的功能写入/更新 compose spec（`docs/compose/spec/`）。
2. **任务**：用任务清单工具登记步骤，执行中 `start`/`done`，与 spec 任务对应。
3. **技能优先**：美术生成用 imagegen；视觉规范可用 design-blueprint；重复流程沉淀为项目 skill，禁止只会「硬写脚本丢根目录」。
4. **实现**：小步改动，按路径 stage，不混区、不混无关脏文件。
5. **验证**：跑相关 smoke（Boss 帧、data、save 等），记录结果。
6. **收尾**：spec → delivered，填写 Report；用户确认后再 push（默认不 push）。

## 提交约定

- 只 stage 与本次功能相关的路径。
- message 示例：`低语主教 whisper_root 引擎帧升级 256 画布并收口 spec`
- `boss_animator.gd` 等共享文件若含多区改动，body 必须逐条说明。

## 当前内容进度（摘要，以 spec/磁盘为准）

| 区域 | Boss | 素材 |
|------|------|------|
| meadow | pollen_queen | bee 齐；dancer 另有 spec |
| forest | mushroom_guardian | 有外部帧 |
| grove | whisper_root | 七态 256 已交付 |
| canyon | canyon_rock_eagle | 七态 256 + blade_gale 已交付 |
| ruins / gate | rune_colossus / sky_gatekeeper | 正式素材未做（回退 painter） |
