# T00a 수정 기록 — 1회차

- 수정자: Claude (채팅 세션 — 로컬에 Claude CLI가 없어 하네스 밖에서 수동 수정)
- 근거 검증: `reviews/T00a/review-0.md`, `reviews/harness-review.md` (둘 다 `d14036c` 기준)
- 허용 범위: 사람이 T00a에 한해 `harness/`, `docs/workflow.md` 수정을 허용 (`harness/criteria/T00a.md`에 기록)

## 수정 기록
| 기준 | 판정 | 한 일 | 바꾼 파일 |
|---|---|---|---|
| H1 | FAIL | `set -e` 제거, CLI 종료 코드를 명시적으로 검사. 실패·빈 출력은 실행 오류(종료 2)로 처리. 실행마다 새 `run-<시각>` 폴더 사용, 쓰기 전 기존 출력 삭제, CLI 로그 저장 | `harness/review-loop.sh` |
| H2 | FAIL | `VERDICT:` 줄이 정확히 1개이고 마지막 줄이며 PASS/FAIL/BLOCKED일 때만 인정, 아니면 실행 오류. 수정 기록이 없거나 마지막 줄이 `STATUS: DONE/BLOCKED`가 아니면 실행 오류 | `harness/review-loop.sh`, `harness/prompts/verify.md`, `harness/prompts/fix.md` |
| H3 | FAIL | `BLOCKED` 판정 추가(검증·수정 양쪽). BLOCKED면 수정 단계로 가지 않고 종료 3. 이후 작업용 미정 결정과 이 작업을 막는 결정을 구분 | `harness/review-loop.sh`, `harness/prompts/*.md`, `harness/criteria/T00a.md` |
| H4 | FAIL | 스냅샷을 HEAD + 파일별 "경로/모드/내용 해시" 목록으로 변경. 삭제된 추적 파일 포함, `reviews/`만 제외. 생성 실패 시 실행 오류 | `harness/review-loop.sh` |
| C1 | FAIL | 작업 `유형`·`산출 결정` 칸 추가. 결정 작업은 산출 결정을 필요 결정으로 갖지 않음(T02 순환 제거). workflow ② 결정 절차 추가. D15를 T01에서 T00 산출 결정으로 옮겨 같은 순환 제거 | `docs/tasks.md`, `docs/workflow.md`, `docs/design.md` |
| C2 | FAIL | `선행 작업`(T)과 `필요 결정`(D) 칸 분리, 시작 조건에 둘 다 포함. 의존성 재정리: T00a→T00→T01, T14는 T13 이후(patch와 effect 순서), T17은 T06·T13 이후 등 | `docs/tasks.md`, `docs/workflow.md` ① |
| C3 | FAIL | `학습 확인 대기` 상태와 `학습` 칸(절 이름 또는 `해당 없음`) 추가. AI는 학습 체크·판정 금지, 사람이 알린 뒤에만 완료. 상태 전환표 추가 | `docs/tasks.md`, `docs/workflow.md` ⑥·4절, `docs/learning.md`, `AGENTS.md` |
| C4 | FAIL | 사람 결정 범위와 AI 판단 범위를 목록으로 정의. 임시 구현 허용 규칙 삭제 → 미정이면 `보류` 후 질문 | `docs/workflow.md` 2절, `AGENTS.md` |
| C5 | FAIL | T08 필요 결정에 D09 추가. T08 완료 기준에 초기 기록, 이전 스냅샷 보존, 뒤로 간 뒤 Patch 처리 추가(정책은 D09에 맡김). D09 하위 질문 구체화 | `docs/tasks.md`, `docs/design.md` 5절·결정 목록 |
| C6 | FAIL | 검증 결과 필수 기록(버전, 검증자, 수행 내용) 규정. 검증 후 대상 변경 시 결과 무효·재검증 규칙. 인계 템플릿에 담당·검증 대상 버전·결과 파일 추가. 스냅샷 경로 문제는 H4로 해결 | `docs/workflow.md` ④⑤, `docs/status.md`, `harness/README.md` |
| C7 | FAIL | 작업 유형별 검증 방법표(구현·설정 / 문서 / 결정). AGENTS·금지 사항의 "테스트 실행"을 "유형에 맞는 검증"으로 통일 | `docs/workflow.md` ④·5절, `AGENTS.md`, `harness/prompts/verify.md` |
| 기타 | — | design.md 흐름도를 개념도로 표시하고 Diff 결과 형식은 D06에 맡김 | `docs/design.md` |

## 하네스 자체 시험 (가짜 codex/claude, 실제 AI 호출 없음)
| 입력 | 결과 |
|---|---|
| PASS 다음 FAIL | 종료 2 (형식 오류) |
| PASS 출력 + codex 종료 7 | 종료 2 |
| VERDICT 없음 | 종료 2, 수정 단계 호출 안 함 |
| 빈 출력 | 종료 2 |
| 검증 중 추적 안 된 파일 이름 변경 / 추적 파일 삭제 / 실행 권한 변경 | 종료 2 (결과 무효) |
| BLOCKED | 종료 3, 수정 단계 호출 안 함 |
| FAIL → 수정 → PASS | 종료 0 |
| 수정 기록 없음 / claude 종료 1 | 종료 2 |
| 수정 기록 STATUS: BLOCKED | 종료 3 |
| 2회 수정 후에도 FAIL | 종료 1 |
| CRLF 줄바꿈 VERDICT | 정상 인식 |

## 사람이 결정해야 할 것
- 이번 작업(T00a)을 막는 결정: 없음
- 이후 작업에서 정할 것(미정으로 기록됨): D01–D15, D17, D18, main 반영 방식(D19 하위)

STATUS: DONE
