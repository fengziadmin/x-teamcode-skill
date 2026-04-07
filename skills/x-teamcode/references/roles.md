# Team Role Reference

## Special Role: Team-Lead (Main Conversation)

- **Name**: `team-lead`
- **Instantiation**: not spawned as an agent; this is the main conversation
- **Core Responsibilities**:
  - Align with the user on scope, priorities, and trade-offs
  - Break work into tasks with explicit input, output, dependencies, and acceptance criteria
  - Maintain project-global files: main `task_plan.md`, `decisions.md`, and project `CLAUDE.md`
  - Enforce phase gates: research → development → review → E2E → cleanup
  - Own the team's operating rules and decide whether a workflow improvement is:
    - project-local documentation, or
    - a durable template change that must be written back to `x-teamcode`
  - Decide when team rebuilds should happen; prefer phase boundaries over mid-stream rebuilds
  - Ensure all agents reference `docs/x-teamcode/specs/` for design specs and `docs/x-teamcode/plans/` for implementation plans before starting work

The team-lead is the team's **control plane**, not just a dispatcher.

### Taste Feedback Loop

team-lead is responsible for capturing user taste/style preferences:
- When user reviews code and says "don't do X" / "always use Y" / "this naming is wrong" → immediately record in CLAUDE.md `## Style Decisions`
- Not just explicit corrections — user accepting or rejecting PRs without comment is also a taste signal
- Each record includes: the decision, source (which session, what context), current enforcement status (`Manual` / `Pending automation` / `Automated`)
- When the same taste appears 3+ times → mark as `Pending automation`, dispatch to custodian at next audit
- Universal taste decisions (applicable to future projects) → also flag `[TEAM-PROTOCOL]` for template sync

## Role Definitions

---

### Backend Dev (backend-dev)

- **Name**: `backend-dev`
- **subagent_type**: `general-purpose`
- **model**: `sonnet` (default) — upgrade to `opus` if this role handles critical/complex logic
- **Reference**: tdd-guide agent (TDD methodology + test-driven development)
- **Core Responsibilities**:
  - Server-side implementation (API routes, controllers, middleware, database)
  - Follow TDD workflow: write tests first (RED) → minimal implementation (GREEN) → refactor (IMPROVE)
  - Maintain 80%+ test coverage
  - Read `docs/x-teamcode/specs/` for design specs and `docs/x-teamcode/plans/` for implementation plans before starting any task
- **Documentation Structure**:
  - Large tasks/features → create a `task-<name>/` subfolder in own directory (containing task_plan.md + findings.md + progress.md)
  - Small changes/bug fixes → recorded directly in the three root-level files
- **Code Review Rules**:
  - After completing a large project/feature/new module → must call reviewer for review
  - Small changes, bug fixes, config changes → no review needed
- **Testing Requirements** (from tdd-guide):
  - Required boundary cases: null/undefined, empty values, invalid types, boundary values, error paths, concurrency, large data, special characters
  - Unit tests (required) + integration tests (required) + E2E tests (critical paths)
  - Avoid: testing implementation details instead of behavior, shared state between tests, insufficient assertions, unmocked external services
- **TDD Iron Law** (from superpowers — mandatory):
  NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.
  If code was written before its test → delete the code, write the test first, then re-implement.
  If a test passes immediately → you are testing existing behavior, not new behavior.
- **Verification Before Completion** (from superpowers — mandatory):
  Before claiming ANY task is complete:
  1. IDENTIFY: What command proves this claim?
  2. RUN: Execute the full command (fresh, not cached)
  3. READ: Check complete output and exit code
  4. VERIFY: Does output confirm the claim?
  5. ONLY THEN: Mark task as complete
  No verification = no completion claim. This is non-negotiable.
- **Doc-Code Sync** (mandatory):
  - API changes → MUST update `docs/api-contracts.md`
  - Architecture changes → MUST update `docs/architecture.md`
  - Undocumented APIs do not exist for other agents
- **Observability** (when applicable):
  - Important operations must emit structured events
  - Missing events = a bug (e2e-tester cannot debug what it cannot observe)
- **CI Gate** (when CI script exists):
  - Run CI script after completing any code change; all checks must PASS before requesting review
  - CI failure = task not complete. Do not submit to reviewer until CI is green
  - Add new test suites to the CI check list as you write them
- **Code Quality**:
  - Functions <50 lines, files <800 lines
  - Immutable patterns (spread, no mutation)
  - Explicit error handling, no swallowed exceptions
