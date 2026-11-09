# Harness review

- Reviewed commit: d14036c0804ce4d9924578df0875a1da01c4938f
- Date: 2026-11-09 Asia/Seoul
- Reviewer: Codex desktop
- Scope: bootstrap script, handoff prompts, local prerequisites; no source changes.
- Codex CLI: 0.167.0-alpha.3.2, logged in using ChatGPT.
- Claude CLI: not found on PATH or checked default native/npm locations.
- Git Bash: C:/Program Files/Git/bin/bash.exe available; bash -n passed.
- Real agent loop: NOT RUN. Mock results are not evidence of real agent integration.

## Blocking findings

### H1 [P1] CLI failures can be accepted as success

Location: harness/review-loop.sh:51, 91, 100.

verify is invoked as an if condition. Bash disables errexit for commands inside that function in this context. A nonzero codex exit does not reliably stop verify. A mock that writes VERDICT: PASS and exits 7 produces overall exit 0 and a first-review-pass message.

Required: explicitly check CLI exit status, stop on execution failures, require fresh nonempty output, and never interpret an operational error as a code-review FAIL. Remove or uniquely name old output before invocation.

### H2 [P1] Verdict parsing accepts contradictory output

Location: harness/review-loop.sh:70; harness/prompts/verify.md:39.

The script searches for PASS anywhere rather than validating the final verdict. Mock output containing VERDICT: PASS followed by VERDICT: FAIL is accepted with exit 0. Output with no verdict invokes the fixer twice instead of stopping for malformed output. Missing fix records are only warnings (line 86).

Required: validate one unambiguous final verdict, reject missing/duplicate/unknown verdicts, and stop on missing required fix records. Structured JSON with schema validation is an alternative, not a requirement.

### H3 [P1] Human-decision-needed is folded into PASS

Location: harness/criteria/T00a.md:22-24; harness/prompts/fix.md:7; harness/review-loop.sh:89-108.

The criteria explicitly permit PASS when human decisions remain merely marked as undecided. The controller has no blocked state. This contradicts the requested behavior of returning to the user when a design decision is needed.

Required: distinguish nonblocking future decisions from decisions blocking this task; add a machine-readable BLOCKED/NEEDS_INPUT outcome and stop without invoking the fixer or marking the task complete.

### H4 [P2] Snapshot does not identify untracked paths

Location: harness/review-loop.sh:28-34.

Untracked file contents are concatenated without filenames or boundaries. Mock verification renamed untracked-a.txt to untracked-b.txt, preserving bytes, and was accepted as unchanged. File paths are relevant to imports and document references.

Required: hash a deterministic manifest containing relative path, type/mode where relevant, and content hash per file; preserve tracked deletions and exclude only intended output paths. Fail if snapshot generation fails.

## Mock reproduction

Test driver: C:/Users/Public/Documents/ESTsoft/CreatorTemp/probe-mini-react-loop.sh

All tests used a disposable initialized Git repository and fake codex/claude executables; no paid AI calls occurred.

| Input | Expected | Observed |
|---|---|---|
| PASS then final FAIL | Reject invalid/conflicting verdict | Accepted, exit 0 |
| Codex exit 7 after PASS output | Stop as execution error | Accepted, exit 0 |
| Missing verdict | Stop as malformed output | Two fix invocations, exit 1 |
| Untracked file renamed with identical bytes | Invalidate changed snapshot | Accepted, exit 0 |

## Handoff

Fix the harness blockers before running the T00a document repair loop. This needs authorization to modify harness/, because the current fix prompt forbids harness edits. The user has requested automatic communication; this report is the handoff artifact, but the controller cannot consume it automatically until Claude CLI is available and the blocking controller behavior is repaired.

No commit, push, merge, or mini-react implementation performed. Existing main checkout and mini-react-toy/ were preserved.

VERDICT: FAIL
