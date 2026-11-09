# harness — Claude Code 구현 ↔ Codex 검증 연결

## 구조

```
harness/
  review-loop.sh        검증 → 수정 → 재검증 루프 (최대 2회 수정)
  prompts/verify.md     Codex 검증 지시 (출력 형식, VERDICT 줄)
  prompts/fix.md        Claude Code 수정 지시
  criteria/<작업ID>.md  작업별 검토 기준
reviews/<작업ID>/
  review-N.md           N회차 검증 결과 (검증한 스냅샷 해시 포함)
  fix-N.md              N회차 수정 기록
```

## 흐름

```
Codex 검증(review-0) ─ PASS → 끝
        │ FAIL
        ▼
Claude Code 수정(fix-1) → Codex 재검증(review-1) ─ PASS → 끝
        │ FAIL
        ▼
Claude Code 수정(fix-2) → Codex 재검증(review-2) ─ PASS → 끝
                                                └ FAIL → 멈춤, 사람 확인
```

## 권한
| 도구 | 권한 | 이유 |
|---|---|---|
| Codex | `-s read-only` 샌드박스. 결과는 CLI `-o` 옵션으로 파일에 저장 | 검증자가 코드를 고치지 못하게 |
| Claude Code | `acceptEdits`, Read/Edit/Write/Glob/Grep만 허용, Bash 금지 | 파일 수정만, git 명령 불가 |

- 스크립트는 커밋·푸시·머지를 하지 않는다.
- 검증 전후 스냅샷이 다르면 결과를 무효로 표시하고 멈춘다.

## 준비 (최초 1회)
1. Claude Code: 설치·로그인되어 있어야 함 (`claude --version`)
2. Codex CLI: `npm i -g @openai/codex` → `codex login`
   - ChatGPT 유료 플랜 계정 로그인 또는 OpenAI API 키 필요. API 키를 쓰면 사용량만큼 과금됨
3. 실행 권한: `chmod +x harness/review-loop.sh` (커밋에 포함돼 있으면 생략)

## 실행
저장소 루트에서:
```bash
harness/review-loop.sh T00a
```
끝나면 `reviews/T00a/`의 결과와 `git diff`를 확인하고 직접 커밋한다.

## 새 작업에 쓰려면
`harness/criteria/<작업ID>.md`에 검증 대상과 기준을 쓰고 같은 명령으로 실행한다.
