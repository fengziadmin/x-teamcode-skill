# Anti-Hollow Implementation Plan

> **Execution mode:** Inline (modify skill files directly in this session)
> **Spec:** docs/x-teamcode/specs/2026-04-06-anti-hollow-design.md

**Goal:** Add anti-hollow implementation detection, acceptance commands, heartbeat monitoring, hallucination detection, and integration smoke tests to the x-teamcode skill.

**Architecture:** 7 file modifications — GR-6 scanner in golden_rules.py, task format + convergence protocol in SKILL.md, acceptance command protocol in onboarding.md, hallucination detection in spec-reviewer-prompt.md, reviewer duties in roles.md, task templates in templates.md, smoke test generation in plan-bridge.md.

**Tech Stack:** Python (golden_rules.py), Markdown (all other files)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `scripts/golden_rules.py` | Modify (add GR-6) | Hollow implementation scanner |
| `SKILL.md` | Modify (Phase A2 task format + Phase C protocols) | Acceptance command in task format, heartbeat protocol, smoke test triggers |
| `references/onboarding.md` | Modify (dev + reviewer sections) | Dev: acceptance command execution. Reviewer: hallucination detection |
| `prompts/spec-reviewer-prompt.md` | Modify (add hallucination detection step) | Report-vs-diff-vs-acceptance verification |
| `references/roles.md` | Modify (reviewer role) | Hallucination detection duty + acceptance command re-run |
| `references/templates.md` | Modify (task template + new smoke-tests template) | Acceptance command field + smoke-tests.md template |
| `references/plan-bridge.md` | Modify (bridge generation) | Generate smoke-tests.md + acceptance commands |

---

### Task 1: Add GR-6 Hollow Implementation Scanner to golden_rules.py

**File:** Modify: `skills/x-teamcode/scripts/golden_rules.py:265-305`

- [ ] **Step 1: Add the hollow implementation detection function**

After `check_invariant_coverage` (line 272) and before the `check_all` function (line 278), add:

```python
# ---------------------------------------------------------------------------
# GR-6: Hollow Implementation Detection
# ---------------------------------------------------------------------------
HOLLOW_BODY_PATTERNS = [
    (r"^\s*pass\s*$", "Function body is `pass`"),
    (r"^\s*\.\.\.\s*$", "Function body is `...` (ellipsis)"),
    (r"^\s*raise\s+NotImplementedError", "Function raises NotImplementedError"),
]

HOLLOW_RETURN_PATTERNS = [
    (r"""^\s*return\s+['"]TODO['"]""", "Returns hardcoded 'TODO'"),
    (r"""^\s*return\s+['"]not.?implemented['"]""", "Returns 'not implemented' string"),
    (r"^\s*return\s+\{\s*\}\s*$", "Returns empty dict"),
    (r"^\s*return\s+\[\s*\]\s*$", "Returns empty list"),
    (r"^\s*return\s+None\s*$", "Returns None explicitly"),
]

SHALLOW_TEST_PATTERNS = [
    (r"assert\s+\w+\s+is\s+not\s+None\s*$", "Test only checks not-None"),
    (r"assert\s+callable\s*\(", "Test only checks callable"),
    (r"assert\s+hasattr\s*\(", "Test only checks attribute exists"),
]

# Markers that indicate intentionally empty implementations (skip these)
INTENTIONAL_EMPTY_MARKERS = (
    "@abstractmethod",
    "# intentionally empty",
    "# abstract",
    "# interface",
    "# placeholder — will be implemented by subclass",
)


def _is_inside_function(lines, line_idx):
    """Check if a line is inside a function/method body (rough heuristic)."""
    for i in range(line_idx - 1, max(line_idx - 10, -1), -1):
        stripped = lines[i].strip()
        if stripped.startswith("def ") or stripped.startswith("async def "):
            return True
        if stripped and not stripped.startswith("#") and not stripped.startswith("@"):
            break
    return False


def _has_intentional_marker(lines, line_idx):
    """Check if nearby lines contain a marker indicating intentionally empty code."""
    start = max(0, line_idx - 5)
    end = min(len(lines), line_idx + 2)
    context = "\n".join(lines[start:end]).lower()
    return any(marker.lower() in context for marker in INTENTIONAL_EMPTY_MARKERS)


def check_hollow_implementation(src_dirs, result):
    """Detect hollow implementations: pass bodies, hardcoded returns, shallow tests."""
    print("[GR-6] Hollow Implementation Check")
    found = False

    for f in _iter_code_files(src_dirs):
        try:
            content = f.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        lines = content.splitlines()
        is_test_file = any(part in {"test", "tests", "__tests__", "spec"} for part in f.parts) or f.name.startswith("test_")

        for i, line in enumerate(lines):
            # Skip comments
            if line.strip().startswith("#"):
                continue

            # Check for intentional markers
            if _has_intentional_marker(lines, i):
                continue

            if not is_test_file and _is_inside_function(lines, i):
                # Check hollow bodies
                for pattern, desc in HOLLOW_BODY_PATTERNS:
                    if re.search(pattern, line):
                        result.fail(
                            "GR-HOLLOW",
                            f"{f}:{i+1} -- {desc}: {line.strip()[:80]}",
                            "Implement actual logic. Empty function bodies are not allowed in production code.")
                        found = True
                        break

                # Check hollow returns
                for pattern, desc in HOLLOW_RETURN_PATTERNS:
                    if re.search(pattern, line):
                        result.warn(
                            "GR-HOLLOW",
                            f"{f}:{i+1} -- {desc}: {line.strip()[:80]}",
                            "Replace with actual computed return value. Hardcoded/empty returns suggest incomplete implementation.")
                        found = True
                        break

            if is_test_file:
                # Check shallow tests
                for pattern, desc in SHALLOW_TEST_PATTERNS:
                    if re.search(pattern, line):
                        result.warn(
                            "GR-HOLLOW-TEST",
                            f"{f}:{i+1} -- {desc}: {line.strip()[:80]}",
                            "Add assertions on actual output content (e.g., assert len(result) > 0, assert 'expected' in result).")
                        found = True
                        break

    if not found:
        print("  [OK] No hollow implementations detected.\n")
```