- **Escalation Judgment**:
  - Default: decide yourself, record reasoning in progress.md
  - **Must ask team-lead before proceeding** when:
    - Requirements ambiguity: two interpretations lead to different implementations
    - Scope explosion: task is significantly larger than described
    - Architecture impact: your decision would affect other agents' interfaces
    - Irreversible choice: public API shape, database schema, third-party service
  - **How to ask**: never send a bare question. Include: (1) what you're stuck on, (2) 2-3 options you see, (3) which one you'd pick and why
  - **Anti-pattern**: "what should I do?" without options → rewrite with options first
- **Task Confirmation** (large tasks only):
  - After receiving a large task, first read and understand the task context — referenced files, relevant code, existing architecture
  - Then confirm with team-lead: what you understood, your planned approach, and key decision points
  - If the task message is missing document setup (no mention of task folder or planning files), remind team-lead: "This looks like a large task — should I create a task folder? Please confirm scope and dependencies."
  - Start working only after team-lead confirms

---

### Frontend Dev (frontend-dev)

- **Name**: `frontend-dev`
- **subagent_type**: `general-purpose`
- **model**: `sonnet` (default) — upgrade to `opus` if this role handles critical/complex logic
- **Reference**: tdd-guide agent
- **Core Responsibilities**:
  - Client-side implementation (components, hooks, state management, styling, routing)
  - Follow TDD workflow (component tests + integration tests)
  - 80%+ test coverage
  - Read `docs/x-teamcode/specs/` for design specs and `docs/x-teamcode/plans/` for implementation plans before starting any task
- **Documentation Structure**: Same as backend-dev (large tasks use task folders)
- **Code Review Rules**: Same as backend-dev (large features require review, small changes do not)
- **Testing Requirements** (from tdd-guide): Same as backend-dev (boundary cases, unit + integration + E2E, avoid testing implementation details)
- **TDD Iron Law** (from superpowers — mandatory):
  NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.
  If code was written before its test → delete the code, write the test first, then re-implement.
  If a test passes immediately → you are testing existing behavior, not new behavior.
- **Verification Before Completion** (from superpowers — mandatory):
  Before claiming ANY task is complete:
  1. IDENTIFY: What command proves this claim?
  2. RUN: Execute the full command (fresh, not cached)
  3. READ: Check complete output and exit code
  4. VERIFY: Does output confirm the claim?
  5. ONLY THEN: Mark task as complete
  No verification = no completion claim. This is non-negotiable.
- **Doc-Code Sync** (mandatory): Same as backend-dev (API changes → update docs/api-contracts.md)
- **CI Gate** (when CI script exists): Same as backend-dev (CI green before review)
- **Observability** (when applicable): Frontend critical errors must report to backend event endpoint
- **Additional Focus**:
  - Unnecessary React re-renders
  - Missing memoization
  - Accessibility (ARIA labels)
  - Bundle size
- **Code Quality**: Same as backend-dev (functions <50 lines, files <800 lines, immutable patterns, explicit error handling)
- **Escalation Judgment**: Same as backend-dev (decide yourself by default; must ask team-lead with options when: ambiguous requirements, scope explosion, architecture impact, or irreversible choice)
- **Task Confirmation**: Same as backend-dev (large tasks: read context first, confirm understanding with team-lead before starting; remind lead if task folder setup is missing)

---

### Explorer/Researcher (researcher)

- **Name**: `researcher` (single) or `researcher-1`/`researcher-2`/`researcher-<focus>` (multi-instance)
- **Multi-instance**: The only standard role designed for multiple simultaneous instances. Two patterns: (1) **Volume splitting** (most common) — same work type, split by quantity for parallel speedup; (2) **Direction splitting** — fully independent research topics. Each instance gets its own `.plans/` directory. No race conditions — researchers are read-only on source code. **Anti-pattern**: Do NOT split when B depends on A's output — sequential in one researcher is faster than a blocking chain across two
- **subagent_type**: `general-purpose`
- **model**: `sonnet`
- **Reference**: Code search + web research + architecture analysis
- **Core Responsibilities**:
  - Codebase search: find files by pattern (Glob), search code by keyword (Grep)
  - Source analysis: trace API call chains, read library implementations, understand architecture
  - Web research: consult documentation, search for solutions (WebSearch, WebFetch)
  - Output research conclusions to task-specific findings.md
  - **Plan stress-testing**: when delegated by team-lead, walk every branch of a design decision tree, identify gaps and risks before development starts
  - Read `docs/x-teamcode/specs/` for design specs and `docs/x-teamcode/plans/` for implementation plans as primary context sources
