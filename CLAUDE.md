# CLAUDE.md

이 저장소의 공통 지침은 `AGENTS.md`와 `docs/`에 있다. Codex와 같은 문서를 쓴다.

@AGENTS.md
@docs/workflow.md
@docs/status.md

## 시작할 때
- 위에서 불러온 현재 상태를 확인한 뒤 `docs/tasks.md`에서 현재 작업을, `docs/design.md`에서 관련 절을 읽는다.

## Claude Code 전용
- Claude Code는 구현·수정 담당이다. `harness/review-loop.sh`로 호출되면 `harness/prompts/fix.md`를 따른다.
- 플러그인(oh-my-claudecode, Superpowers 등)이 만든 계획·스펙 파일보다 `docs/`가 우선이다. 플러그인 결과물은 `docs/tasks.md`, `docs/design.md`에 반영한 뒤 진행한다.