- [ ] **Step 2: Register GR-6 in `check_all` function**

In `check_all()` (around line 286), add the call after `check_console_log`:

```python
    check_file_size(src_dirs, result)
    check_secrets(src_dirs, result)
    check_console_log(src_dirs, result)
    check_hollow_implementation(src_dirs, result)
```

- [ ] **Step 3: Run the script to verify no syntax errors**

Run: `python3 skills/x-teamcode/scripts/golden_rules.py skills/x-teamcode/scripts/`
Expected: Completes without Python errors (may show 0 findings since scripts/ has no hollow code)

- [ ] **Step 4: Commit**

```bash
git add skills/x-teamcode/scripts/golden_rules.py
git commit -m "feat: add GR-6 hollow implementation scanner"
```

---

### Task 2: Update SKILL.md — Task Format + Convergence Protocols

**File:** Modify: `skills/x-teamcode/SKILL.md`

- [ ] **Step 1: Update Phase A2 task format to include acceptance command**

In the A2 section (around line 127), the current task format has Role suggestion, Parallel group, Dependencies. Add Acceptance command and Anti-hollow checks fields. Replace the task header template block:

Find the current header block:
```markdown
> **Execution mode:** x-teamcode team execution
```

Replace the task MUST include list to:
```markdown
   - **Each Task MUST include**:
     - `**Role suggestion:**` which CCteam role should handle it
     - `**Parallel group:**` which tasks can run simultaneously
     - `**Dependencies:**` which tasks must complete first
     - `**Acceptance command:**` an executable command that proves the feature works (written by team-lead, not dev)
     - `**Anti-hollow checks:**` specific assertions that the implementation is not empty/mock
```

- [ ] **Step 2: Add heartbeat monitoring to Phase C**

After C2 (Parallel Execution) section, before C3, add:

```markdown
**Agent Heartbeat Monitoring** (team-lead runs continuously during C2):
- After dispatching each round of tasks, note the time
- Periodically read each active agent's `progress.md` (last 5 lines)
- If an agent has no updates for an extended period → `SendMessage` asking for status
- If no reply after follow-up → mark as HUNG → re-spawn agent with same task context from `.plans/` files
- Record heartbeat check results in `.plans/<project>/progress.md`
```

- [ ] **Step 3: Add integration smoke test triggers to Phase C4 and C5**

Update C4 (Phase Progression Gates) to include smoke tests:

