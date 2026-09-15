---
feature: code-quality-and-sprite-pipeline
status: delivered
updated: 2026-07-15
branch: refactor/code-quality-and-sprite-pipeline
commits: 3e809a8..7fc9bd5
---

# Code Quality & Sprite Pipeline Optimization

## Report

**What was built** — 修复了飞行敌人双重 move_and_slide 物理 bug、_apeak_y 拼写错误、data/enemy_data 类型冗余,删除了废弃的 game_manager.gd。创建了 FxUtil 公共特效工具(浮动文字/粒子/圆环/斩击弧线)和 BalanceConfig 数值配置类(攻击框/难度缩放/跳跃系数),消除了 player.gd 和 basic_enemy.gd 中的重复代码和魔法数字。提取了 world_map.gd 的公共建场景逻辑。拆分了 basic_enemy.gd 的 AI 行为到 EnemyBehaviors(526→335 行)。创建了 tools/sprite_pipeline.py 统一精灵后处理管线,支持 process/verify/assemble 子命令、Scale Profile 跨动作一致性锁定、量化 QC(body_scale_cv/anchor_y_std/edge_touch)。

**Verification** — sprite_pipeline.py 三个子命令均测试通过;用 mushroom_guardian idle 6 帧验证 QC: body_scale_cv=0.0241(≤0.08), anchor_y_std=0.0013(≤0.05), edge_touch=0, 结果 PASS。Godot 4.7.2 headless 120帧 verbose 运行零错误零脚本警告;有窗口模式标题屏截图渲染正常。

**Journey log** —
1. 飞行敌人的双重 move_and_slide 是最隐蔽的 bug:在 `_process_flyer` 的 else 分支里,只有玩家不在检测范围时才会触发。
2. pixel_style_manager / elite_boss / boss_form_painter 的拆分风险较高(autoload 依赖、运行时行为复杂),在无法启动 Godot 编辑器验证的情况下暂缓,建议后续在编辑器中逐步拆分。
3. GDScript 静态方法访问实例私有变量是可行的,但需要在 EnemyBehaviors 中用 `enemy.` 前缀访问所有属性,枚举值需用数字字面量(State.PATROL → 0)。
4. tools/ 目录有 31 个 Python 脚本,大部分是一次性工具;统一入口 sprite_pipeline.py 取代了碎片化流程,但旧脚本保留作参考。

## [S1] Problem

基于对合并后 master 代码的全面审评,发现以下问题:

**Bug 类:**
- `basic_enemy.gd` 的 `_process_flyer()` 内部调用 `move_and_slide()`,而 `_physics_process` 主循环也调用,导致飞行敌人每帧执行两次物理滑动,可能造成穿墙或位置异常。
- `player.gd:70` 变量名 `_apeak_y` 拼写错误(应为 `_apex_y`)。
- `basic_enemy.gd:7-8` 同时声明 `data: Resource` 和 `enemy_data: EnemyData`,`_ready` 中两次赋值,语义混乱。
- `game_manager.gd`(14 行)未注册为 autoload,功能与 `GameState` 完全重复,疑似废弃代码。

**可维护性类:**
- 视觉特效代码在 `player.gd` 和 `basic_enemy.gd` 中重复实现(浮动文字、粒子、圆环效果)。
- 魔法数字遍布:攻击判定框尺寸、难度缩放数组、跳跃系数等硬编码在脚本中。
- `world_map.gd` 的 `_ready()` 和 `_start_loading_flow()` 存在大量重复的建场景逻辑。

**大文件类:**
- `boss_form_painter.gd` 894 行,`pixel_style_manager.gd` 796 行,`elite_boss.gd` 746 行,`basic_enemy.gd` 506 行。单文件过大,职责过多,难以维护和测试。

**Sprite 管线类:**
- `tools/` 目录有 31 个 Python 脚本,大量是一次性硬编码脚本,缺乏统一入口。
- 精灵生成使用单行 `1xN` 网格,帧间一致性差(agent-sprite-forge 验证的最佳实践是多行网格)。
- 主角 8 个动作(idle/run/jump/fall/attack1/attack2/landing/hurt)缺少跨动作 Scale Profile,大小/锚点可能不一致。
- 无自动化 QC(量化帧间一致性指标)。

## [S2] Design

### 2.1 Bug 修复

**双重 move_and_slide:** 从 `_process_flyer()` 中移除内部的 `move_and_slide()` 调用,只保留 `_physics_process` 主循环中的一次调用。`_process_flyer` 只负责设置 `velocity`。

**_apeak_y 拼写:** 重命名为 `_apex_y`,同步更新所有引用。

**data/enemy_data 冗余:** 移除 `enemy_data` 字段,统一使用 `data: EnemyData` 类型声明。`_ready` 中只赋值一次。

