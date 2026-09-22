# 冒险岛物语（AdventureIsland）

一款使用 Godot 4.7 制作的横版像素冒险平台跳跃游戏。玩家从初始草原出发，穿越六大主题区域，击败沿途怪物，最终抵达天穹之门完成通关。

**工程规范（必读）**：[`AGENTS.md`](AGENTS.md) — 含「八耻八荣」、目录契约、提交与自测约定。

## 游戏特色

- **六大主题区域**：初始草原、蘑菇森林、低语树洞、风哨峡谷、苔石遗迹、天穹之门，每个区域拥有独立配色、地形与敌人布置，通过传送门依次连通。
- **多种敌人与分区 Boss**：基础敌人行为各异；各区 Elite Boss 含两形态与技能。
- **双轨美术**：
  - 地形、传送门、部分装饰仍由 `PixelStyleManager` 等在加载阶段生成；
  - **主角与 Boss 使用外部引擎帧**，路径约定 `assets/sprites/monsters/<resource_prefix>/`，经 `BossAssetLibrary.load_frames` 加载；原稿与中间图放 `data/*/raw/` 或 `.scratch/`（勿堆在仓库根目录）。
  - Boss 素材进度：meadow / forest / grove / canyon 两形态已齐；**ruins `statue` + `sage` 七态 88 帧已入库**；gate 待做。
- **程序化芯片音乐**：`AudioManager` 实时合成波形。
- **完整局内体验**：暂停、死亡复活、检查点存档、金币与经验、Tab 世界地图。
- **敌人传送门边界**：传送门两侧隐形边界仅对敌人生效。

## 操作方式

| 按键 | 功能 |
| --- | --- |
| A / D | 左右移动 |
| W / 空格 | 跳跃 |
| J | 攻击 |
| K / Shift | 冲刺 |
| Tab | 世界地图 |

## 运行方式

1. 安装 [Godot 4.7](https://godotengine.org/download) 或更高版本。
2. 使用 Godot 打开本项目根目录的 `project.godot`。
3. 点击运行（F5）即可从标题屏开始游戏。

素材与工具流水线详见 [`tools/README.md`](tools/README.md)；功能交付记录见 `docs/compose/spec/`。