```markdown
### C4: Phase Progression Gates

1. **Research phase done**: team-lead reads researcher findings → updates main plan architecture section
2. **Dev phase done**: all dev tasks passed two-stage review → team-lead confirms
3. **E2E testing done**: e2e-tester results reviewed → team-lead confirms pass rate
4. **Integration smoke test** (at every phase boundary):
   - Run smoke tests defined in `.plans/<project>/smoke-tests.md`
   - Each test step must produce non-empty, non-default output
   - Any step failing → PHASE BLOCKED → fix before advancing
```

- [ ] **Step 4: Add acceptance command to Key Rules section**

In the "Goal Convergence" rules section, add:

```markdown
- **Every task has an acceptance command**: written by team-lead, run by dev, verified by reviewer
- **Dev pastes raw stdout**: not "acceptance passed" but the actual terminal output
- **Hollow implementations blocked by CI**: GR-6 detects pass/empty bodies before review
- **Integration smoke tests at phase boundaries**: end-to-end pipeline must produce real output
- **Heartbeat monitoring**: team-lead detects hung agents and re-spawns
```

- [ ] **Step 5: Commit**

```bash
git add skills/x-teamcode/SKILL.md
git commit -m "feat: add acceptance commands, heartbeat monitoring, smoke tests to SKILL.md"
```

---

### Task 3: Update onboarding.md — Dev Acceptance Protocol + Reviewer Hallucination Detection

**File:** Modify: `skills/x-teamcode/references/onboarding.md`

- [ ] **Step 1: Add acceptance command protocol to dev section**

In the dev onboarding section (backend-dev / frontend-dev), after the "Verification Before Completion" section, add:

```markdown
### Acceptance Command Protocol (x-teamcode mandatory)

Every task you receive includes an **Acceptance command** defined by team-lead.

After completing your implementation:
1. Run the acceptance command exactly as written
2. **Paste the full raw stdout** in your completion report — not "it passed", the actual output
3. If the acceptance command fails:
   - Read the error, fix your implementation
   - Re-run until it passes
   - Only then proceed to request review

Example completion report:
```
Status: DONE
Acceptance command output:
$ python -c "from src.llm.client import LLMClient; r = LLMClient().generate('hello'); print(repr(r))"
'Hello! How can I assist you today? I am ready to help with any questions.'

Files changed: src/llm/client.py, tests/test_llm.py
```

**Anti-hollow self-check before reporting DONE:**
- [ ] No function body is `pass` or `...`
- [ ] No function returns hardcoded TODO/mock values
- [ ] Tests assert on actual output content, not just function existence
- [ ] Acceptance command produces real, non-empty output
```

- [ ] **Step 2: Add hallucination detection to reviewer section**

In the reviewer onboarding section, after the "Two-Stage Review Protocol" section, add:

```markdown
### Hallucination Detection (x-teamcode mandatory)

During BOTH review stages, you must check for hallucinations:

**Step 1: Report vs Diff**
- Read the dev's completion report (what they claim they did)
- Read `git diff` (what actually changed)
- For each claim: is there corresponding code in the diff?
  - "Implemented LLM integration" → Is there an actual API call in the diff?
  - "Added error handling" → Are there try/catch blocks in the diff?
  - "All tests pass" → Does CI output confirm this?

**Step 2: Report vs Acceptance**
- Re-run the acceptance command yourself
- Does the output match what the dev reported?
- Is the output real data (not mock/empty/TODO)?

**Step 3: Mark discrepancies**
If any claim doesn't match reality:
```
[HALLUCINATION] Dev claimed: "<claim>"
  Actual: <what the code/output actually shows>
  File: <path:line>
  Severity: CRITICAL — auto-escalate to team-lead
```

Hallucination findings are ALWAYS CRITICAL — they indicate the dev's self-report cannot be trusted for this task.
```

- [ ] **Step 3: Update the dev's review request format**

Update the SendMessage template in "Code Review Rules" to include acceptance command output:

```markdown
3. Request review:
   ```
   SendMessage(to: "reviewer", message:
     "Spec compliance review for task-<name>.
      Files changed: <list>
      Spec: docs/x-teamcode/specs/<file>.md
      Plan Task: docs/x-teamcode/plans/<file>.md, Task N
      Acceptance command output:
      $ <command>
      <raw stdout>
      My findings: .plans/<project>/<your-name>/task-<name>/findings.md")
   ```
```

- [ ] **Step 4: Commit**

```bash
git add skills/x-teamcode/references/onboarding.md
git commit -m "feat: add acceptance command protocol and hallucination detection to onboarding"
```

---

### Task 4: Update spec-reviewer-prompt.md — Add Hallucination Detection Step

**File:** Modify: `skills/x-teamcode/prompts/spec-reviewer-prompt.md`

- [ ] **Step 1: Add hallucination detection between Step 3 and Step 4**

After "Step 3: Check Against Spec" and before "Step 4: Report", insert:

```markdown
### Step 3.5: Hallucination Detection

Verify that the dev's completion report matches reality:

**Report vs Code:**
- For each claim in the dev's report, verify it exists in `git diff`
- Dev says "implemented X" → is X actually in the code?
- Dev says "added tests for Y" → do test files for Y exist in the diff?

**Report vs Acceptance Command:**
- Re-run the acceptance command from the task description
- Compare output to what the dev pasted in their report
- Check: is the output real data? (not empty, not "TODO", not mock)

**If discrepancy found:**
Add to your review report:
```
### Hallucination Detected
- Claim: "<what dev reported>"
- Reality: <what code/output actually shows>
- Severity: CRITICAL
- Action: task is NOT spec compliant regardless of other checks
```

A hallucination finding overrides all other results — verdict is automatically ❌.
```

- [ ] **Step 2: Update the report format to include hallucination section**

In the report format (Step 4), add after "Misunderstandings":

```markdown
### Hallucination Check
- [ ] Dev report matches git diff: YES/NO
- [ ] Acceptance command output matches report: YES/NO
- [ ] Output is real data (not empty/mock/TODO): YES/NO
```

- [ ] **Step 3: Commit**

```bash
git add skills/x-teamcode/prompts/spec-reviewer-prompt.md
git commit -m "feat: add hallucination detection to spec-reviewer-prompt"
```

---

### Task 5: Update roles.md — Reviewer Duties Enhancement

**File:** Modify: `skills/x-teamcode/references/roles.md`

- [ ] **Step 1: Add hallucination detection and acceptance command verification to reviewer role**

In the reviewer section (after the Two-Stage Review Protocol block, around line 223), add:

```markdown
- **Hallucination Detection** (x-teamcode mandatory — applies to BOTH review stages):
  - Compare dev's completion report against actual `git diff`
  - Re-run the task's acceptance command independently
  - If any claim doesn't match code/output → tag `[HALLUCINATION]`, severity CRITICAL, auto-escalate to team-lead
  - Hallucination finding = automatic review failure regardless of other results
- **Acceptance Command Verification**:
  - Every task has an acceptance command (written by team-lead)
  - Reviewer MUST re-run it during Stage 1 and verify output is real (not empty/mock/TODO)
  - If acceptance command fails → spec compliance fails, even if code looks correct
```

- [ ] **Step 2: Commit**

```bash
git add skills/x-teamcode/references/roles.md
git commit -m "feat: add hallucination detection and acceptance verification to reviewer role"
```

---

### Task 6: Update templates.md — Task Template + Smoke Tests Template

**File:** Modify: `skills/x-teamcode/references/templates.md`

- [ ] **Step 1: Update the dev task folder template to include acceptance command**

In the "Dev Task Folder" section's `task_plan.md` template (around line 450), update:

```markdown
#### task_plan.md

```markdown
# <Feature Name> - Task Plan

> Agent: <agent-name>
> Status: in_progress
> Created: <date>

## Goal

<What this feature needs to accomplish>

## Acceptance Command

```bash
<executable command that proves this feature works — written by team-lead>
```
Expected output: <description of what correct output looks like>

## Anti-Hollow Checks

- [ ] No `pass` in function bodies
- [ ] No hardcoded return values
- [ ] Tests assert on actual output content
- [ ] Acceptance command produces real output

## Detailed Steps

- [ ] 1. <step description>
- [ ] 2. <step description>
- [ ] 3. Run acceptance command — paste raw stdout
- [ ] 4. Request reviewer review

## Files Involved

- `path/to/file1.ts` — <description>

## Dependencies

- <dependencies>
```
```

- [ ] **Step 2: Add smoke-tests.md template**

After the "phase-state.md" template section, add a new section:

```markdown
## Smoke Tests (smoke-tests.md)

Generated during Phase B by team-lead. Defines end-to-end verification commands for each checkpoint.

```markdown
# <Project Name> - Integration Smoke Tests

> Generated during Phase B.
> Team-lead defines these tests; devs do not modify.
> Run at integration checkpoints (every 3-5 tasks) and phase boundaries.

## Checkpoint 1: After Tasks 1-N

```bash
# Test: <what this verifies>
<executable command>
# Expected: <what correct output looks like, e.g., "non-empty string", "> 0", "status 200">
```

## Phase M Complete: <phase name>

```bash
# End-to-end pipeline test
# Step 1: <description>
<command>
# Expected: <expected output>

# Step 2: <description>
<command>
# Expected: <expected output>

# Step N: <description>
<command>
# Expected: <expected output>
```

## Results Log

| Checkpoint | Date | Result | Notes |
|---|---|---|---|
| Checkpoint 1 | <date> | PASS/FAIL | <details> |
```
```

- [ ] **Step 3: Commit**

```bash
git add skills/x-teamcode/references/templates.md
git commit -m "feat: add acceptance command to task template and smoke-tests.md template"
```

---

### Task 7: Update plan-bridge.md — Generate Acceptance Commands + Smoke Tests

**File:** Modify: `skills/x-teamcode/references/plan-bridge.md`

- [ ] **Step 1: Add acceptance command generation to task mapping rules**

In the "Task-to-Role Mapping Rules" section, add after the mapping table:

```markdown
### Acceptance Command Generation

When converting plan tasks to team tasks, team-lead MUST write an acceptance command for each task:

**Rules:**
1. The command must be executable without manual setup (assuming the project is running)
2. The command must verify the feature produces **real output** (not just that code exists)
3. The command must fail if the implementation is hollow (empty/mock/TODO)

**Patterns by task type:**

| Task Type | Acceptance Command Pattern |
|---|---|
| API endpoint | `curl -s <endpoint> \| jq '<field>'` — expected: non-empty, non-null |
| Data processing | `python -c "from mod import Func; r = Func().run(input); assert len(r) > 0"` |
| UI component | E2E test command or screenshot verification |
| Integration | Pipeline command: step1 \| step2 \| step3, each step non-empty |
| Library/utility | `python -c "from lib import func; print(func(test_input))"` — expected: correct output |

**If team-lead cannot write an acceptance command**, the task is too vague and must be decomposed further.
```

- [ ] **Step 2: Add smoke test generation to bridge process**

In the "B3: Generate .plans/ Infrastructure" equivalent section, add:

```markdown
### Smoke Test Generation

During bridge Phase B, team-lead generates `.plans/<project>/smoke-tests.md`:

1. Read the plan's parallel groups to determine natural checkpoints
2. For each checkpoint (every 3-5 tasks), write a smoke test that:
   - Exercises the features completed so far
   - Verifies end-to-end data flow (not just individual functions)
   - Has explicit "Expected" annotations
3. For each phase boundary, write a full pipeline smoke test
4. Use the smoke-tests.md template from references/templates.md
```

- [ ] **Step 3: Commit**

```bash
git add skills/x-teamcode/references/plan-bridge.md
git commit -m "feat: add acceptance command generation and smoke test generation to bridge"
```

---

## Self-Review

**Spec coverage check:**
- [x] GR-6 hollow scanner → Task 1
- [x] Acceptance command in task format → Task 2 (SKILL.md) + Task 6 (templates)
- [x] Heartbeat monitoring → Task 2 (SKILL.md)
- [x] Hallucination detection → Task 3 (onboarding) + Task 4 (spec-reviewer) + Task 5 (roles)
- [x] Integration smoke tests → Task 2 (SKILL.md) + Task 6 (templates) + Task 7 (bridge)
- [x] Dev acceptance command protocol → Task 3 (onboarding)
- [x] Reviewer re-runs acceptance command → Task 5 (roles)

**Placeholder scan:** No TBD/TODO found.

**Type consistency:** All references to "acceptance command", "smoke-tests.md", "[HALLUCINATION]" tag, and "GR-HOLLOW" are consistent across tasks.