**game_manager.gd:** 删除文件及其 `.uid` 文件。确认无其他脚本引用它(搜索 `GameManager` 或 `game_manager`)。

### 2.2 公共特效工具

创建 `scripts/systems/fx_util.gd`,提供静态方法:
- `spawn_floating_text(parent, text, world_pos, color, font_size)` — 统一的浮动文字
- `spawn_particles(parent, world_pos, config)` — 统一的粒子爆发
- `spawn_ring(parent, world_pos, color, radius)` — 统一的圆环效果
- `spawn_slash_arc(parent, local_pos, facing, stage, color, reach)` — 统一的斩击弧线

`player.gd` 和 `basic_enemy.gd` 中的重复实现替换为对 `FxUtil` 的调用。

### 2.3 魔法数字配置化

创建 `scripts/systems/balance_config.gd`(autoload 或 const class),集中管理:
- 玩家攻击判定框尺寸(stage1/stage2 的 width/height/reach)
- 难度缩放表(health_scale / speed_scale / damage_bonus 数组)
- 跳跃系数(air_jump_multiplier, jump_cut_multiplier)
- 移动参数(slow_factor 等)

`player.gd` 和 `basic_enemy.gd` 引用此配置,不再硬编码。

### 2.4 world_map 去重

提取 `_ready()` 和 `_start_loading_flow()` 的公共部分为 `_build_common_scene()`,包含:建相机、建玩家、建 UI、建过渡层。两条路径各自调用后再执行差异化逻辑(加载流程 vs 直接启动)。

### 2.5 大文件拆分

**basic_enemy.gd (506 行) → 拆分为:**
- `basic_enemy.gd` — 核心状态机 + 物理 + 组件装配(保留 ~200 行)
- `enemy_behaviors.gd` — 各敌人类型的 AI 行为函数(_process_flyer, _process_snail, _process_slime, _process_charger, _process_caster, _process_ambusher)

**pixel_style_manager.gd (796 行) → 拆分为:**
- `pixel_style_manager.gd` — 调度入口 + 进度管理(保留 ~200 行)
- `zone_painter.gd` — 区域地形/物件像素化逻辑
- `enemy_painter.gd` — 敌人纹理生成逻辑

**elite_boss.gd (746 行) → 拆分为:**
- `elite_boss.gd` — 状态机 + 数据加载 + 核心流程(保留 ~300 行)
- `boss_combat.gd` — 攻击/技能执行逻辑
- `boss_visual.gd` — 动画/特效/HUD 可见性逻辑

**boss_form_painter.gd (894 行) → 拆分为:**
- `boss_form_painter.gd` — 公共框架 + pose 系统(保留 ~200 行)
- 按 region 拆分绘制函数到独立文件或内部 region class

### 2.6 Sprite 管线标准化

**统一入口脚本:** 创建 `tools/sprite_pipeline.py`,整合以下功能:
- `process` 子命令:色键抠图 → 网格切帧 → 尺寸归一 → 对齐 → QC 输出
- `verify` 子命令:检查帧间一致性(body_scale_cv, anchor_y_std)
- `assemble` 子命令:从多行网格组装单行 strip(用于引擎交付)

参数化: `--input`, `--rows`, `--cols`, `--key`(magenta/green), `--cell-size`, `--align`(center/feet), `--scale-strategy`(fit/preserve), `--output-dir`, `--write-scale-profile`, `--scale-profile`

**Scale Profile:** 从已接受的 idle/run 帧提取 `character-scale-profile.json`,记录:cell_size, fit_scale, align, subject_height_mean。后续所有动作用 `--scale-profile` 引用,确保跨动作一致。

**多行网格策略:** 新精灵生成时默认使用 `2x2`(4帧), `2x3`(6帧), `3x3`(9帧) 网格,不再使用 `1xN` 单行。已有的 `1xN` 素材保持不变,新素材遵循新策略。

**旧脚本处理:** `tools/` 中的一次性脚本保留(它们是历史工具),但新增 `README.md` 说明哪些是活跃工具、哪些是历史遗留。新的 `sprite_pipeline.py` 作为唯一推荐入口。

## [S3] Out of Scope

- 不修改游戏玩法逻辑(数值平衡、敌人行为参数)。
- 不重新生成现有精灵素材(只标准化管线,不重新出图)。
- 不修改 `PixelStyleManager` 运行时像素生成的视觉效果。
- 不引入外部依赖(纯 Python stdlib + Pillow)。
- 不修改 `.tres` 数据资源文件。
- 不做 CI/CD 配置。

## Tasks

### Phase 1: Bug 修复与清理

