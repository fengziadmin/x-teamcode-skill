# X-TeamCode

结构化计划 + 多智能体团队执行，适用于 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)。

融合 [superpowers](https://github.com/obra/superpowers) 的严谨计划工作流与 [CCteam-creator](https://github.com/jessepwj/CCteam-creator) 的多智能体团队协作能力。通过头脑风暴和细粒度任务分解来规划复杂项目，然后由并行 AI 智能体团队执行——每一步都内置目标收敛机制。

## 为什么选择 X-TeamCode？

| 能力 | superpowers | CCteam-creator | X-TeamCode |
|---|---|---|---|
| 结构化头脑风暴 | 有 | 无 | 有 |
| 详细计划编写 + 自审 | 有 | 无 | 有 |
| 多智能体并行执行 | 无 | 有 | 有 |
| 文件系统持久化进度 | 无 | 有 | 有 |
| 逐任务规格合规审查 | 有（子代理） | 无 | 有（团队） |
| 逐任务代码质量审查 | 有（子代理） | 无 | 有（团队） |
| 最终规格验收门禁 | 部分 | 无 | 有 |
| TDD 铁律强制执行 | 有 | 部分 | 有 |
| Golden Rules CI 自动化 | 无 | 有 | 有 |
| 上下文压缩后恢复 | 无 | 有 | 有 |

X-TeamCode 解决了一个核心问题：superpowers 擅长计划但只有单代理执行，CCteam-creator 擅长团队执行但缺少结构化计划。两者结合，取长补短。

## 工作原理

```
阶段 A：结构化计划（来自 superpowers）
  A1. 头脑风暴 — 一次一问、2-3 种方案推荐、设计规格文档
  A2. 编写计划 — 文件映射、任务分解（2-5 分钟粒度）、TDD
      |
阶段 B：计划到团队的衔接（全新设计）
  B1. 分析计划 → 自动推荐团队配置
  B2. 将计划任务映射到团队角色
  B3. 生成 .plans/ 基础设施 + CLAUDE.md
  B4. 用户确认团队方案
      |
阶段 C：团队执行（来自 CCteam-creator）
  C1. 创建团队 + 并行生成智能体
  C2. 并行执行（TDD + 3-Strike + 上下文恢复）
  C3. 逐任务收敛：规格合规审查 → 代码质量审查
  C4. 阶段推进门禁
  C5. 最终规格验收（逐条验证每个需求）
  C6. 完成
```

### 目标收敛机制

每个开发任务都经过两阶段审查循环：

```
开发者完成任务 → CI 通过
    ↓
第一阶段：规格合规审查
    审查者逐行对照实际代码与规格文档
    通过 → 进入第二阶段 | 不通过 → 开发者修复 → 重新审查
    ↓
第二阶段：代码质量审查
    安全 / 质量 / 性能 / 审查维度评分
    [OK] → 任务完成 | [BLOCK] → 开发者修复 → 重新审查
    ↓
所有任务完成 → 最终规格验收
    团队领导逐条验证每个规格需求是否都有实现证据
```

## 前置要求

- 已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- 推荐安装 [superpowers](https://github.com/obra/superpowers) 插件（智能体会使用其中的 TDD、调试等质量技能）
- 已开启 Agent Teams 功能（安装脚本会自动开启）。如需手动开启，在 `~/.claude/settings.json` 中添加：
  ```json
  { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
  ```

## 安装方法

### 一键安装

```bash
git clone https://github.com/fengziadmin/x-teamcode-skill.git && bash x-teamcode-skill/install.sh
```

安装脚本会自动完成：
- 将插件链接到 Claude Code 的 marketplace 目录
- 在 `~/.claude/settings.json` 中注册插件

安装完成后，**重启 Claude Code**，输入 `/x-teamcode` 即可使用。

### 卸载

```bash
bash x-teamcode-skill/uninstall.sh
```

### 手动安装

如果你希望手动安装，可以查看 [install.sh](install.sh) 脚本了解具体步骤——脚本很短，一目了然。
- "使用 x-teamcode 来构建..."
- "计划+团队"

## 使用方法

### 快速开始

1. 在你的项目目录中打开 Claude Code
2. 输入 `/x-teamcode` 或描述你的项目
3. 跟随引导式工作流：
   - **头脑风暴**：逐个回答问题，定义设计方案
   - **编写计划**：审核详细的实施计划
   - **团队组建**：确认推荐的团队配置
   - **执行**：智能体并行工作，自动审查循环

### 详细工作流

#### 阶段 A：结构化计划

**A1. 头脑风暴**

Claude 作为设计伙伴：
- 探索项目上下文（文件、文档、提交记录）
- 一次一个问题进行需求澄清
- 提议 2-3 种方案，附带权衡分析和推荐
- 将设计规格文档写入 `docs/x-teamcode/specs/`
- 运行自动化规格自审以保证质量

**A2. 编写计划**

基于已批准的设计：
- 映射所有需要创建或修改的文件
- 将工作拆分为细粒度任务（每个 2-5 分钟）
- 为每个任务分配角色建议和并行分组
- 遵循 TDD/DRY/YAGNI 原则
- 将计划保存到 `docs/x-teamcode/plans/`
- 运行自动化计划自审

#### 阶段 B：计划到团队的衔接

将计划转换为团队配置：
- 分析任务并推荐角色（backend-dev、frontend-dev、researcher 等）
- 自动将计划任务映射到团队角色
- 生成 `.plans/` 目录结构用于进度跟踪
- 创建项目 `CLAUDE.md` 保存团队运维知识
- 设置 CI 基础设施（golden_rules.py）

#### 阶段 C：团队执行

智能体并行工作：
- 每个智能体遵循 TDD、3-Strike 错误处理和上下文恢复协议
- **每个任务** 经过两阶段审查（规格合规 + 代码质量）
- 阶段门禁确保推进前的质量
- 最终规格验收确认每个需求都已实现

### 可用角色

| 角色 | 名称 | 核心能力 |
|---|---|---|
| 后端开发 | `backend-dev` | 服务端代码 + TDD |
| 前端开发 | `frontend-dev` | 客户端代码 + TDD |
| 研究员 | `researcher` | 代码搜索 + 网络调研（只读） |
| E2E 测试 | `e2e-tester` | Playwright 测试 + 浏览器自动化 |
| 代码审查 | `reviewer` | 安全/质量/性能 + 规格合规审查 |
| 管家 | `custodian` | 约束合规 + 文档治理 + CI 自动化 |

团队领导（主会话）协调所有智能体。不是每个项目都需要全部角色——技能会根据你的项目推荐合适的配置。

### 项目产物

运行 x-teamcode 后，你的项目将包含：

```
你的项目/
  CLAUDE.md                              # 团队运维知识（自动加载到上下文）
  docs/x-teamcode/
    specs/YYYY-MM-DD-<主题>-design.md    # 设计规格文档
    plans/YYYY-MM-DD-<功能>.md           # 实施计划
  .plans/<项目>/
    task_plan.md                         # 主导航地图
    phase-state.md                       # 当前阶段（用于恢复）
    team-snapshot.md                     # 缓存的入职提示（快速恢复）
    findings.md / progress.md / decisions.md
    docs/                                # 架构、API 合约、不变量
    <智能体名>/                           # 各智能体工作目录
      task_plan.md / findings.md / progress.md
      <前缀>-<任务>/                      # 任务文件夹
  scripts/
    golden_rules.py                      # 自动化质量检查
    run_ci.py                            # CI 管道
```

### 恢复项目

X-TeamCode 支持会话恢复。如果你重启 Claude Code 或上下文被压缩：

1. 技能自动检测已存在的 `.plans/` 目录
2. 读取 `phase-state.md` 确定从哪个阶段恢复
3. 使用 `team-snapshot.md` 快速重新生成智能体，无需重读所有技能文件
4. 每个智能体读取自己的任务文件恢复上下文

只需再次输入 `/x-teamcode`，它会提供恢复选项。

## 适用场景

**适合使用：**
- 多模块项目（前端 + 后端 + 测试）
- 需要调研 + 开发 + 测试多阶段的项目
- 2-6 个 AI 智能体并行协作的场景
- 对规格合规和代码质量有要求的项目

**不适合使用：**
- 单文件修改或简单 Bug 修复
- 只需要一个角色的任务（直接使用 superpowers）
- 无质量要求的快速原型

## 文件结构

```
x-teamcode-skill/
  .claude-plugin/
    plugin.json                          # 插件清单
    marketplace.json                     # Marketplace 注册信息
  skills/x-teamcode/
    SKILL.md                             # 主技能文件（入口 + 完整工作流）
    references/
      roles.md                           # 角色定义（含质量增强）
      onboarding.md                      # 智能体入职提示模板
      templates.md                       # .plans/ 文件模板
      plan-bridge.md                     # 衔接层：计划 → 团队任务
    prompts/
      spec-document-reviewer.md          # 设计规格自审（阶段 A）
      plan-document-reviewer.md          # 实施计划自审（阶段 A）
      spec-reviewer-prompt.md            # 逐任务规格合规审查（阶段 C）
      code-quality-reviewer-prompt.md    # 逐任务代码质量审查（阶段 C）
    scripts/
      golden_rules.py                    # 5 项通用代码健康检查
```

## 质量保障体系

X-TeamCode 在每个层级强制执行质量标准：

| 实践 | 来源 | 何时应用 |
|---|---|---|
| TDD（RED-GREEN-REFACTOR） | superpowers | 每个开发任务 |
| 规格文档自审 | superpowers | 设计文档编写后 |
| 实施计划自审 | superpowers | 计划编写后 |
| 逐任务规格合规审查 | superpowers（适配） | 每个开发任务完成后 |
| 逐任务代码质量审查 | superpowers（适配） | 规格合规通过后 |
| 完成前验证 | superpowers | 任何完成声明之前 |
| Golden Rules CI | CCteam-creator | 提交审查之前 |
| 3-Strike 升级 | CCteam-creator | 重复失败时 |
| 最终规格验收 | X-TeamCode | 所有任务完成后 |

## 致谢

X-TeamCode 建立在两个优秀的 Claude Code 插件之上：

- **[superpowers](https://github.com/obra/superpowers)** by Jesse Vincent — TDD、调试、头脑风暴和计划工作流的核心技能库
- **[CCteam-creator](https://github.com/jessepwj/CCteam-creator)** by jessepwj — 基于文件系统的多智能体团队协作与角色化管理

## 许可证

MIT
