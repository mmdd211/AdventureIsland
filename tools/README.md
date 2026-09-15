# Tools 目录说明

## 推荐入口

**`sprite_pipeline.py`** — 统一精灵表后处理管线,是新素材处理的唯一推荐入口。

```bash
# 处理: 色键抠图 + 切帧 + 缩放 + 对齐 + QC
python sprite_pipeline.py process --input raw.png --rows 2 --cols 3 --output-dir out/

# 验证: 检查帧间一致性
python sprite_pipeline.py verify --input-dir out/

# 组装: 从帧组装网格/条带
python sprite_pipeline.py assemble --input-dir out/ --output strip.png --layout 1x8
```

支持 `--key magenta|green`、`--align center|feet|bottom`、`--scale-profile`、`--write-scale-profile` 等参数。

## 活跃工具

| 脚本 | 用途 |
|------|------|
| `sprite_pipeline.py` | **统一后处理管线(推荐)** |
| `process_boss_sheet.py` | Boss 精灵表处理(洋红/绿幕色键) |
| `split_sprite_grid.py` | 网格拆分为单帧 |
| `normalize_player_frames.py` | 主角帧归一化 |
| `generate_mushroom_guardian_pixels.py` | 菌王程序化像素画 |
| `generate_pollen_queen_pixels.py` | 蜂后程序化像素画 |

## 历史遗留脚本

以下脚本是一次性工具,保留作参考,不建议在新流程中使用:

- `_banbu_*.py` — 菌王班布相关的一次性处理
- `_verify_*.py`, `_make_*_preview.py` — 临时验证/预览
- `_charge_workaround.py`, `_cast_workaround.py` — 临时 workaround
- `preview_*.py`, `generate_*_preview.py` — 预览生成
- `audit_bee_identity.py`, `scan_ai_watermark.py`, `scrub_*.py` — 审计/清理工具
- `clean_player_frames.py`, `polish_dancer_frames.py` — 特定素材处理
- `process_run_batch.py`, `process_pollen_queen_bee_hover.py` — 特定批次处理

## Smoke Check 场景

| 场景 | 验证内容 |
|------|---------|
| `smoke_check_scenes.tscn` | 场景加载 |
| `smoke_check_data.tscn` | 数据完整性 |
| `smoke_check_ui.tscn` | UI 加载 |
| `smoke_check_save.tscn` | 存档系统 |
