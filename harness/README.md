# harness — Claude Code 구현 ↔ Codex 검증 연결

## 구조

```
harness/
  review-loop.sh        검증 → 수정 → 재검증 루프 (기본 최대 2회 수정)
  prompts/verify.md     Codex 검증 지시 (판정 값, 마지막 줄 VERDICT)
  prompts/fix.md        Claude Code 수정 지시 (마지막 줄 STATUS)
  criteria/<작업ID>.md  작업별 검증 대상·수정 허용 범위·기준
reviews/<작업ID>/run-<YYYYMMDD-HHMMSS>/   실행할 때마다 새 폴더
  review-N.md           N회차 검증 결과 (HEAD, 검증 대상 스냅샷 해시 포함)
  fix-N.md              N회차 수정 기록
  codex-N.log, claude-N.log   CLI 출력 로그
```

## 흐름

```
Codex 검증(review-0) ─ PASS → 종료 0
        │            └ BLOCKED → 종료 3 (사람 결정)
        │ FAIL
        ▼
Claude 수정(fix-1) ─ STATUS: BLOCKED → 종료 3
        │ STATUS: DONE
        ▼
Codex 재검증(review-1) ─ PASS / BLOCKED / FAIL → (반복, 최대 2회 수정)
                                              └ 2회 후에도 FAIL → 종료 1
어느 단계든 실행 오류 → 종료 2
```

## 종료 코드
| 코드 | 의미 |
|---|---|
| 0 | PASS |
| 1 | 최대 수정 후에도 FAIL — 사람 확인 |
| 2 | 실행 오류 — CLI 실패, 빈 출력, VERDICT/STATUS 형식 오류, 검증 중 파일 변경. **검증 FAIL이 아님** |
| 3 | BLOCKED — 사람이 정책을 정해야 함. 수정 단계로 넘어가지 않음 |

## 엄격하게 확인하는 것
- CLI 종료 코드가 0이 아니면 즉시 실행 오류
- 결과 파일: 비어 있으면 실행 오류. `VERDICT:` 줄이 정확히 1개이고 마지막 줄이며 PASS/FAIL/BLOCKED 중 하나여야 함
- 수정 기록: 없거나 마지막 줄이 `STATUS: DONE`/`STATUS: BLOCKED`가 아니면 실행 오류
- 검증 대상 스냅샷: HEAD + 파일별 경로·모드·내용 해시(삭제 포함, `reviews/` 제외). 검증 전후가 다르면 결과 무효
- 실행마다 새 폴더를 만들어 이전 결과를 읽거나 덮어쓰지 않음

## 권한
| 도구 | 권한 | 이유 |
|---|---|---|
| Codex | `-s read-only` 샌드박스. 결과는 CLI `-o` 옵션으로 파일에 저장 | 검증자가 파일을 고치지 못하게 |
| Claude Code | `acceptEdits`, Read/Edit/Write/Glob/Grep만 허용, Bash 금지 | 파일 수정만, git 명령 불가 |

스크립트는 커밋·푸시·머지를 하지 않는다.

## 준비 (최초 1회)
1. Claude Code CLI: 설치·로그인 (`claude --version`으로 확인). 수정 단계에서 Claude 사용량이 차감됨
2. Codex CLI: `npm i -g @openai/codex` → `codex login`
   - ChatGPT 유료 플랜 계정 또는 OpenAI API 키 필요. API 키는 사용량만큼 과금
3. Windows: Git Bash 또는 WSL에서 실행

## 실행
저장소 루트에서:
```bash
harness/review-loop.sh T00a
```
끝나면 해당 `run-*` 폴더와 `git diff`를 확인하고 직접 커밋한다.

## 루프 밖에서 검증·수정했을 때 (수동)
CLI 없이 직접 검증하거나 수정한 경우에도 같은 형식으로 남긴다.
- 검증 결과: 검증한 커밋 해시와 "커밋 안 된 변경 있음/없음"을 머리에 적고, 마지막 줄 VERDICT
- 수정 기록: 마지막 줄 STATUS

## 새 작업에 쓰려면
`harness/criteria/<작업ID>.md`에 작업 유형, 검증 대상, 수정 허용 범위, 기준을 쓰고 같은 명령으로 실행한다.