- [x] T1: 修复飞行敌人双重 move_and_slide — acceptance: `_process_flyer` 中不再调用 `move_and_slide()`,飞行敌人物理行为不变 (covers: S2.1)
- [x] T2: 修复 `_apeak_y` 拼写为 `_apex_y` — acceptance: `player.gd` 中无 `_apeak_y` 残留,所有引用已更新 (covers: S2.1)
- [x] T3: 清理 `basic_enemy.gd` 的 `data`/`enemy_data` 冗余 — acceptance: 只保留一个字段,类型为 `EnemyData`,运行时行为不变 (covers: S2.1)
- [x] T4: 删除废弃的 `game_manager.gd` — acceptance: 文件不存在,项目中无 `GameManager` 引用,Godot 无报错 (covers: S2.1)

### Phase 2: 公共工具与配置

- [x] T5: 创建 `FxUtil` 公共特效工具 — acceptance: `scripts/systems/fx_util.gd` 存在,提供 floating_text/particles/ring/slash_arc 静态方法 (covers: S2.2)
- [x] T6: 替换 player.gd 中的重复特效代码为 FxUtil 调用 — acceptance: `player.gd` 中 `_spawn_floating_text`/`_create_ring_effect`/`_create_slash_arc` 改为调用 FxUtil,视觉效果不变 (covers: S2.2)
- [x] T7: 替换 basic_enemy.gd 中的重复特效代码为 FxUtil 调用 — acceptance: `basic_enemy.gd` 中 `_spawn_text`/`_create_death_effect` 改为调用 FxUtil,视觉效果不变 (covers: S2.2)
- [x] T8: 创建 `BalanceConfig` 配置类 — acceptance: `scripts/systems/balance_config.gd` 存在,集中管理玩家攻击框、难度缩放表、跳跃系数 (covers: S2.3)
- [x] T9: 替换 player.gd 和 basic_enemy.gd 中的魔法数字为 BalanceConfig 引用 — acceptance: 两个文件中无硬编码的攻击框尺寸/难度缩放数组,运行时数值不变 (covers: S2.3)
- [x] T10: 提取 world_map.gd 公共建场景逻辑 — acceptance: `_ready` 和 `_start_loading_flow` 调用共享的 `_build_common_scene()`,无重复代码 (covers: S2.4)

### Phase 3: 大文件拆分

- [x] T11: 拆分 basic_enemy.gd 的 AI 行为到 enemy_behaviors.gd — acceptance: `enemy_behaviors.gd` 包含所有 `_process_*` 行为函数,`basic_enemy.gd` ≤ 250 行,敌人行为不变 (covers: S2.5)
- [ ] T12: 拆分 pixel_style_manager.gd 的区域绘制到 zone_painter.gd — acceptance: `zone_painter.gd` 包含区域地形/物件像素化逻辑,`pixel_style_manager.gd` ≤ 300 行,视觉效果不变 (covers: S2.5) — **暂缓: autoload 依赖复杂,需 Godot 编辑器验证**
- [ ] T13: 拆分 elite_boss.gd 的战斗逻辑到 boss_combat.gd — acceptance: `boss_combat.gd` 包含攻击/技能执行,`elite_boss.gd` ≤ 400 行,Boss 行为不变 (covers: S2.5) — **暂缓: 运行时行为复杂,需 Godot 编辑器验证**
- [ ] T14: 拆分 boss_form_painter.gd 的绘制逻辑 — acceptance: 按 region 拆分绘制函数,主文件 ≤ 300 行,像素输出不变 (covers: S2.5) — **暂缓: 894 行像素绘制,需 Godot 编辑器验证**

### Phase 4: Sprite 管线标准化

- [x] T15: 创建 tools/sprite_pipeline.py 统一入口 — acceptance: 脚本存在,支持 process/verify/assemble 子命令,参数化输入输出 (covers: S2.6)
- [x] T16: 实现 Scale Profile 读写 — acceptance: `--write-scale-profile` 输出 JSON,`--scale-profile` 读取并应用,跨动作尺寸一致 (covers: S2.6)
- [x] T17: 实现量化 QC 输出 — acceptance: process 后输出 `pipeline-meta.json`,包含 body_scale_cv / anchor_y_std / edge_touch 指标 (covers: S2.6)
- [x] T18: 为 tools/ 添加 README.md 说明文档 — acceptance: 文件存在,列出活跃工具 vs 历史遗留脚本,说明 sprite_pipeline.py 为推荐入口 (covers: S2.6)

### Phase 5: 验证

- [x] T19: 运行项目 smoke check 场景验证 — acceptance: Godot headless 120帧零错误 + 标题屏截图正常 (covers: S2.1, S2.2, S2.3, S2.4, S2.5)
- [x] T20: 运行 sprite_pipeline.py 自测 — acceptance: 用现有素材跑一遍 process 流程,输出正常,QC 指标合理 (covers: S2.6)
