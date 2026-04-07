# X-TeamCode

Structured Planning + Multi-Agent Team Execution for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Combines [superpowers](https://github.com/obra/superpowers)' disciplined planning workflow with [CCteam-creator](https://github.com/jessepwj/CCteam-creator)'s multi-agent team orchestration. Plan complex projects through brainstorming and detailed task decomposition, then execute with parallel AI agent teams — with built-in goal convergence at every step.

## Why X-TeamCode?

| Capability | superpowers | CCteam-creator | X-TeamCode |
|---|---|---|---|
| Structured brainstorming | Yes | No | Yes |
| Detailed plan writing with self-review | Yes | No | Yes |
| Multi-agent parallel execution | No | Yes | Yes |
| File-based progress persistence | No | Yes | Yes |
| Per-task spec compliance review | Yes (subagent) | No | Yes (team) |
| Per-task code quality review | Yes (subagent) | No | Yes (team) |
| Final spec acceptance gate | Partial | No | Yes |
| TDD iron law enforcement | Yes | Partial | Yes |
| Golden rules CI automation | No | Yes | Yes |
| Context recovery after compaction | No | Yes | Yes |

X-TeamCode addresses the gap where superpowers has excellent planning but single-agent execution, while CCteam-creator has excellent team execution but minimal structured planning.

## How It Works

```
Phase A: Structured Planning (from superpowers)
  A1. Brainstorming — one question at a time, 2-3 approaches, design spec
  A2. Writing Plans — file mapping, task decomposition (2-5 min granularity), TDD
      |
Phase B: Plan-to-Team Bridge (new)
  B1. Analyze plan → auto-recommend team configuration
  B2. Map plan tasks to team roles
  B3. Generate .plans/ infrastructure + CLAUDE.md
  B4. User confirms team
      |
Phase C: Team Execution (from CCteam-creator)
  C1. Create team + spawn agents in parallel
  C2. Parallel execution with TDD + 3-Strike + context recovery
  C3. Per-task convergence: spec compliance review → code quality review
  C4. Phase progression gates
  C5. Final spec acceptance (every requirement verified)
  C6. Completion
```

### Goal Convergence

Every dev task goes through a two-stage review cycle:

```
Dev completes task → CI green
    ↓
Stage 1: Spec Compliance Review
    Reviewer reads actual code vs spec, line by line
    ✅ pass → Stage 2 | ❌ fail → Dev fixes → re-review
    ↓
Stage 2: Code Quality Review
    Security / quality / performance / Review Dimensions
    [OK] → task done | [BLOCK] → Dev fixes → re-review
    ↓
All tasks done → Final Spec Acceptance
    Team-lead verifies every spec requirement is met with evidence
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Recommended: [superpowers](https://github.com/obra/superpowers) plugin installed (for TDD, debugging, and other quality skills used by agents)
- Agent teams enabled (the install script does this automatically). For manual setup, add to `~/.claude/settings.json`:
  ```json
  { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
  ```

## Installation

### One-Line Install

```bash
git clone https://github.com/fengziadmin/x-teamcode-skill.git && bash x-teamcode-skill/install.sh
```

The install script automatically:
- Links the plugin to Claude Code's marketplace directory
- Registers the plugin in `~/.claude/settings.json`

After installation, **restart Claude Code** and type `/x-teamcode` to start.

### Uninstall

```bash
bash x-teamcode-skill/uninstall.sh
```

### Manual Installation

If you prefer to install manually, see the [install.sh](install.sh) script for the exact steps — it's short and readable.

## Usage

### Quick Start

1. Open Claude Code in your project directory
2. Type `/x-teamcode` or describe your project
3. Follow the guided workflow:
   - **Brainstorming**: Answer questions one at a time to define the design
   - **Planning**: Review the detailed implementation plan
   - **Team Setup**: Confirm the recommended team configuration
   - **Execution**: Agents work in parallel, with automatic review cycles

### Detailed Workflow

#### Phase A: Structured Planning

**A1. Brainstorming**

Claude acts as a design partner:
- Explores your project context (files, docs, commits)
- Asks clarifying questions one at a time
- Proposes 2-3 approaches with trade-offs and a recommendation
- Writes a design spec document to `docs/x-teamcode/specs/`
- Runs an automated spec self-review for quality

**A2. Writing Plans**

Based on the approved design:
- Maps out all files to create or modify
- Breaks work into bite-sized tasks (2-5 minutes each)
- Assigns role suggestions and parallel groups to each task
- Follows TDD/DRY/YAGNI principles
- Saves plan to `docs/x-teamcode/plans/`
- Runs automated plan self-review

#### Phase B: Plan-to-Team Bridge

Converts the plan into a team configuration:
- Analyzes tasks and recommends roles (backend-dev, frontend-dev, researcher, etc.)
- Maps plan tasks to team roles automatically
- Generates the `.plans/` directory structure for progress tracking
- Creates project `CLAUDE.md` with team operational knowledge
- Sets up CI infrastructure (golden_rules.py)

#### Phase C: Team Execution

Agents work in parallel:
- Each agent follows TDD, 3-Strike error handling, and context recovery protocols
- **Every task** goes through two-stage review (spec compliance + code quality)
- Phase gates ensure quality before advancing
- Final spec acceptance verifies every requirement is met

### Available Roles

| Role | Name | Capability |
|---|---|---|
| Backend Dev | `backend-dev` | Server-side code + TDD |
| Frontend Dev | `frontend-dev` | Client-side code + TDD |
| Researcher | `researcher` | Code search + web research (read-only) |
| E2E Tester | `e2e-tester` | Playwright tests + browser automation |
| Code Reviewer | `reviewer` | Security/quality/performance + spec compliance review |
| Custodian | `custodian` | Constraint compliance + doc governance + CI automation |

The team-lead (main conversation) coordinates all agents. Not every project needs all roles — the skill recommends an appropriate configuration based on your project.

### Project Artifacts

After running x-teamcode, your project will have:

```
your-project/
  CLAUDE.md                              # Team operational knowledge (auto-loaded)
  docs/x-teamcode/
    specs/YYYY-MM-DD-<topic>-design.md   # Design specification
    plans/YYYY-MM-DD-<feature>.md        # Implementation plan
  .plans/<project>/
    task_plan.md                         # Main navigation map
    phase-state.md                       # Current phase for recovery
    team-snapshot.md                     # Cached onboarding for fast resume
    findings.md / progress.md / decisions.md
    docs/                                # Architecture, API contracts, invariants
    <agent-name>/                        # Per-agent working directory
      task_plan.md / findings.md / progress.md
      <prefix>-<task>/                   # Per-task folder
  scripts/
    golden_rules.py                      # Automated quality checks
    run_ci.py                            # CI pipeline
```

### Resuming a Project

X-TeamCode supports session recovery. If you restart Claude Code or the context is compressed:

1. The skill detects existing `.plans/` directory automatically
2. Reads `phase-state.md` to determine which phase to resume from
3. Uses `team-snapshot.md` to quickly re-spawn agents without re-reading all skill files
4. Each agent reads its own task files to restore context

Simply type `/x-teamcode` again and it will offer to resume.

## When to Use X-TeamCode

**Good fit:**
- Multi-module projects (frontend + backend + tests)
- Projects needing research + development + testing phases
- Teams of 2-6 AI agents working in parallel
- Projects where spec compliance and quality matter

**Not a good fit:**
- Single-file changes or simple bug fixes
- Tasks needing only one role (use superpowers directly)
- Quick prototyping without quality requirements

## File Structure

```
x-teamcode-skill/
  .claude-plugin/
    plugin.json                          # Plugin manifest
    marketplace.json                     # Marketplace registration
  skills/x-teamcode/
    SKILL.md                             # Main skill (entry point + full workflow)
    references/
      roles.md                           # Role definitions with quality enhancements
      onboarding.md                      # Agent onboarding prompt templates
      templates.md                       # File templates for .plans/ structure
      plan-bridge.md                     # Bridge layer: plan → team tasks
    prompts/
      spec-document-reviewer.md          # Design spec self-review (Phase A)
      plan-document-reviewer.md          # Implementation plan self-review (Phase A)
      spec-reviewer-prompt.md            # Per-task spec compliance review (Phase C)
      code-quality-reviewer-prompt.md    # Per-task code quality review (Phase C)
    scripts/
      golden_rules.py                    # 5 universal code health checks
```

## Quality Practices

X-TeamCode enforces quality at every level:

| Practice | Source | When Applied |
|---|---|---|
| TDD (RED-GREEN-REFACTOR) | superpowers | Every dev task |
| Spec self-review | superpowers | After writing design spec |
| Plan self-review | superpowers | After writing implementation plan |
| Per-task spec compliance review | superpowers (adapted) | After every dev task |
| Per-task code quality review | superpowers (adapted) | After spec compliance passes |
| Verification before completion | superpowers | Before any completion claim |
| Golden rules CI | CCteam-creator | Before submitting for review |
| 3-Strike escalation | CCteam-creator | On repeated failures |
| Final spec acceptance | X-TeamCode | After all tasks complete |

## Credits

X-TeamCode builds on the work of two excellent Claude Code plugins:

- **[superpowers](https://github.com/obra/superpowers)** by Jesse Vincent — Core skills library for TDD, debugging, brainstorming, and planning workflows
- **[CCteam-creator](https://github.com/jessepwj/CCteam-creator)** by jessepwj — Multi-agent team orchestration with file-based planning and role-based collaboration

## License

MIT
