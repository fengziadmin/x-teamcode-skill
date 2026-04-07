---
name: x-teamcode
description: >
  Structured planning (superpowers) + multi-agent team execution (CCteam-creator).
  Combines brainstorming and detailed plan writing with parallel AI agent team orchestration.
  Use when: (1) complex projects needing structured plan + parallel team execution,
  (2) user says "x-teamcode", "plan and team", "structured team development",
  (3) multi-module projects that benefit from role-based parallel work.
  TRIGGER on: "x-teamcode", "plan and team", "structured team development",
  "计划+团队", "结构化团队开发".
  NOT suitable for: single-file changes, simple bug fixes, tasks needing only one role.
  IMPORTANT: You (team-lead) MUST read all reference files directly — do NOT delegate to subagents.
---

# X-TeamCode: Structured Planning + Team Execution

Combine superpowers' disciplined planning workflow with CCteam-creator's multi-agent team execution for complex projects.

## Prerequisites

**Before starting any step**, you (team-lead) MUST read all reference files directly into your own context:

```
Read references/roles.md
Read references/onboarding.md
Read references/templates.md
Read references/plan-bridge.md
```

Do NOT delegate this to a subagent (Explore, general-purpose, etc.). Subagents return summaries, losing critical detail — you need the full templates and onboarding prompts to generate files and spawn agents correctly.

## Process Overview

```
Phase A: Structured Planning (from superpowers)
  A1. Brainstorming → design spec
  A2. Writing Plans → implementation plan
      ↓
Phase B: Plan-to-Team Bridge (NEW)
  B1. Analyze plan → recommend team config
  B2. Map tasks to roles
  B3. Generate .plans/ infrastructure
  B4. User confirms team
      ↓
Phase C: Team Execution (from CCteam-creator)
  C1. Create team + spawn agents
  C2. Parallel execution
  C3. Quality gates
  C4. Completion
```

## Step 0: Detect Existing Project (Auto — Before Anything Else)

Before starting, check for existing project state.

**Check `.plans/` directory**:
- If exists → read project CLAUDE.md, scan for project directories
- Tell user: "I found an existing project [name]. Resume or start new?"
- **If resume**: Check `phase-state.md` to determine which phase to resume from:
  - `phase: planning` → resume Phase A, read existing specs/plans in `docs/x-teamcode/`
  - `phase: bridging` → resume Phase B, read plan and generated infrastructure
  - `phase: executing` → use CCteam standard resume (check `team-snapshot.md`, spawn agents from cache)
- **If new**: Proceed to Phase A

**Check `docs/x-teamcode/` directory**:
- If specs/plans exist but no `.plans/` → previous planning was done but team not created yet. Resume from Phase B.

**If nothing exists**: Skip directly to Phase A.

---

## Phase A: Structured Planning

### A1: Brainstorming

<HARD-GATE>
Do NOT write any code, create any teams, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

**Checklist** (complete in order):

1. **Explore project context** — check files, docs, recent commits
2. **Assess scope** — if the request describes multiple independent subsystems, flag immediately. Help user decompose into sub-projects first. Each sub-project gets its own spec → plan → team cycle.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
   - Prefer multiple choice when possible
   - Only one question per message
   - Focus on: purpose, constraints, success criteria, tech stack
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
   - Lead with your recommended option and explain why
   - Scale detail to complexity
5. **Present design** — in sections scaled to complexity
   - Ask after each section whether it looks right
   - Cover: architecture, components, data flow, error handling, testing
6. **Write design doc** — save to `docs/x-teamcode/specs/YYYY-MM-DD-<topic>-design.md`
   - Add a `## Team Execution Suggestions` section at the end:
     - Recommended roles for this project
     - Which modules can be worked on in parallel
     - Key dependency paths between components
   - Commit the design document to git
7. **Spec self-review** — dispatch a spec-document-reviewer subagent (see `prompts/spec-document-reviewer.md`), max 3 rounds
   - Fix any FAIL items inline
8. **User reviews written spec** — ask user to review before proceeding
   - Wait for user approval. If changes requested, revise and re-review.
9. **Transition** — proceed to A2 (Writing Plans)

**Key Principles:**
- One question at a time — don't overwhelm
- Multiple choice preferred — easier to answer
- YAGNI ruthlessly — remove unnecessary features
- Explore alternatives — always propose 2-3 approaches
- Design for isolation — smaller units with clear boundaries

