# Tools 目录说明

> 工程总规范见仓库根目录 [`AGENTS.md`](../AGENTS.md)。  
> **禁止**把生成图、临时预览丢在项目根目录；本地临时统一放 `.scratch/`（gitignore）。

## 推荐入口

**`sprite_pipeline.py`** — 统一精灵表后处理管线，是**新素材处理的唯一推荐入口**。

```bash
# 处理: 色键抠图 + 切帧 + 缩放 + 对齐 + QC
python sprite_pipeline.py process --input raw.png --rows 2 --cols 3 --output-dir out/

# 验证: 检查帧间一致性
python sprite_pipeline.py verify --input-dir out/

# 组装: 从帧组装网格/条带
python sprite_pipeline.py assemble --input-dir out/ --output strip.png --layout 1x8
```

支持 `--key magenta|green`、`--align center|feet|bottom`、`--scale-profile`、`--write-scale-profile` 等参数。

Boss 身份锁流水线（spec → 母版 → 网格 → `process_boss_sheet.py` / `sprite_pipeline.py` → smoke → 小步 commit）见 `docs/compose/spec/*-sprites.md`。

## 活跃工具（建议入库、可复用）

| 脚本 | 用途 |
|------|------|
| `sprite_pipeline.py` | **统一后处理管线（推荐）** |
| `process_boss_sheet.py` | Boss 精灵表处理（洋红/绿幕色键） |
| `split_sprite_grid.py` | 网格拆分为单帧 |
| `normalize_player_frames.py` | 主角帧归一化 |
| `generate_mushroom_guardian_pixels.py` | 菌王程序化像素画 |
| `generate_pollen_queen_pixels.py` | 蜂后程序化像素画 |
| `audit_sprite_rect_borders.py` | 矩形边框/贴边审计 |
| `audit_sprite_texture_box.py` | 贴图铺满/裁切审计 |
| `fix_sprite_safe_margin.py` | 安全透明边距修复 |
| `generate_data_resources.gd` | 从 world_maps 等再生区域资源 |
| `smoke_check_*.gd` / `smoke_*_frames.gd` | Godot headless 自测入口 |

## Smoke Check

### 帧加载（headless）

```text
godot --headless --path <项目根> --script res://tools/smoke_<boss>_<form>_frames.gd
```

例如：`smoke_canyon_eagle_frames.gd`、`smoke_rune_colossus_statue_frames.gd`。成功时打印 `SMOKE_*_ALL_STATES_OK`。

**重要：** smoke 只验证「文件存在、能加载、张数符合 `BOSS_FRAME_STATES`」，**不能**证明角色肢体完整或未裁切。交付前必须过 `AGENTS.md`「Boss 素材视觉 QC 门禁」（目检源表格数、贴边审计、与母版并排）。

### 场景 / 数据 / UI / 存档

| 场景 | 验证内容 |
|------|----------|
| `smoke_check_scenes.tscn` | 场景加载 |
| `smoke_check_data.tscn` | 数据完整性 |
| `smoke_check_ui.tscn` | UI 加载 |
| `smoke_check_save.tscn` | 存档系统 |

## 历史遗留 / 一次性脚本

以下保留作参考，**不建议在新流程中使用**（多位于 gitignore 的 `tools/_*.py` 或仅本地）：

- `_banbu_*.py` — 菌王班布一次性处理
- `_verify_*.py`、`_make_*_preview.py`、`_charge_workaround.py`、`_cast_workaround.py`
- `preview_*.py`、`generate_*_preview.py`
- `polish_dancer_frames.py`、`clean_player_frames.py`、`process_run_batch.py` 等批次专用脚本

新 Boss/角色素材：**先 spec + task 清单**，再走 `sprite_pipeline.py`，不要新增根目录散落脚本。