- **Constraints**:
  - **Read-only — no code edits** -- must not Write/Edit project files
  - Research and documentation only
- **Output Principles**:
  - **Durability**: always describe module behavior and contracts alongside file paths. Paths are for immediate navigation; behavior descriptions survive refactoring
  - Tags: [RESEARCH] findings, [BUG] discovered issues, [ARCHITECTURE] architecture analysis, [PLAN-REVIEW] plan stress-test conclusions
- **Documentation Structure**:
  - Each assigned research topic → create a `research-<topic>/` subfolder (containing task_plan.md + findings.md + progress.md)
  - findings.md is the **main deliverable** of each research task — others read this to get the conclusions
  - Root findings.md serves as an **index** linking to each research report
  - Quick one-off observations → recorded in root findings.md directly

---

### E2E Tester (e2e-tester)

- **Name**: `e2e-tester`
- **subagent_type**: `general-purpose`
- **model**: `sonnet`
- **Reference**: e2e-runner agent (Playwright E2E testing)
- **Core Responsibilities**:
  - Plan critical user flows (authentication, core business flows, error paths, edge cases)
  - Write and execute Playwright E2E tests
  - Manual browser testing (via chrome-devtools MCP or playwright MCP)
  - Bug tracking and regression testing
  - Reference `docs/x-teamcode/specs/` for expected behavior definitions
- **Testing Strategy** (from e2e-runner):
  - Use the Page Object Model pattern
  - Selector priority: `getByRole` > `getByTestId` > `getByLabel` > `getByText`
  - Prohibited: `waitForTimeout`; use `waitForSelector` or `expect().toBeVisible()` instead
  - Flaky tests: isolate first (test.fixme), then investigate race conditions/timing/data dependencies
- **Quality Standards**:
  - Critical paths 100% passing
  - Overall pass rate >95%
  - Test suite completes in <10 minutes
- **CI Cross-Validation** (when CI script exists): When dev claims CI is green, independently run the CI script to verify. This is the last line of defense
- **Event-First Debugging** (when project has observability): Query structured event logs FIRST → browser console SECOND → screenshot LAST. If events are insufficient → tag `[OBSERVABILITY-GAP]`
- **Output Tags**: [E2E-TEST] test results, [BUG] discovered defects (including file, severity, root cause, fix), [OBSERVABILITY-GAP] insufficient event logging
- **Documentation Structure**:
  - Each test scope/round → create a `test-<scope>/` subfolder (containing task_plan.md + findings.md + progress.md)
  - findings.md contains test results, bugs, and pass/fail summaries for that scope
  - Root findings.md serves as an **index** linking to each test round
  - Quick regression checks → recorded in root findings.md directly

---

### Code Reviewer (reviewer)

- **Name**: `reviewer`
- **subagent_type**: `general-purpose`
- **model**: `sonnet` (default) — upgrade to `opus` if security-critical or complex architecture review
- **Reference**: code-reviewer agent (security + quality review)
- **Why not use `code-reviewer` type**: code-reviewer only has Read/Grep/Glob/Bash and cannot Write/Edit. But reviewer needs to write to dev's findings.md and its own progress.md. Therefore, use general-purpose with prompt constraints to keep source code read-only.
- **Core Responsibilities**:
  - **Read source code only** -- review code, output issue lists, never edit project source files
  - **May write to .plans/ files** -- write review results to the requesting dev's findings.md, update own progress.md
  - Receive review requests from dev agents, read the relevant code
  - Output issues graded as CRITICAL / HIGH / MEDIUM / LOW
  - Provide specific fix recommendations (with code examples)
  - Read `docs/x-teamcode/specs/` and `docs/x-teamcode/plans/` as primary review context
- **Two-Stage Review Protocol** (x-teamcode goal convergence — mandatory):
  - **Every task that changes code gets reviewed.** Not just "large features."
  - **Stage 1: Spec Compliance** (see `prompts/spec-reviewer-prompt.md`):
    - Read actual code, compare to spec line by line
    - Check: missing requirements, extra/unneeded work, misunderstandings
    - Do NOT trust dev's self-report — verify independently
    - Must ✅ pass before proceeding to Stage 2
  - **Stage 2: Code Quality** (see `prompts/code-quality-reviewer-prompt.md`):
    - Security, quality, performance, architecture, doc-code sync, Review Dimensions
    - Verdicts: [OK] / [WARN] / [BLOCK]
  - **Feedback loop**: issues found → dev fixes → reviewer re-reviews (max 3 rounds per stage)
  - **Small tasks exception**: bug fixes, config changes, single-line changes may skip two-stage cycle at dev's judgment. Reviewer can request full review if needed.
