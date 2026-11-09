# 학습 확인 노트

> 작업이 끝날 때마다 해당 질문에 직접 답을 적음. AI 답변 복붙 금지, 내 말로 정리.
> 답 형식: 개조식, 핵심 코드 위치(파일:함수) 같이 적음.
> 체크: `[ ]` 미완 / `[x]` 내 말로 설명 가능
> 체크는 사람만 함. AI는 체크하거나 대신 판정하지 않음. 절 이름은 `tasks.md`의 학습 칸과 같음

## Phase 1

### T03 DOM → VNode
- [ ] 실제 DOM 노드를 순회하는 방법 (childNodes vs children 차이)
- [ ] 텍스트 노드, 공백, 주석을 어떻게 처리했고 왜 그렇게 했는지

### T04 VNode → DOM
- [ ] VNode 하나를 실제 DOM으로 만드는 과정

### T05 Diff
- [ ] Diff 동작 방식 한 문단 요약
- [ ] 최소 변경 5가지 케이스 각각 예시
- [ ] key가 없으면 생기는 문제 (D07 결정과 연결)

### T06 Patch
- [ ] 변경 내역을 실제 DOM에 반영하는 방법
- [ ] 실제 DOM이 느린 이유 (Reflow / Repaint)
- [ ] 바뀐 부분만 반영하는 게 왜 이득인지

### T08–T09 Patch 버튼 / History
- [ ] Patch 버튼을 눌렀을 때 데이터 흐름
- [ ] History 이동 시 두 영역을 어떻게 맞췄는지

### Phase 1 공통
- [ ] Document와 Window 차이
- [ ] 실제 DOM 변화를 감지하는 브라우저 API (예: MutationObserver)와 이번 구현에서 썼는지
- [ ] Virtual DOM 구조와 필요한 이유
- [ ] React가 실제 DOM을 바꿀 때 VDOM·Diff가 동작하는 방식

## Phase 2

### T11 FunctionComponent
- [ ] "함수는 매번 새로 실행되는데 상태는 어떻게 유지하나?" 내 답
- [ ] hooks 배열 + 인덱스 방식, 호출 순서가 바뀌면 생기는 문제

### T12–T13 useState / 재렌더
- [ ] setState가 상태 변경 말고 하는 일
- [ ] update()에서 Diff/Patch로 이어지는 흐름

### T14 useEffect
- [ ] deps 3가지 경우의 실행 시점
- [ ] cleanup이 필요한 이유

### T15 useMemo
- [ ] 언제 재계산하고 언제 안 하는지

### T17 이벤트 핸들러
- [ ] 이벤트 핸들러를 어떻게 붙이고, 재렌더 때 어떻게 교체했는지

### T16–T19 컴포넌트 / 앱
- [ ] UI를 컴포넌트로 나눈 기준
- [ ] State를 루트에 둔 이유 (Lifting State Up)

### Phase 2 공통
- [ ] Batching이란 무엇이고 어떻게 구현할 수 있는지
- [ ] 이번 구현과 실제 React의 차이 3가지 이상
