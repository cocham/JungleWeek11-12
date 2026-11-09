#!/usr/bin/env bash
# Codex 검증 → (FAIL이면) Claude Code 수정 → Codex 재검증. 최대 수정 횟수까지 반복.
# 커밋·푸시·머지는 하지 않는다.
#
# 사용법: harness/review-loop.sh <작업ID> [최대 수정 횟수, 기본 2]
# 예:     harness/review-loop.sh T00a

set -euo pipefail

TASK="${1:?사용법: harness/review-loop.sh <작업ID> [최대 수정 횟수]}"
MAX_FIX="${2:-2}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

CRITERIA="harness/criteria/${TASK}.md"
OUT="reviews/${TASK}"
[ -f "$CRITERIA" ] || { echo "검토 기준 파일 없음: $CRITERIA" >&2; exit 1; }
command -v codex  >/dev/null || { echo "codex 없음: npm i -g @openai/codex 후 codex login" >&2; exit 1; }
command -v claude >/dev/null || { echo "claude 없음: Claude Code 설치 필요" >&2; exit 1; }
mkdir -p "$OUT"

hash_stdin() {
  if command -v sha256sum >/dev/null; then sha256sum | cut -c1-12; else shasum -a 256 | cut -c1-12; fi
}

# 검증 대상 버전: HEAD + 커밋 안 된 변경(reviews/ 제외)의 해시
snapshot_id() {
  {
    git rev-parse HEAD
    git diff HEAD -- . ':(exclude)reviews'
    git ls-files --others --exclude-standard -z -- . ':(exclude)reviews' |
      while IFS= read -r -d '' f; do cat "$f"; done
  } | hash_stdin
}

verify() {
  local round="$1" prev_review="$2" prev_fix="$3"
  local file="${OUT}/review-${round}.md"
  local before after
  before="$(snapshot_id)"

  local prompt="harness/prompts/verify.md 의 지시를 따른다.
- 작업 ID: ${TASK}
- 검토 기준 파일: ${CRITERIA}
- 회차: ${round}
- 이전 검증 결과: ${prev_review:-없음}
- 수정 기록: ${prev_fix:-없음}"

  echo "▶ [${round}] Codex 검증 중..."
  codex exec -s read-only -C "$ROOT" -o "${file}.body" "$prompt" >/dev/null

  after="$(snapshot_id)"
  {
    echo "# ${TASK} 검증 결과 — 회차 ${round}"
    echo
    echo "- 일시: $(date '+%Y-%m-%d %H:%M')"
    echo "- 검증자: Codex"
    echo "- HEAD: $(git rev-parse --short HEAD)"
    echo "- 검증 대상 스냅샷: ${before}"
    if [ "$before" != "$after" ]; then
      echo "- ⚠ 검증 중 파일이 바뀜 (${after}) — 이 결과는 무효"
    fi
    echo
    cat "${file}.body"
  } > "$file"
  rm -f "${file}.body"

  [ "$before" = "$after" ] || { echo "검증 중 파일 변경 감지 → 중단" >&2; exit 2; }
  grep -q '^VERDICT: PASS[[:space:]]*$' "$file"
}

fix() {
  local round="$1" review="$2"
  local record="${OUT}/fix-${round}.md"
  local prompt="harness/prompts/fix.md 의 지시를 따른다.
- 작업 ID: ${TASK}
- 검증 결과 파일: ${review}
- 수정 기록 파일: ${record}"

  echo "▶ [${round}] Claude Code 수정 중..."
  claude -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Read" "Edit" "Write" "Glob" "Grep" \
    --disallowedTools "Bash" >/dev/null
  [ -f "$record" ] || echo "⚠ 수정 기록 파일이 만들어지지 않음: $record" >&2
}

round=0
review="${OUT}/review-0.md"
if verify 0 "" ""; then
  echo "✅ 첫 검증 통과: $review"; exit 0
fi

while [ "$round" -lt "$MAX_FIX" ]; do
  round=$((round + 1))
  fix "$round" "$review"
  prev="$review"
  review="${OUT}/review-${round}.md"
  if verify "$round" "$prev" "${OUT}/fix-${round}.md"; then
    echo "✅ ${round}회 수정 후 통과: $review"
    echo "커밋은 하지 않았음. git diff로 확인 후 직접 커밋할 것."
    exit 0
  fi
done

echo "❌ ${MAX_FIX}회 수정 후에도 FAIL: $review — 사람 확인 필요"
exit 1