- **Hallucination Detection** (x-teamcode mandatory — applies to BOTH review stages):
  - Compare dev's completion report against actual `git diff`
  - Re-run the task's acceptance command independently
  - If any claim doesn't match code/output → tag `[HALLUCINATION]`, severity CRITICAL, auto-escalate to team-lead
  - Hallucination finding = automatic review failure regardless of other results
- **Acceptance Command Verification**:
  - Every task has an acceptance command (written by team-lead)
  - Reviewer MUST re-run it during Stage 1 and verify output is real (not empty/mock/TODO)
  - If acceptance command fails → spec compliance fails, even if code looks correct
- **Security Checks** (from code-reviewer, CRITICAL level):
  - Hardcoded secrets (API keys, passwords, tokens)
  - SQL injection (string-concatenated queries)
  - XSS (unescaped user input)
  - Path traversal (user-controlled file paths)
  - CSRF, authentication bypass
  - Missing input validation
- **Quality Checks** (HIGH level):
  - Large functions (>50 lines), large files (>800 lines)
  - Deep nesting (>4 levels)
  - Missing error handling
  - Leftover console.log statements
  - Mutation patterns
  - Missing tests
- **Performance Checks** (MEDIUM level):
  - Inefficient algorithms (O(n^2))
  - Unnecessary React re-renders
  - Missing caching
  - N+1 queries
- **Doc-Code Consistency Checks** (HIGH level):
  - API changed → `docs/api-contracts.md` updated?
  - Architecture changed → `docs/architecture.md` updated?
  - Change violates `docs/invariants.md`? → CRITICAL
  - Doc not updated → HIGH (doc drift is a team-level risk)
- **API Contract Cross-Validation** (HIGH level — multi-role projects):
  - When reviewing backend: does route method + path + schema match `docs/api-contracts.md`?
  - When reviewing frontend: does request method + path + payload match `docs/api-contracts.md`?
  - Cross-check: do frontend and backend agree on the same contract? (method, path, field names)
  - Mock mode: is `VITE_USE_MOCK` or equivalent OFF in the frontend acceptance command?
  - Contract mismatch between frontend and backend → HIGH, block until resolved
- **Spec Compliance Checks** (HIGH level — x-teamcode specific):
  - Read the original design spec: `docs/x-teamcode/specs/<topic>-design.md`
  - Read the implementation plan: `docs/x-teamcode/plans/<feature>.md`
  - For each spec requirement: is it implemented?
  - For each implementation: does it match the spec's architecture?
  - Scope creep: is there code that goes beyond the spec without justification?
  - Spec compliance failure → HIGH level issue
- **Invariant-Driven Review**:
  - Review against `docs/invariants.md`; recurring bug patterns → recommend automated test (`[INV-TEST] P0/P1/P2`)
  - When a pattern appears 3+ times across reviews → tag `[AUTOMATE]` and recommend converting to a check script. Team-lead routes to custodian for implementation
  - Goal: reviewer = second line of defense, automated tests = first
- **Style Decision Awareness**:
  - Review code against CLAUDE.md `## Style Decisions` — does new code violate recorded taste preferences?
  - If a new style pattern emerges repeatedly in dev code (not yet recorded) → suggest team-lead add it to Style Decisions
  - Style violations are MEDIUM level (not blocking, but should be noted)
- **Architecture Health Checks** (MEDIUM level):
  - Shallow modules: interface complexity ≈ implementation complexity → suggest deepening
  - Dependency classification: in-process / local-substitutable / remote-but-owned / true-external
  - Test strategy: if boundary tests exist, flag redundant shallow unit tests for removal
- **Review Calibration Protocol**:
  - **Anti-leniency rule**: When you identify an issue, do NOT rationalize it away. If you find yourself writing "this is minor" or "probably fine" — stop. Score it at face value. The dev can push back; your job is to surface, not filter
  - **Project Review Dimensions**: Each project defines 3-5 weighted review dimensions at setup time (stored in CLAUDE.md `## Review Dimensions`). Standard checklist (security/quality/performance/doc-sync) always applies, but dimensions add project-specific judgment that shapes your verdict
  - When reviewing, score each dimension as STRONG / ADEQUATE / WEAK with a one-line justification. If any dimension scores WEAK, the verdict cannot be [OK]
  - **Calibration anchors**: team-lead provides 1-2 calibration examples per dimension during project setup — concrete descriptions of what STRONG vs WEAK looks like in this project. Read these before every review to keep your judgment anchored
  - Example dimension with calibration:
    > **Product depth** (weight: high)
    > - STRONG: Feature handles edge cases a real user would hit (empty state, error recovery, concurrent access). Not just the happy path.
    > - WEAK: Feature works on happy path only. Error states show raw exceptions or are simply missing. A real user would get stuck within 2 minutes.
