# AGENTS.md

미니 리액트 과제 저장소. Vanilla JS/TS로 Virtual DOM + Diff + Patch, 함수형 컴포넌트 + Hooks를 구현한다.

## 시작할 때 반드시 읽을 것
1. `docs/workflow.md` — 작업 절차, 판단 범위, 금지 사항 (이 파일보다 우선)
2. `docs/status.md` — 지금 어디까지 왔는지, 다음 작업
3. `docs/tasks.md` — 현재 작업의 의존성과 완료 기준
4. `docs/design.md` — 관련 설계, 확정/미정 구분
5. `docs/requirements.md` — 필요할 때

## 역할
- Codex는 검증 담당이다. `harness/review-loop.sh`로 호출되면 `harness/prompts/verify.md`를 따르고 파일을 수정하지 않는다.

## 핵심 규칙 (요약, 자세한 건 workflow.md)
- 한 번에 `tasks.md`의 작업 하나만 한다. 시작 조건은 workflow.md ①.
- 사람이 정할 결정이 미정이면 임시로 정하지 말고 멈추고 묻는다. 사람/AI 판단 범위는 workflow.md 2절.
- 외부 프레임워크 금지.
- 완료 처리 전에 작업 유형에 맞는 검증을 직접 한다 (코드: 테스트 실행, 문서·결정: workflow.md ④의 문서 검증).
- 검증 이후 대상 파일이 바뀌면 그 검증 결과는 무효다. 다시 검증한다.
- AI는 학습 확인(`docs/learning.md`)을 대신 체크하지 않는다.
- 끝내기 전에 `docs/status.md`를 갱신한다.
- main에 직접 커밋·푸시하지 않는다. 브랜치·커밋 이름은 `docs/workflow.md` ⑧의 컨벤션을 따른다.