### A2: Writing Plans

**Announce**: "I'm using x-teamcode to create the implementation plan."

**Checklist** (complete in order):

1. **Scope check** — if spec covers multiple independent subsystems, suggest separate plans
2. **Map file structure** — which files will be created or modified, what each is responsible for
   - Design units with clear boundaries and well-defined interfaces
   - Each file should have one clear responsibility
   - Follow existing codebase patterns
3. **Task decomposition** — break into bite-sized steps (2-5 minutes each)
   - Each step is one action: write test → run test → implement → run test → commit
   - TDD/DRY/YAGNI throughout
   - **Each Task MUST include**:
     - `**Role suggestion:**` which CCteam role should handle it
     - `**Parallel group:**` which tasks can run simultaneously
     - `**Dependencies:**` which tasks must complete first
4. **Write plan** — save to `docs/x-teamcode/plans/YYYY-MM-DD-<feature-name>.md`
   - Use this header format:

```markdown
# [Feature Name] Implementation Plan

> **Execution mode:** x-teamcode team execution
> **Suggested roles:** backend-dev, frontend-dev, researcher, e2e-tester, reviewer
> **Parallel groups:** [Group A: Tasks 1-3] [Group B: Tasks 4-5, after Group A]
> **Spec:** docs/x-teamcode/specs/YYYY-MM-DD-<topic>-design.md

**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
```

5. **No placeholders** — every step must contain actual content:
   - Never write "TBD", "TODO", "add appropriate error handling"
   - Every code step must have a code block
   - Exact file paths always
   - Exact commands with expected output
6. **Plan self-review** — dispatch a plan-document-reviewer subagent (see `prompts/plan-document-reviewer.md`), max 3 rounds
   - Fix any FAIL items inline
7. **User reviews plan** — ask user to review before proceeding
8. **Update phase state** — write `phase-state.md` with `phase: bridging`
9. **Transition** — proceed to Phase B

---

## Phase B: Plan-to-Team Bridge

See [references/plan-bridge.md](references/plan-bridge.md) for detailed bridge layer specification.

### B1: Analyze Plan → Recommend Team Configuration

1. Read the completed plan document
2. Parse all Tasks' role suggestions and parallel group assignments
3. Assess tech stack and project complexity
4. Generate team configuration recommendation:
   - Which roles are needed (from the 6 standard roles + any custom)
   - How many instances of each role
   - Model selection (sonnet default, opus for critical roles)
   - Task-to-role assignment mapping

**Recommendation principles** (from CCteam-creator):
- More roles is not always better — choose based on actual project needs
- Small projects may only need 1 dev + 1 researcher
- custodian recommended for teams with 4+ agents
- Multi-instance researchers for large parallel research workloads

### B2: Gather Team-Specific Requirements

Through natural conversation, learn:
1. **Working language** — match the user's language in CLAUDE.md and onboarding prompts
2. **User involvement** — every decision, or autonomous?
3. **Quality priorities** — 3-5 Review Dimensions for the reviewer (what STRONG vs WEAK looks like)
4. **Special constraints** — deadlines, standards, tech requirements

### B3: User Confirms Team Configuration

Use AskUserQuestion to get final confirmation on:
- **Project name**: short, ASCII, kebab-case
- **Brief description**: 1-2 sentences
- **Confirmed role list**: which roles, what each does
- **Review Dimensions**: 3-5 weighted dimensions with calibration anchors

Only proceed after user confirms.

### B4: Generate .plans/ Infrastructure

See [references/templates.md](references/templates.md) for all file templates.

1. **Create .plans/<project>/ directory structure**:
   - Main files: task_plan.md, findings.md, progress.md, decisions.md
   - docs/: index.md, architecture.md, api-contracts.md, invariants.md
   - Per-agent directories with task_plan.md, findings.md, progress.md

2. **Convert superpowers plan to team task_plan.md**:
   - Main task_plan.md: lean navigation map with phase overview and task summary table
   - Per-agent task_plan.md: extract each role's tasks from the master plan
   - Link back to original plan: `See docs/x-teamcode/plans/<filename>.md for detailed steps`

3. **Populate docs/ from spec**:
   - architecture.md: extract from spec's architecture section
   - api-contracts.md: extract API definitions if present
   - invariants.md: initial system boundaries

