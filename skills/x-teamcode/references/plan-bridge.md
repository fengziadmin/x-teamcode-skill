# Plan-to-Team Bridge Layer

The bridge layer converts a superpowers-format implementation plan into CCteam-creator team tasks and infrastructure. This is the core innovation of x-teamcode — connecting structured planning with multi-agent execution.

## When This Runs

After Phase A (plan approved by user), before Phase C (team execution). The plan document exists at `docs/x-teamcode/plans/YYYY-MM-DD-<feature-name>.md`.

## Task-to-Role Mapping Rules

### Automatic Mapping (based on plan task metadata)

Each task in the plan has a `**Role suggestion:**` field. The bridge validates these against available roles:

| Plan Task Characteristics | Mapped Role | Signals |
|--------------------------|-------------|---------|
| Server-side code (API, DB, middleware, services) | backend-dev | File paths in `src/api/`, `src/server/`, `backend/`; mentions REST/GraphQL/DB |
| Client-side code (components, hooks, state, UI) | frontend-dev | File paths in `src/components/`, `src/pages/`, `frontend/`; mentions React/Vue/CSS |
| Research, tech evaluation, analysis | researcher | Keywords: "research", "evaluate", "compare", "analyze"; no code output |
| E2E test writing and execution | e2e-tester | Keywords: "E2E", "Playwright", "browser test"; test file paths |
| Review checkpoints in the plan | reviewer | Plan marks "review needed after this task" |
| Unit/integration tests within dev tasks | dev role (built-in TDD) | Part of dev's RED-GREEN-REFACTOR cycle, not separate |

### Multi-Instance Researchers

