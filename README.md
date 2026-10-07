# 人生重开模拟器（Godot 版）

> 用 **Godot 4** 重写的《人生重开模拟器》——一款文字人生模拟游戏：抽天赋、定属性、看事件、走到结局，然后重开。

---

## ⚠️ 重要声明：这个项目还有大量的 BUG

**请务必先读完这一段再决定要不要用它。**

- 本项目目前处于**早期开发阶段**，**没有完成开发，也从未做过系统性测试**。
- 代码中**存在大量已知和未知的 BUG**：数值计算错误、事件条件判断不准、界面偶尔残留或错位、极端情况下崩溃，都属于正常现象。
- **不保证任何数值平衡与存档兼容性**：后续提交可能修改存档结构、事件 id 和成就判定，旧存档不保证能继续使用。
- 请不要把本项目用于任何严肃用途，也不要把它的数值表现当作设计参考。
- 如果你只是来找一个能稳定游玩的成品，**这个仓库不适合你**。

欢迎提交 Issue 报告你遇到的 BUG，这正是本仓库公开的主要目的之一。

---

## 项目简介

《人生重开模拟器》的核心玩法是「随机出身 + 逐年事件 + 一局一结算」。本仓库是这个玩法在 Godot 引擎上的独立实现，包含完整的主菜单、天赋抽取、属性分配、逐年推进、事件选择、结算与图鉴等流程。

## 功能特性

| 模块 | 说明 |
| --- | --- |
| 主菜单 | 开始游戏 / 通过种子开始 / 成就 / 事件图鉴 |
| 天赋系统 | 按稀有度抽取，支持天赋初始效果与全局广播（`Auto_load/TalentPool.gd`） |
| 六维属性 | 体质、颜值、智商、家境、运气、心情，附带压力机制 |
| 事件系统 | 条件 / 权重驱动的逐年事件、分支事件、二选一事件 |
| 种子系统 | 可输入指定种子复现同一局人生 |
| 修仙线 | 境界晋升、渡劫、仙修 / 魔修 / 魂修三条支线及多种结局 |
| 成就 | 青铜 / 白银 / 黄金 / 钻石四级，含隐藏成就 |
| 事件图鉴 | 记录已触发事件，统计收集度 |
| 结算与存档 | 结局摘要、新解锁成就、跨局进度持久化（`user://dsh_progress.cfg`） |
| 其他界面 | 天赋锁定、技能菜单、历史记录 |

## 运行方式

1. 安装 [Godot 4](https://godotengine.org/download)（本项目的 `project.godot` 声明为 `4.7`）。
2. 用 Godot 打开本目录下的 `project.godot`。
3. 按 <kbd>F5</kbd> 运行。

入口场景为 `Main_menu/main_menu.tscn`，窗口尺寸 1920×1080（`canvas_items` 拉伸，`expand` 宽高比）。

> 如果你的 Godot 版本低于项目声明的 `4.7`，打开时可能提示版本不匹配；此时需要自行调整 `project.godot` 中 `config/features` 一行。

## 项目结构

```
.
├── project.godot            # 引擎配置、Autoload 注册、入口场景
├── Auto_load/               # 全局单例
│   ├── GlobalData.gd        #   本局状态（属性、年龄、种子、结局摘要）
│   ├── Progress.gd          #   跨局进度（成就、事件图鉴、锁定天赋、存档）
│   ├── TalentPool.gd        #   天赋表与稀有度
│   ├── RandomProbability.gd #   带权随机
│   └── PopupManager.gd      #   全局弹窗
├── Main/                    # 主游戏循环
│   ├── main.gd              #   核心逻辑（约 2400 行 / 128 个函数）
│   ├── main.tscn
│   ├── choose_line.tscn     #   选择项控件
│   └── text_line.tscn       #   文本行控件
├── Data/                    # 事件数据模块（各约 190 条事件条目）
│   ├── CultivationEvents.gd #   修仙线
│   ├── ResourceEvents.gd    #   资源 / 经济线
│   ├── AdvanceEvents.gd     #   进阶线
│   ├── RomanceEvents.gd     #   感情线
│   ├── FamilyEvents.gd      #   家庭线
│   ├── GenderEvents.gd      #   性别相关事件
│   ├── InteractionEvents.gd #   社交互动
│   └── BreakthroughItems.gd #   突破道具
├── Main_menu/               # 主菜单
├── Talent_menu/             # 天赋抽取
├── Lock_talent/             # 天赋锁定
├── Skill_menu/              # 技能菜单
├── Choose_seed/             # 种子输入
├── Settlement/              # 结算界面
├── Record/                  # 成就 / 事件图鉴
└── Tools/                   # 开发期自测脚本（见下）
```

## 开发期自测脚本

`Tools/` 下是一批手动运行的无头验证脚本，不是自动化测试，**不会被 CI 执行，也没有 CI**：

```bash
godot --headless --script res://Tools/verify_flow.gd
```

可用的脚本包括 `verify_flow`、`verify_meta`、`verify_seed`、`verify_seed_ui`、`verify_rarity`、`verify_tribulation`、`verify_settle_lock`、`verify_ui_fixes`，以及 `sim_life`（批量模拟）和 `shot_tribulation`（截图）。

## 已知问题

除了上面声明的大量 BUG，以下是打开代码就能确认的几类结构性问题：

- **核心逻辑过度集中**：`Main/main.gd` 约 2400 行、128 个函数，事件定义、状态机、界面刷新混在一起，改动极易引入回归。
- **没有测试与 CI**：`Tools/` 里的脚本依赖人工执行，且各自是为某次修复临时写的，覆盖不完整。
- **存档没有版本号**：`user://dsh_progress.cfg` 只按字段名直接读写，字段结构变化时无法做迁移。
- **仓库中残留编辑器临时文件**：`Main/*.tmp`、`Talent_menu/*.tmp` 是 Godot 编辑器异常退出留下的场景临时文件（已在 `.gitignore` 中排除，未纳入版本控制）。

## 贡献

欢迎 Issue 与 Pull Request，尤其是 BUG 修复。提交前请注意：

- 保持 GDScript 缩进为 Tab（见 `.editorconfig`）。
- 文本文件编码统一为 UTF-8，换行由 `.gitattributes` 归一为 LF。
- 如果修改了事件或成就判定，请说明你验证过的场景。

## 许可证

本项目以 **GNU General Public License v3.0** 发布，全文见 [LICENSE](LICENSE)。

你可以自由使用、修改和分发本项目，但**衍生作品必须以同样的 GPL-3.0 协议开源**。

## 说明

本项目是独立实现，与原版《人生重开模拟器》的作者及维护者**没有关联**，也未获得其背书。
