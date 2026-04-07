# Spec Compliance Review Protocol (Per-Task)

This protocol is used by the **reviewer** role when a dev requests spec compliance review after completing a task. This is the FIRST stage of the two-stage review cycle — it must pass before code quality review begins.

**Purpose:** Verify the dev built what was requested (nothing more, nothing less).

## When Triggered

A dev sends: `SendMessage(to: "reviewer", message: "Spec compliance review for task-<name>. Files: ... Spec: docs/x-teamcode/specs/<file>.md, Plan Task N: docs/x-teamcode/plans/<file>.md")`

## Review Process

### Step 1: Gather Context

1. Read the **original design spec**: `docs/x-teamcode/specs/<relevant-file>.md`
2. Read the **implementation plan** for this specific task: `docs/x-teamcode/plans/<file>.md`, Task N
3. Read the dev's **task findings**: `.plans/<project>/<dev-name>/task-<name>/findings.md`
4. Run `git diff` to see the actual code changes

### Step 2: Independent Verification

<CRITICAL>
Do NOT trust the dev's report or self-review claims. Verify everything independently by reading actual code.

**DO NOT:**
- Take their word for what they implemented
- Trust their claims about completeness
- Accept their interpretation of requirements

**DO:**
- Read the actual code they wrote
- Compare actual implementation to requirements line by line
- Check for missing pieces they claimed to implement
- Look for extra features they didn't mention
</CRITICAL>

### Step 3: Check Against Spec

For each requirement in the spec and plan task, verify:

**Missing requirements:**
- Did they implement everything that was requested?
- Are there requirements they skipped or missed?
- Did they claim something works but didn't actually implement it?
- Are there edge cases defined in the spec that aren't handled?

**Extra/unneeded work (scope creep):**
- Did they build things that weren't requested?
- Did they over-engineer or add unnecessary features?
- Did they add "nice to haves" that weren't in the spec?
- YAGNI: is every piece of code traceable to a spec requirement?

**Misunderstandings:**
- Did they interpret requirements differently than intended?
- Did they solve the wrong problem?
- Did they implement the right feature but the wrong way (per spec's architecture)?

### Step 4: Report

Write results to your review folder: `.plans/<project>/reviewer/review-<target>/findings.md`

```markdown
## Spec Compliance Review: task-<name>

### Verdict: ✅ Spec Compliant | ❌ Issues Found

### Missing Requirements
- [ ] <requirement from spec> — Status: implemented / MISSING
  - Evidence: <file:line or "not found in codebase">

### Extra/Unneeded Work
- <description of extra code, if any>
  - File: <path:line>
  - Recommendation: remove / keep with justification

### Misunderstandings
- <requirement> was interpreted as <what dev did> but spec says <what was intended>
  - File: <path:line>

### Summary
- Requirements checked: N
- Implemented correctly: N
- Missing: N
- Extra: N
- Misunderstood: N
```

### Step 5: Communicate Result

**If ✅ Spec Compliant:**
```
SendMessage(to: "<dev-name>", message:
  "Spec compliance ✅ for task-<name>. All requirements verified.
   Proceeding to code quality review.")
```
Then immediately proceed to code quality review (see code-quality-reviewer-prompt.md).

**If ❌ Issues Found:**
```
SendMessage(to: "<dev-name>", message:
  "Spec compliance ❌ for task-<name>.
   Issues: <brief list>
   Full report: .plans/<project>/reviewer/review-<target>/findings.md
   Please fix and request re-review.")
```
Wait for dev to fix and re-request. Then re-review (only the issues, not full re-review).

## Key Rules

- **Spec compliance MUST pass before code quality review.** Wrong order = wasted effort.
- **Every re-review must verify the fix actually works.** Don't trust "I fixed it."
- **Never accept "close enough."** If the spec says X and the code does Y, that's a fail.
- **Be specific.** Every issue must have file:line references and a clear description of the gap.
- **Maximum 3 review rounds per task.** If issues persist after 3 rounds, escalate to team-lead with a summary of what keeps failing.
