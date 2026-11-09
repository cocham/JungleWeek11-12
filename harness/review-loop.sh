#!/usr/bin/env bash
# Codex 검증 → (FAIL이면) Claude Code 수정 → Codex 재검증. 최대 수정 횟수까지 반복.
# 커밋·푸시·머지는 하지 않는다.
#
# 사용법: harness/review-loop.sh <작업ID> [최대 수정 횟수, 기본 2]
#
# 종료 코드
#   0  PASS
#   1  최대 수정 횟수 후에도 FAIL
#   2  실행 오류 (CLI 실패, 빈 출력, VERDICT/STATUS 형식 오류, 검증 중 파일 변경 등) — 검증 FAIL과 다름
#   3  BLOCKED — 사람 결정 필요. 수정 단계로 넘어가지 않음
#
# set -e는 쓰지 않는다. 함수가 if/|| 안에서 불리면 bash가 errexit를 끄기 때문에(H1),
# 모든 실패를 명시적으로 검사한다.

set -uo pipefail

die() { echo "⛔ 실행 오류: $*" >&2; exit 2; }

TASK="${1:-}"; [ -n "$TASK" ] || die "사용법: harness/review-loop.sh <작업ID> [최대 수정 횟수]"
MAX_FIX="${2:-2}"
case "$MAX_FIX" in ''|*[!0-9]*) die "최대 수정 횟수는 숫자여야 함: $MAX_FIX";; esac

ROOT="$(git rev-parse --show-toplevel)" || die "git 저장소 안에서 실행해야 함"
cd "$ROOT" || die "저장소 루트로 이동 실패"

CRITERIA="harness/criteria/${TASK}.md"
[ -f "$CRITERIA" ] || die "검토 기준 파일 없음: $CRITERIA"
command -v codex  >/dev/null || die "codex 없음: npm i -g @openai/codex 후 codex login"
command -v claude >/dev/null || die "claude 없음: Claude Code 설치·로그인 필요"

# 실행마다 새 폴더 → 이전 결과를 덮어쓰거나 잘못 읽지 않음 (H1)
RUN="reviews/${TASK}/run-$(date '+%Y%m%d-%H%M%S')"
[ -e "$RUN" ] && die "실행 폴더가 이미 있음: $RUN"
mkdir -p "$RUN" || die "실행 폴더 생성 실패: $RUN"

hash_stdin() {
  if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi | cut -c1-12
}

# 검증 대상 버전 (H4)
# HEAD + 파일별 "경로 / 종류·모드 / 내용 해시" 목록. 삭제된 추적 파일 포함, reviews/만 제외.
snapshot_id() {
  local head list
  head="$(git rev-parse HEAD)" || return 1
  list="$(
    git ls-files -c -o --exclude-standard -z -- . ':(exclude)reviews' |
      while IFS= read -r -d '' f; do
        if [ -L "$f" ]; then
          printf '%s\tlink\t%s\n' "$f" "$(readlink "$f")"
        elif [ -f "$f" ]; then
          mode=644; [ -x "$f" ] && mode=755
          h="$(git hash-object -- "$f")" || exit 1
          printf '%s\t%s\t%s\n' "$f" "$mode" "$h"
        else
          printf '%s\tdeleted\n' "$f"
        fi
      done | LC_ALL=C sort -u
  )" || return 1
  printf 'HEAD %s\n%s\n' "$head" "$list" | hash_stdin
}

last_line() { grep -v '^[[:space:]]*$' "$1" | tail -n 1 | tr -d '\r'; }

# 마지막 줄이 유일한 VERDICT여야 함 (H2)
verdict_of() {
  local f="$1" n last
  n="$(grep -c '^VERDICT:' "$f")"
  [ "$n" = "1" ] || return 1
  last="$(last_line "$f")"
  case "$last" in
    "VERDICT: PASS"|"VERDICT: FAIL"|"VERDICT: BLOCKED") echo "${last#VERDICT: }" ;;
    *) return 1 ;;
  esac
}

