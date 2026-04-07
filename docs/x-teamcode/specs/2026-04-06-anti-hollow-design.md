# Anti-Hollow Implementation & Robustness Enhancement — Design Spec

## Problem Statement

X-TeamCode's current quality gates check **structure** but not **substance**. Agents produce code that looks complete (tests pass, CI green, functions exist) but core business logic is hollow — `pass` bodies, mock returns, empty orchestration. Additionally, agents may hallucinate completion, hang without progress, or lose track after context compression.

Three observed symptoms:
1. **Task execution incomplete** (~65% completion) — agents build scaffolding but leave core logic as empty shells
2. **Bugs in final output** — integration failures, logic errors, and hollow implementations all mixed
3. **Hallucination/hang** — agents claim done without doing; become unresponsive; team-lead loses state

Root cause: quality gates verify "function exists + tests pass" but not "function actually does what the spec says."

## Solution: B + C Combination

Combine **execution granularity improvements** (B) with **automated detection mechanisms** (C).

---

## Part 1: Task Decomposition — Acceptance Commands

### Core Change

Every task in the implementation plan MUST include an `Acceptance command` — an executable command that proves the feature actually works, written by team-lead at dispatch time (not by the dev).

### New Task Format

```markdown
### Task N: [Component Name]
**Role:** backend-dev
**Parallel group:** A
**Dependencies:** Task M
**Files:**
- Create: `exact/path/to/file.py`
- Test: `tests/exact/path/to/test.py`

**Acceptance command:**
  python -c "from src.module import Func; r = Func().run('input'); assert len(r) > 0 and 'TODO' not in str(r), f'Got: {r}'"

**Anti-hollow checks:**
  - No `pass` in function bodies
  - No hardcoded return values
  - Response must come from actual processing, not mock data

**Steps:**
- [ ] Write failing test (must assert on REAL output content, not just function existence)
- [ ] Implement
- [ ] Run acceptance command — paste full stdout
- [ ] Commit
```

### Rules

1. **Every task has an acceptance command.** No exceptions. If team-lead cannot write one, the task is too vague and needs decomposition.
2. **Team-lead writes the acceptance command**, not the dev. This prevents the dev from writing a self-passing check.
3. **Dev must paste raw stdout** of the acceptance command in their completion report. Not "acceptance passed" — the actual terminal output.
4. **Reviewer verifies** by re-running the acceptance command independently.
5. **Integration checkpoints**: every 3-5 tasks, team-lead triggers a cross-module smoke test.

### Test Quality Requirements

Tests must assert on **output substance**, not structure:

```python
# BAD — tests structure only
def test_llm_client():
    client = LLMClient()
    assert client is not None
    assert hasattr(client, 'generate')

# GOOD — tests actual behavior
def test_llm_client_generates_content():
    client = LLMClient()
    result = client.generate("Summarize: AI is transforming software.")
    assert len(result) > 20  # non-trivial output
    assert result != "TODO"
    assert "AI" in result or "software" in result  # contextually relevant
```

---

## Part 2: Automated Detection — 4 Layers

### Layer 1: GR-6 Hollow Implementation Scanner

New check added to `golden_rules.py`. Runs in CI before review.

**Detects:**

| Pattern | Example | Severity |
|---|---|---|
| Empty function body | `def process(self): pass` | FAIL |
| Ellipsis body | `def process(self): ...` | FAIL |
| NotImplementedError | `raise NotImplementedError` | FAIL |
| Hardcoded return | `return "TODO"`, `return {}`, `return None` (in non-trivial functions) | WARN |
| Shallow test assertion | `assert func is not None`, `assert callable(func)` | WARN |
| Mock data as real return | Function returns a static dict/string that looks like mock data | WARN |

**Output format (agent-readable):**

```
[FAIL] [GR-HOLLOW] src/export/word.py:85 — _apply_template() body is `pass`
  FIX: Implement actual template application. Empty function bodies are not allowed.

[WARN] [GR-HOLLOW] tests/test_llm.py:23 — test only asserts function exists, not output
  FIX: Add assertion on actual output: assert len(result.content) > 0
```

**Scope:**
- Scans all code files in SRC_DIRS
- Skips: test fixtures, abstract base classes (explicitly marked), interface definitions
- Configurable allowlist for intentionally empty methods (e.g., `__init__` with no args)

### Layer 2: Agent Heartbeat Monitoring

Team-lead protocol addition for detecting hung/dead agents.

**Protocol:**

```
After dispatching tasks:
  1. Note the dispatch time
  2. Set a check interval (default: after reasonable time based on task complexity)
  3. At check time:
     a. Read each active agent's progress.md (last 5 lines)
     b. If updated since dispatch → agent is alive, continue
     c. If NOT updated → SendMessage asking for status
     d. If no reply after follow-up → mark as HUNG
     e. HUNG agent → re-spawn with same task context from .plans/ files
```

