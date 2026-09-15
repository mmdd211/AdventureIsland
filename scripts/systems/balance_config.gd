class_name BalanceConfig
extends RefCounted

## 集中管理攻击判定框、难度缩放等硬编码数值。
## 改动这里即可全局调整,无需搜索散落的魔法数字。

## 玩家攻击判定框 [stage1, stage2]
const ATTACK_BOX_WIDTH := [82.0, 116.0]
const ATTACK_BOX_HEIGHT := [52.0, 66.0]
const ATTACK_BOX_OFFSET_X := [56.0, 68.0]

## 空中跳跃力度系数
const AIR_JUMP_MULTIPLIER := 0.88

## 减速状态下的移动速度系数
const SLOW_FACTOR := 0.55

## 难度缩放表 (index = difficulty - 1, difficulty 1..6)
const DIFFICULTY_HEALTH_SCALE := [1.0, 1.22, 1.48, 1.80, 2.20, 2.70]
const DIFFICULTY_SPEED_SCALE := [1.0, 1.06, 1.12, 1.18, 1.25, 1.32]
const DIFFICULTY_DAMAGE_BONUS := [0, 2, 4, 6, 9, 12]

## 难度索引安全取值
static func difficulty_index(difficulty: int) -> int:
	return mini(6, maxi(1, difficulty)) - 1