VERDICT=""
verify() {
  local round="$1" prev_review="$2" prev_fix="$3"
  local file="${RUN}/review-${round}.md" body="${RUN}/.review-${round}.body" log="${RUN}/codex-${round}.log"
  local before after rc

  rm -f "$file" "$body"
  before="$(snapshot_id)" || die "스냅샷 생성 실패 (검증 전)"

  local prompt="harness/prompts/verify.md 의 지시를 따른다.
- 작업 ID: ${TASK}
- 검토 기준 파일: ${CRITERIA}
- 회차: ${round}
- 이전 검증 결과: ${prev_review:-없음}
- 수정 기록: ${prev_fix:-없음}"

  echo "▶ [${round}] Codex 검증 중... (로그: $log)"
  codex exec -s read-only -C "$ROOT" -o "$body" "$prompt" >"$log" 2>&1
  rc=$?
  [ "$rc" -eq 0 ] || die "codex 종료 코드 $rc — 로그 확인: $log"
  [ -s "$body" ] || die "codex 결과가 비어 있음: $body"

  after="$(snapshot_id)" || die "스냅샷 생성 실패 (검증 후)"
  {
    echo "# ${TASK} 검증 결과 — 회차 ${round}"
    echo
    echo "- 일시: $(date '+%Y-%m-%d %H:%M')"
    echo "- 검증자: Codex (harness)"
    echo "- HEAD: $(git rev-parse HEAD)"
    echo "- 검증 대상 스냅샷: ${before}"
    [ "$before" = "$after" ] || echo "- ⚠ 검증 중 파일이 바뀜 (${after}) — 이 결과는 무효"
    echo
    cat "$body"
  } >"$file" || die "결과 파일 쓰기 실패: $file"
  rm -f "$body"

  [ "$before" = "$after" ] || die "검증 중 파일 변경 감지 — 결과 무효: $file"
  VERDICT="$(verdict_of "$file")" || die "VERDICT 형식 오류(없음/중복/마지막 줄 아님/알 수 없는 값): $file"
}

fix() {
  local round="$1" review="$2"
  local record="${RUN}/fix-${round}.md" log="${RUN}/claude-${round}.log" rc status

  rm -f "$record"
  local prompt="harness/prompts/fix.md 의 지시를 따른다.
- 작업 ID: ${TASK}
- 검증 결과 파일: ${review}
- 수정 기록 파일: ${record}"

  echo "▶ [${round}] Claude Code 수정 중... (로그: $log)"
  claude -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Read" "Edit" "Write" "Glob" "Grep" \
    --disallowedTools "Bash" >"$log" 2>&1
  rc=$?
  [ "$rc" -eq 0 ] || die "claude 종료 코드 $rc — 로그 확인: $log"
  [ -s "$record" ] || die "수정 기록 파일이 없음: $record"

  status="$(last_line "$record")"
  case "$status" in
    "STATUS: DONE") ;;
    "STATUS: BLOCKED") echo "⏸ BLOCKED — 수정 중 사람 결정이 필요함: $record"; exit 3 ;;
    *) die "수정 기록 마지막 줄이 STATUS: DONE/BLOCKED가 아님: $record" ;;
  esac
}

handle() {
  case "$VERDICT" in
    PASS)    echo "✅ PASS: $1"; echo "커밋은 하지 않았음. 결과와 git diff를 확인한 뒤 직접 커밋할 것."; exit 0 ;;
    BLOCKED) echo "⏸ BLOCKED — 사람 결정 필요: $1"; exit 3 ;;
    FAIL)    ;;
    *)       die "알 수 없는 판정: $VERDICT" ;;
  esac
}

round=0
review="${RUN}/review-0.md"
verify 0 "" ""
handle "$review"

while [ "$round" -lt "$MAX_FIX" ]; do
  round=$((round + 1))
  fix "$round" "$review"
  prev="$review"
  review="${RUN}/review-${round}.md"
  verify "$round" "$prev" "${RUN}/fix-${round}.md"
  handle "$review"
done

echo "❌ ${MAX_FIX}회 수정 후에도 FAIL: $review — 사람 확인 필요"
exit 1
