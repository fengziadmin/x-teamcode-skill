# Code Quality Review Protocol (Per-Task)

This protocol is used by the **reviewer** role as the SECOND stage of the two-stage review cycle. It runs only AFTER spec compliance review passes.

**Purpose:** Verify the implementation is well-built (clean, tested, maintainable).

## When Triggered

Automatically after spec compliance passes. The reviewer proceeds from spec compliance to code quality in the same review session.

## Review Process

### Step 1: Context (already loaded from spec compliance review)

You already have:
- The spec and plan task from the spec compliance review
- The git diff of changes
- Understanding of what was implemented

### Step 2: Security Checks (CRITICAL level)

- Hardcoded secrets (API keys, passwords, tokens)
- SQL injection (string-concatenated queries)
- XSS (unescaped user input)
- Path traversal (user-controlled file paths)
- CSRF, authentication bypass
- Missing input validation
- Insecure dependencies

### Step 3: Quality Checks (HIGH level)

- Large functions (>50 lines), large files (>800 lines)
- Deep nesting (>4 levels)
- Missing error handling
- Leftover console.log statements
- Mutation patterns (prefer immutable)
- New code missing tests
- File responsibility: does each file have one clear purpose?
- Interface design: can units be understood and tested independently?

### Step 4: Performance Checks (MEDIUM level)

- Inefficient algorithms (O(n^2) where O(n) is possible)
- Unnecessary re-renders (React), missing memoization
- Missing caching for expensive operations
- N+1 queries
- Oversized bundles

### Step 5: Architecture Health (MEDIUM level)

- Shallow modules (interface complexity ≈ implementation complexity)
- Does the implementation follow the file structure from the plan?
- Did this change create files that are already large?
- Dependency classification appropriate?

### Step 6: Doc-Code Consistency (HIGH level)

- API changed → `docs/api-contracts.md` updated?
- Architecture changed → `docs/architecture.md` updated?
- Change violates `docs/invariants.md`? → CRITICAL
- Observability: new endpoints emit structured events?

### Step 7: Review Dimensions (Project-Specific)

Score each project Review Dimension (from CLAUDE.md):

| Dimension | Weight | Score | Justification |
|-----------|--------|-------|---------------|
| <dimension> | high/medium/low | STRONG/ADEQUATE/WEAK | <one line> |

If any dimension scores WEAK → verdict cannot be [OK].

### Step 8: Report

Append to the same review folder: `.plans/<project>/reviewer/review-<target>/findings.md`

```markdown
## Code Quality Review: task-<name>

### Verdict: [OK] | [WARN] | [BLOCK]

### Dimension Scores
| Dimension | Weight | Score | Justification |
|-----------|--------|-------|---------------|
| ... | ... | ... | ... |

### Issues

#### [CRITICAL] <title>
- File: <path:line>
- Issue: <description>
- Fix: <recommendation with code example>

#### [HIGH] <title>
- File: <path:line>
- Issue: <description>
- Fix: <recommendation>

#### [MEDIUM] <title>
...

### Summary
- CRITICAL: 0
- HIGH: 0
- MEDIUM: 0
- LOW: 0
```

### Step 9: Communicate Result

**Approval criteria:**
- **[OK]**: No CRITICAL or HIGH issues, no WEAK dimension scores
- **[WARN]**: MEDIUM issues only, all dimensions ADEQUATE+
- **[BLOCK]**: Has CRITICAL or HIGH, or any dimension WEAK

**If [OK] or [WARN]:**
```
SendMessage(to: "<dev-name>", message:
  "Code quality review complete for task-<name>. Verdict: [OK/WARN].
   Full report: .plans/<project>/reviewer/review-<target>/findings.md
   Task is approved. [If WARN: Please address MEDIUM items when convenient.]")

SendMessage(to: "team-lead", message:
  "Review complete: task-<name> by <dev-name>.
   Spec compliance: ✅ | Code quality: [OK/WARN]
   Report: .plans/<project>/reviewer/review-<target>/findings.md")
```

**If [BLOCK]:**
```
SendMessage(to: "<dev-name>", message:
  "Code quality review ❌ for task-<name>. Verdict: [BLOCK].
   Issues: <brief list of CRITICAL/HIGH items>
   Full report: .plans/<project>/reviewer/review-<target>/findings.md
   Please fix CRITICAL and HIGH issues, then request re-review.")
```
Wait for dev to fix. Re-review only the flagged issues.

## Key Rules

- **Only run after spec compliance ✅.** Never start code quality review if spec compliance failed.
- **Re-review must verify fixes.** Don't trust "I fixed it."
- **Maximum 3 review rounds per task.** Escalate to team-lead if issues persist.
- **Anti-leniency rule**: When you identify an issue, do NOT rationalize it away. Score at face value.
- **Be specific.** Every issue must have file:line references and a concrete fix recommendation.