4. **Generate project CLAUDE.md**:
   - Use the template from references/templates.md
   - Dynamically fill based on confirmed roles
   - Include Review Dimensions from B3
   - If CLAUDE.md already exists, append team operations section

5. **Harness setup** (code projects only):
   - Copy golden_rules.py to project `scripts/`
   - Configure SRC_DIRS
   - Create CI script skeleton (`scripts/run_ci.py`)

6. **Write phase-state.md**: `phase: executing`

### B5: Compact Context Checkpoint

After generating all infrastructure, recommend the user runs `/compact`:
- All plan artifacts are now persisted to the file system
- CLAUDE.md keeps operational knowledge in context
- Compacting reclaims context space for team management

---

## Phase C: Team Execution

### C1: Create Team + Spawn Agents

1. `TeamCreate(team_name: "<project>")`
2. Create tasks via TaskCreate — one-line scope + acceptance criteria + `.plans/` path
3. Set dependencies and owners via TaskUpdate
4. Spawn each role in parallel (`run_in_background: true`)
   - Use onboarding prompt from references/onboarding.md (common template + role-specific additions)
   - Include project-specific context (spec/plan references, Review Dimensions)
5. Generate `team-snapshot.md` — cached onboarding prompts + skill file timestamps

### C2: Parallel Execution

Agents work autonomously following their onboarding protocols:
- **TDD iron law** embedded in dev onboarding: no production code without a failing test first
- **verification-before-completion** as hard gate: run verification commands before claiming done
- **2-Action Rule**: after every 2 search/read ops, update findings.md
- **3-Strike protocol**: 3 failures → escalate to team-lead
- **Context recovery**: after compaction, read task files in order
- **Doc-Code sync**: API/architecture changes → must update docs/

### C3: Per-Task Convergence Cycle (Goal Convergence — Core Mechanism)

Every dev task goes through a **two-stage review cycle** to ensure convergence toward the original spec. This is adapted from superpowers' subagent-driven-development, applied to team mode.

```
Dev completes task
    ↓
Dev runs CI (golden_rules.py + tests) — must PASS
    ↓
Dev → SendMessage(to: "reviewer") requesting spec compliance review
    ↓
[Stage 1: Spec Compliance Review]
    Reviewer reads actual code + compares to spec line by line
    (see prompts/spec-reviewer-prompt.md)
    ↓
    ✅ Spec compliant → proceed to Stage 2
    ❌ Issues found → Dev fixes → Reviewer re-reviews (max 3 rounds)
    ↓
[Stage 2: Code Quality Review]
    Reviewer checks security/quality/performance/dimensions
    (see prompts/code-quality-reviewer-prompt.md)
    ↓
    [OK]/[WARN] → Task approved, mark complete
    [BLOCK] → Dev fixes → Reviewer re-reviews (max 3 rounds)
    ↓
Reviewer → SendMessage(to: "team-lead") with review summary
```

**Key convergence rules:**
- **Every task gets reviewed.** Not just "large features" — every task that changes code.
- **Spec compliance BEFORE code quality.** Wrong order = wasted effort reviewing code that doesn't match spec.
- **Do NOT trust dev's self-report.** Reviewer reads actual code independently.
- **Maximum 3 review rounds per stage.** If issues persist → escalate to team-lead.
- **Small tasks exception**: Bug fixes, config changes, and single-line changes can skip the two-stage cycle. Dev uses judgment; reviewer can request full review if needed.

### C4: Phase Progression Gates

1. **Research phase done**: team-lead reads researcher findings → updates main plan architecture section
2. **Dev phase done**: all dev tasks passed two-stage review → team-lead confirms
3. **E2E testing done**: e2e-tester results reviewed → team-lead confirms pass rate

### C5: Final Spec Acceptance (Goal Convergence — Final Gate)

After ALL tasks are complete, team-lead performs a **full spec acceptance review**:

1. **Re-read the original spec**: `docs/x-teamcode/specs/<file>.md`
2. **Create acceptance checklist**: one item per spec requirement
3. **Verify each requirement**:
   - Is it implemented? (check code or test evidence)
   - Does it work as specified? (check test results or reviewer reports)
   - Is there evidence? (test output, reviewer [OK], CI green)
4. **Gap analysis**: list any requirements NOT fully met
5. **Report to user**:

```markdown
## Final Spec Acceptance

### Spec: docs/x-teamcode/specs/<file>.md
### Status: ✅ ALL REQUIREMENTS MET | ❌ GAPS FOUND

| # | Requirement | Status | Evidence |
|---|------------|--------|----------|
| R1 | <from spec> | ✅ | reviewer [OK] + tests pass |
| R2 | <from spec> | ✅ | reviewer [OK] + e2e pass |
| R3 | <from spec> | ❌ | not implemented / partial |

### Gaps (if any)
- R3: <description of what's missing and recommended action>

### Recommendation
- ✅ Ready for completion / ❌ Needs additional work on: R3
```

6. **If gaps found**: dispatch dev to fix → re-run two-stage review → re-verify
7. **If all met**: proceed to C6

### C6: Completion

1. Final CI run across all code
2. Team-lead presents final spec acceptance report to user
3. Use `finishing-a-development-branch` workflow if applicable:
   - Run full test suite
   - Present options: merge, PR, keep branch, or discard
4. Clean up: update phase-state.md to `phase: complete`

---

## Key Rules

### From Superpowers (Planning Quality)
- **HARD-GATE**: No implementation before design approval
- **One question at a time**: Don't overwhelm during brainstorming
- **YAGNI**: Remove unnecessary features from all designs
- **TDD**: No production code without a failing test first
- **Verification before completion**: Run commands and confirm output before claiming done
- **No placeholders**: Every plan step must have actual, complete content

### From CCteam-creator (Team Execution)
- **Dual-system, no duplication**: .plans/ = source of truth; TaskCreate = live dispatch layer
- **Team-lead is control plane**: owns user alignment, task decomposition, phase gates
- **No standalone subagents after team exists**: ALL work goes through teammates via SendMessage
- **Context recovery**: agents must read their task files after compaction
- **All roles use task folders**: every assigned task gets a dedicated folder
- **CI gate before review**: dev runs CI, all checks PASS before submitting
- **3-Strike escalation**: 3 failures → escalate, never silently retry
- **Anti-bloat**: root findings.md is pure index, no content dumping
- **Peer review**: dev contacts reviewer directly, not through team-lead

### Goal Convergence (from superpowers, adapted for team mode)
- **Per-task two-stage review**: every task → spec compliance first, then code quality (see C3)
- **Spec compliance before code quality**: wrong order = wasted effort
- **Do not trust self-reports**: reviewer reads actual code, not dev's summary
- **Maximum 3 review rounds**: per stage per task; escalate if unresolved
- **Final spec acceptance**: after all tasks, team-lead verifies every spec requirement is met (see C5)
- **Evidence before claims**: no completion without verification command output
- **Feedback loop**: review issues → dev fixes → re-review → confirm fix (never skip re-review)

### Combined (Bridge Layer)
- **Plan-to-role mapping**: every plan task gets a role suggestion and parallel group
- **Phase state tracking**: phase-state.md tracks A/B/C phases for recovery
- **Original docs preserved**: spec and plan in docs/x-teamcode/ serve as authority references

---

## Team-Lead Operations Guide

### Status Check

| What to Check | How |
|---------------|-----|
| Overview | `TaskList` — all tasks, owners, blockers |
| Quick scan | Read each agent's `progress.md` in parallel |
| Deep dive | Read agent's `findings.md` (index) then specific task folder |
| Direction check | Read `.plans/<project>/task_plan.md` |
| Spec compliance | Read `docs/x-teamcode/specs/` and compare with implementation |

Reading order: **progress** (where are we) → **findings** (what happened) → **task_plan** (what's the goal)

### Phase Advancement

- Research done → read researcher findings → update main plan architecture
- Dev done → wait for reviewer [OK]/[WARN] → advance
- All done → parallel read all progress.md → confirm complete

### 3-Strike Escalation Handling

When an agent reports "3 failures, escalating":
1. Read their progress.md attempted steps
2. Assess whether main plan needs revision
3. Provide new direction or reassign
4. **Guardrail check**: Will this recur?
   - YES for this project → append to CLAUDE.md Known Pitfalls
   - YES for future teams → also flag `[TEAM-PROTOCOL]`
   - NO → no further action

### Template Sync vs Project-Local

- **Project-local**: only this project needs it → update project docs
- **Template-level**: future teams should inherit → update x-teamcode source files first