**Added to CLAUDE.md Key Protocols table:**

```
| Agent heartbeat | After task dispatch | Team-lead checks progress.md activity; no update → ping; no reply → re-spawn |
```

**Added to team-lead operations guide** as a new section.

### Layer 3: Hallucination Detection

Reviewer enhancement — added to both review stages.

**Detection method:**

After receiving a dev's completion report, reviewer performs:

1. **Report vs Diff check**: Read the dev's report claims. Then read `git diff`. For each claim:
   - "Implemented LLM integration" → Is there actual API call code in the diff?
   - "All tests pass" → Does CI output confirm this?
   - "Added error handling" → Are there try/catch blocks in the diff?

2. **Report vs Acceptance check**: Re-run the acceptance command. Does output match what dev reported?

3. **Marking**: If discrepancy found → `[HALLUCINATION]` tag, severity CRITICAL, auto-escalate to team-lead.

**Added to spec-reviewer-prompt.md** as a mandatory step.

### Layer 4: Integration Smoke Tests

Phase-level validation that the system actually works end-to-end.

**When triggered:**
- After every 3-5 dev tasks (integration checkpoint)
- At every phase boundary (mandatory)
- Before final spec acceptance (mandatory)

**Format:**

Team-lead defines smoke tests during Phase B (plan-to-team bridge), stored in `.plans/<project>/smoke-tests.md`:

```markdown
# Smoke Tests

## Checkpoint 1 (after Tasks 1-5)
```bash
# Test: document upload and extraction
curl -s -X POST http://localhost:8000/api/upload -F file=@test.pdf | jq '.doc_id'
# Expected: non-empty string, not null

# Test: knowledge extraction produces chunks
DOC_ID=$(curl -s -X POST http://localhost:8000/api/upload -F file=@test.pdf | jq -r '.doc_id')
curl -s http://localhost:8000/api/knowledge/$DOC_ID/extract | jq '.chunks | length'
# Expected: > 0
```

## Phase 2 Complete (full pipeline)
```bash
# End-to-end: upload → extract → outline → export
# Each step must produce non-empty, non-default output
```
```

**Rules:**
- Smoke tests are defined by team-lead, not devs
- Each test has an explicit "Expected" annotation
- Any step returning empty/null/default → PHASE BLOCKED
- Smoke test results recorded in `.plans/<project>/findings.md`

---

## Integration Points

### Files Modified

| File | Change |
|---|---|
| `SKILL.md` | Phase A2: task format includes acceptance command. Phase C: add heartbeat protocol, integration checkpoints, smoke test triggers |
| `references/roles.md` | reviewer: add hallucination detection duty. dev: add acceptance command protocol |
| `references/onboarding.md` | dev section: acceptance command execution + output pasting. reviewer section: hallucination detection steps |
| `references/plan-bridge.md` | Bridge generates acceptance commands per task + smoke-tests.md |
| `references/templates.md` | Task template: add acceptance command field. New template: smoke-tests.md |
| `prompts/spec-reviewer-prompt.md` | Add hallucination detection (report vs diff vs acceptance) |
| `scripts/golden_rules.py` | Add GR-6 hollow implementation scanner |

### Flow Change

```
BEFORE:
  Plan → Dispatch → Dev implements → CI → Reviewer reads code → Done

AFTER:
  Plan (with acceptance commands + smoke tests)
    → Dispatch (team-lead writes acceptance command per task)
    → Dev implements → Dev runs acceptance command (pastes stdout)
    → CI (with GR-6 hollow scan) → Reviewer (reads code + re-runs acceptance + hallucination check)
    → Done
    → Every 3-5 tasks: integration smoke test
    → Phase end: full pipeline smoke test

  Parallel: team-lead heartbeat monitoring (detect hung agents)
```

### What Does NOT Change

- Phase A brainstorming and writing-plans flow
- Phase B bridge logic (only task template enriched)
- Two-stage review framework (enhanced, not replaced)
- 6 standard roles (duties enhanced, not restructured)
- 3-Strike, context recovery, file persistence, team-snapshot
- golden_rules GR-1 through GR-5

---

## Success Criteria

After implementing these changes, the following should hold:

1. **No hollow implementations pass review**: GR-6 catches `pass`/empty bodies before reviewer sees the code
2. **Every task has proof of function**: acceptance command output is on record, not just "tests pass"
3. **Hallucinations are caught**: reviewer detects claims that don't match actual code/output
4. **Hung agents are recovered**: team-lead detects and re-spawns unresponsive agents
5. **Integration works before phase advances**: smoke tests block progression if pipeline is broken
6. **Completion rate improves from ~65% to 90%+**: hollow implementations are no longer counted as "complete"
