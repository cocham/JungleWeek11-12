# T00a document review — initial review

- Reviewed commit: d14036c0804ce4d9924578df0875a1da01c4938f
- Date: 2026-11-09 Asia/Seoul
- Reviewer: Codex desktop, direct inspection (not a CLI loop run)
- Snapshot: clean tracked files at the commit; generated reviews/ excluded.
- No document fixes were performed.

## Criteria

### C1 Decision tasks can start — FAIL
- Evidence: docs/tasks.md:6, 23; docs/workflow.md:33-41.
- T02 requires D04 before starting, but deciding D04 is its deliverable. Decision work needs its own proposal/selection/recording procedure.

### C2 Task dependencies and design decisions — FAIL
- Evidence: docs/tasks.md:13-53; docs/workflow.md:34.
- A column named prerequisite decisions mixes T and D IDs. Selection checks decisions only. Separate task completion dependencies from required confirmed decisions; clarify ordering, including hook runtime dependencies and bootstrap T00a.

### C3 Waiting for human learning confirmation — FAIL
- Evidence: docs/tasks.md:5, 9; docs/workflow.md:54-60.
- No waiting-for-learning state exists, and tasks without learning questions have no not-applicable path. Human confirmation must not be inferred by an AI.

### C4 Human decisions versus internal implementation — FAIL
- Evidence: AGENTS.md:17; docs/workflow.md:39-41.
- All design decisions stop work, but temporary implementation is also allowed without an explicit permission condition. Define human-controlled public contracts/scope separately from local implementation choices, and remove contradictory fallback behavior.

### C5 History contract before T08 — FAIL
- Evidence: docs/tasks.md:29-30; docs/design.md:63, 101.
- T08 stores History before requiring D09; D09 appears only at T09. Require D09 before T08. Add acceptance criteria for initial history, immutable earlier snapshots, and branch-after-back behavior without choosing the policy for the user.

### C6 Reviewed version and invalidation — FAIL
- Evidence: docs/status.md:23-29; docs/workflow.md:44-52; harness/review-loop.sh:28-34.
- Controller records a version and rechecks after fixes, but general handoff records lack target version and responsible roles. Post-review edits need explicit invalidation/retest rules. Untracked rename detection is incomplete; see reviews/harness-review.md H4.

### C7 Documentation verification — FAIL
- Evidence: AGENTS.md:19; docs/workflow.md:46, 90; harness/prompts/verify.md:11-17.
- The verifier prompt correctly describes document checks, but shared mandatory rules still require test execution without a document-only exception. Make the common rules consistent and record actual consistency/reference/scenario checks for docs-only tasks.

## Previous FAIL resolution

Initial review; no fixes yet.

## Other findings

- Controller blockers with mock reproduction are recorded in reviews/harness-review.md. Fix before automatic execution; the current fix prompt does not allow harness changes.
- docs/design.md:15, 30 assume a change-list boundary while D06 still treats that boundary as undecided. Describe the diagram as conceptual or await the decision consistently.
- No real AI-to-AI run occurred. Claude CLI is unavailable locally; Codex CLI is available and logged in using ChatGPT.

VERDICT: FAIL