If the plan has 3+ independent research tasks:
- **Volume splitting**: same type of work → `researcher-1`, `researcher-2`
- **Direction splitting**: independent topics → `researcher-api`, `researcher-arch`
- **Anti-pattern**: never split sequential research (B depends on A's output)

### When to Include Custodian

Include custodian when:
- Team has 4+ agents
- Project is expected to run for multiple phases
- Plan includes explicit quality/compliance requirements

Skip custodian when:
- Small team (2-3 agents) — team-lead absorbs compliance checks
- Short project (single phase)

## Acceptance Command Generation

When converting plan tasks to team tasks, team-lead MUST write an acceptance command for each task.

**Rules:**
1. The command must be executable without manual setup (assuming the project is running)
2. The command must verify the feature produces **real output** (not just that code exists)
3. The command must fail if the implementation is hollow (empty/mock/TODO)
4. If team-lead cannot write an acceptance command, the task is too vague — decompose further

**Patterns by task type:**

| Task Type | Acceptance Command Pattern |
|---|---|
| API endpoint | `curl -s <endpoint> \| jq '<field>'` — expected: non-empty, non-null |
| Data processing | `python -c "from mod import Func; r = Func().run(input); assert len(r) > 0"` |
| UI component | E2E test command or screenshot verification |
| Integration | Pipeline command: step1 \| step2 \| step3, each step non-empty |
| Library/utility | `python -c "from lib import func; print(func(test_input))"` — expected: correct output |

## Smoke Test Generation

During Phase B, team-lead generates `.plans/<project>/smoke-tests.md`:

1. Read the plan's parallel groups to determine natural checkpoints
2. For each checkpoint (every 3-5 tasks), write a smoke test that exercises the features completed so far
3. For each phase boundary, write a full pipeline smoke test
4. Use the smoke-tests.md template from `references/templates.md`
5. Smoke tests verify end-to-end data flow, not just individual functions
6. Each test step has an explicit "Expected" annotation

## Parallel Group Extraction

Each task in the plan has a `**Parallel group:**` field. The bridge uses these to determine dispatch order:

```
Group A (parallel): Tasks 1, 2, 3 — no dependencies between them
Group B (parallel): Tasks 4, 5 — depend on Group A completing
Group C (sequential): Task 6 — depends on specific task in Group B
```

Rules:
- Tasks in the same group can be dispatched simultaneously
- Groups are dispatched in order (A before B before C)
- Within a group, each task goes to its assigned role
- If a role has multiple tasks in the same group, dispatch them together in one message

## .plans/ Directory Generation

### From Plan to Main task_plan.md

The main `.plans/<project>/task_plan.md` is a **lean navigation map**, NOT a copy of the full plan. It references the original plan for details:

```markdown
# <Project Name> - Main Plan

> Status: EXECUTING
> Created: <date>
> Team: <team-name> (<role list>)
> Source Plan: docs/x-teamcode/plans/<filename>.md
> Source Spec: docs/x-teamcode/specs/<filename>.md

## 1. Project Overview

<1-2 sentences from plan Goal>

## 2. Docs Index

| Document | Location | Content |
|----------|----------|---------|
| Design Spec | docs/x-teamcode/specs/<file>.md | Original design specification |
| Implementation Plan | docs/x-teamcode/plans/<file>.md | Detailed task steps with code |
| Architecture | .plans/<project>/docs/architecture.md | System components, data flow |
| API Contracts | .plans/<project>/docs/api-contracts.md | Interface definitions |
| Invariants | .plans/<project>/docs/invariants.md | System boundaries |

## 3. Phases Overview

### Slicing Principle
Break tasks into vertical slices (tracer bullets), NOT horizontal slices by tech layer.

### Phases
- Phase 0: Team Setup + Context Alignment
- Phase 1: <from plan parallel groups>
- Phase 2: <from plan parallel groups>
- Phase N: Review & Cleanup

## 4. Task Summary

| # | Task | Owner | Parallel Group | Status | Plan Reference |
|---|------|-------|----------------|--------|---------------|
| T1 | <name> | <role> | A | pending | Plan Task 1 |
| T2 | <name> | <role> | A | pending | Plan Task 2 |
| T3 | <name> | <role> | B | pending | Plan Task 3 |

## 5. Current Phase

Phase 0: Team created, agents spawning.
```

### From Plan to Per-Agent task_plan.md

Each agent's `.plans/<project>/<agent-name>/task_plan.md` extracts ONLY that agent's tasks:

```markdown
# <Agent Name> - Task Plan

> Role: <role description>
> Status: pending
> Source Plan: docs/x-teamcode/plans/<filename>.md

## Tasks

- [ ] Task N: <description> (Plan Task N, Parallel Group A)
  - Detailed steps: see source plan Task N
  - Dependencies: <list>
  - Acceptance criteria: <from plan>

- [ ] Task M: <description> (Plan Task M, Parallel Group B)
  - Detailed steps: see source plan Task M
  - Dependencies: Task N complete
  - Acceptance criteria: <from plan>

## Notes

- Original design spec: docs/x-teamcode/specs/<file>.md
- Full implementation plan: docs/x-teamcode/plans/<file>.md
- Read these when you need detailed context beyond what's in this task plan.
```

### Populating docs/ from Spec

Extract structured content from the design spec:

1. **docs/architecture.md**: From spec's architecture/components/data flow sections
2. **docs/api-contracts.md**: From spec's API definitions (if present)
3. **docs/invariants.md**: From spec's constraints/boundaries (if present), plus standard entries
4. **docs/index.md**: Navigation map linking to all docs with section names and line ranges

If the spec doesn't have a section for a particular doc, create a skeleton with a note: "To be populated during development."

## CLAUDE.md Generation

Generate CLAUDE.md in the project working directory using the template from `references/templates.md`. Key additions for x-teamcode:

1. **Source Documents section** (added to Docs Index):
```markdown
| Design Spec | docs/x-teamcode/specs/<file>.md | Original design (brainstorming output) |
| Implementation Plan | docs/x-teamcode/plans/<file>.md | Detailed tasks (planning output) |
```

2. **Review Dimensions** (from B3 user input):
Populate the Review Dimensions table with actual dimensions, not examples.

3. **Key Protocols** (add x-teamcode specific entries):
```markdown
| Spec compliance review | After each major task | Reviewer checks implementation against docs/x-teamcode/specs/ |
| Plan deviation | Dev finds plan doesn't match reality | Record in findings.md + notify team-lead. Lead updates plan if needed |
```

## phase-state.md Format

Track the current phase for recovery purposes:

```markdown
# Phase State

> Project: <project-name>
> Last updated: <date>

phase: planning | bridging | executing | complete

## Phase History

- <date>: planning — brainstorming started
- <date>: planning — spec written and approved
- <date>: planning — plan written and approved
- <date>: bridging — team configuration confirmed
- <date>: executing — team created, agents spawned
- <date>: complete — all tasks done, review passed
```

## Recovery Logic

When resuming a project, check `phase-state.md`:

| Phase | Recovery Action |
|-------|----------------|
| `planning` | Read existing specs/plans in `docs/x-teamcode/`. Resume where brainstorming or plan writing left off. |
| `bridging` | Read the completed plan. Check what infrastructure has been generated. Resume bridge steps. |
| `executing` | Use CCteam standard resume: check `team-snapshot.md`, spawn agents from cache, read progress files. |
| `complete` | Inform user project is already complete. Offer to start a new project or review. |

## Information Flow Summary

```
Design Spec (docs/x-teamcode/specs/)
    ↓ referenced by
Implementation Plan (docs/x-teamcode/plans/)
    ↓ extracted into
Main task_plan.md (.plans/<project>/)
    ↓ split into
Per-Agent task_plan.md (.plans/<project>/<agent>/)
    ↓ links back to
Implementation Plan (for detailed steps and code)
    ↓ links back to
Design Spec (for requirements validation)
```

The original spec and plan are NEVER deleted or replaced. They serve as the authoritative reference throughout execution. The .plans/ files are navigation aids and progress trackers, not content replacements.