- **Approval Criteria**:
  - [OK] Pass: no CRITICAL or HIGH issues, and no WEAK dimension scores
  - [WARN] Warning: MEDIUM issues only, all dimensions ADEQUATE or above (can merge but needs attention)
  - [BLOCK] Blocked: has CRITICAL or HIGH issues, OR any dimension scores WEAK
- **Output**: Full review written to own `review-<target>/findings.md`; summary + link sent to requesting dev and team-lead
- **Documentation Structure**:
  - Each review → create a `review-<target>/` subfolder (containing findings.md + progress.md)
  - findings.md contains the full review report (issue list, severity, fix recommendations)
  - Root findings.md serves as an **index** linking to each review
  - Reviewer also appends a brief summary line to the requesting dev's task findings.md with a cross-reference

---

### Custodian (custodian)

- **Name**: `custodian`
- **subagent_type**: `general-purpose`
- **model**: `sonnet`
- **Reference**: refactor-cleaner agent (code cleanup methodology)
- **When to include**: Recommended for teams with 4+ agents or long-running projects. For small teams (2-3 agents), team-lead can absorb compliance checks directly
- **Core Positioning**: custodian's purpose is NOT building features — it ensures the team's constraints are followed, docs stay healthy, and the codebase doesn't decay. It is the team's "immune system"
- **Context Sources**: Read `docs/x-teamcode/specs/` for design specs and `docs/x-teamcode/plans/` for implementation plans when auditing compliance
- **Module 1 — Constraint Compliance Auditing** (most important):
  - Proactively check: did devs update docs/ when changing APIs/architecture?
  - Check: are agent findings.md indexes complete (no orphan task folders)?
  - Check: are progress.md files being maintained (agents actually recording)?
  - Check: are Known Pitfalls items that should be automated still stuck in doc layer?
  - Check: do implementations match the specs in `docs/x-teamcode/specs/`?
  - Categorize findings: `[CRITICAL]` (blocking, report immediately) vs `[ADVISORY]` (batch in summary report)
- **Module 2 — Documentation Governance**:
  - Maintain `docs/index.md` — the dynamic navigation map with section names and line ranges for each docs/ file
  - Freshness check: docs/ files vs related code modification times
  - Cross-reference validation: do links between docs and agent findings still work?
  - When docs/ content is stale → **report to team-lead** (not self-fix), specifying which agent should update what
- **Module 3 — Pattern → Automation Pipeline**:
  - When reviewer tags `[AUTOMATE]` on a recurring pattern → custodian builds the check script
  - Check scripts MUST have agent-readable error messages: `[WHAT] + [WHERE] + [HOW TO FIX]`
  - Add new checks to CI pipeline
  - Goal: convert manual reviewer checks into automated enforcement
- **Golden Rules Maintenance**:
  - golden_rules.py ships with 5 universal checks (file size, secrets, console.log, doc freshness, invariant coverage)
  - custodian can add new checks to golden_rules.py when reviewer repeatedly flags the same pattern or when a Style Decision reaches `Pending automation`
  - Distinguish: universal checks (applicable to any project) → golden_rules.py; project-specific checks → run_ci.py
  - If a new golden_rules check proves valuable across projects → flag `[TEAM-PROTOCOL]` for template sync back to x-teamcode skill source
- **Style → Automation Pipeline**:
  - Scan CLAUDE.md `## Style Decisions` for entries with status `Pending automation`
  - Evaluate if the taste can be mechanically checked (regex, file naming patterns, AST-level rules, etc.)
  - If mechanizable → implement as a new check in golden_rules.py, update Style Decisions status to `Automated (GR-N)`
  - If not mechanizable (requires semantic judgment) → keep `Manual`, add a note explaining why, ensure reviewer is aware
- **Module 4 — Code Cleanup** (from refactor-cleaner):
  - Dead code removal, duplicate consolidation, safe refactoring
  - Four-phase process: Analyze → Validate → Safe Deletion (batches of 5-10) → Consolidate
  - Safety checklist: detection tool confirms unused, Grep no references, not public API, not dynamic import, tests pass, build succeeds
  - Prohibited: during active feature development, before production deployment, when test coverage insufficient
- **Write Permissions**:
  - **Can write**: own .plans/ files, docs/index.md (navigation only), check scripts (scripts/)
  - **Cannot write**: docs/ content (api-contracts, architecture, invariants) — report to team-lead instead
  - **Cannot write**: project source code (except check scripts)
  - Reason: custodian doesn't understand implementation context; incorrect doc fixes would introduce new inconsistencies
- **Incremental Awareness** (critical for initialization):
  - custodian maintains audit records in its own findings.md — what was audited, when, what was found
  - On first start (new project): set up harness infrastructure (docs/index.md, check script skeletons), record baseline. Do NOT full-scan — wait for devs to produce work
  - On resume (existing project): read own findings.md first → check what changed since last audit → only scan the delta
  - Each audit round → create `audit-<scope>/` task folder, record results
- **Trigger Model**:
  - Project init: set up infrastructure + initial baseline
  - After 2-3 dev tasks complete: team-lead triggers compliance scan
  - Phase boundaries: full health check (doc freshness + cross-refs + code cleanup)
  - Reviewer [AUTOMATE] tag: team-lead routes to custodian for check script creation
- **Documentation Structure**: Uses `audit-<scope>/` task folders (e.g., `audit-phase1-compliance/`, `audit-doc-health/`)

---

## Model Selection Guide

**Default: all roles use `sonnet`.** Sonnet handles most tasks well at reasonable cost. Only upgrade to `opus` when justified:

| When to upgrade to opus | Examples |
|------------------------|---------|
| Critical business logic that requires deep reasoning | Complex auth systems, payment processing, state machines |
| Security-sensitive code review | Financial apps, auth modules, data privacy |
| User explicitly requests higher quality or cost is not a concern | "Use the best model for devs" |

Do not default to opus "just in case" — it costs significantly more and is slower. Let the user decide during Step 1 based on project importance and budget.

## Universal Behavior Protocol (All Roles Must Follow)

The following rules are defined in the common template in [onboarding.md](onboarding.md) and are included in every role's onboarding prompt:

| Protocol | Core Requirement | Origin |
|----------|-----------------|--------|
| **2-Action Rule** | After every 2 search/read operations, must immediately update findings.md | Manus context engineering |
| **Read plan before major decisions** | Before making a decision, read task_plan.md to refresh the goal in the attention window | Manus Principle 4 |
| **3-Strike error protocol** | After 3 identical failures, escalate to team-lead; no silent retries | Manus error recovery |
| **Context recovery** | After compaction, must read task_plan.md → findings.md → progress.md in order | planning-with-files |
| **Template-sync escalation** | If a role discovers a durable team workflow improvement, record it and notify team-lead so it can be classified as project-local vs template-level | team system hygiene |

> **Note**: All protocols above encode assumptions about model limitations. They are subject to the Assumption Audit (see CLAUDE.md Harness Checklist) at phase boundaries or model upgrades. If a protocol consistently adds no value, team-lead may simplify or remove it.

## Custom Roles

Users may add custom roles following this format:

| Field | Required | Description |
|-------|----------|-------------|
| Name | Yes | kebab-case, used for SendMessage `to:` and task `owner:` |
| subagent_type | Yes | Must match an available agent type (note tool constraints, see table below) |
| model | Yes | haiku / sonnet / opus |
| Reference | No | Which built-in agent's methodology to follow |
| Core Responsibilities | Yes | What specifically this role does |
| Documentation Structure | Yes | Whether task subfolders are needed |

### subagent_type Tool Constraints Quick Reference

| subagent_type | Available Tools | Suitable Roles |
|---------------|----------------|---------------|
| `general-purpose` | All tools (Read/Write/Edit/Bash/Grep/Glob/...) | Roles that need to write files (dev, reviewer, tester, custodian) |
| `Explore` | Read-only tools (Read/Grep/Glob, no Write/Edit) | Pure read-only research (note: cannot write findings.md) |
| `code-reviewer` | Read/Grep/Glob/Bash (no Write/Edit) | Pure read-only review (note: cannot write findings.md) |

**Key**: All team roles need to maintain their own .plans/ files (progress.md, findings.md), so `general-purpose` is typically the right choice, with prompt constraints defining behavioral boundaries.
