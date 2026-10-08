# POS Mate

Flutter와 SQLite로 구현한 **편의점 POS · 재고관리 모바일 앱**입니다.  
현재는 Android 단일 단말에서 동작하는 로컬 버전에 초점을 두고 있으며, 상품 판매부터 재고 변화, 환불, 근무/정산, 매출 분석, Audit Log까지 하나의 업무 흐름으로 연결했습니다.

> 현재 버전은 서버 없이 `Flutter → Provider → LocalDatabase → SQLite` 구조로 동작합니다. 여러 단말 동기화가 필요해지면 Spring Boot + PostgreSQL 중앙 서버 구조로 확장할 계획입니다.

## 주요 기능

### POS / 결제
- 상품명·바코드·소분류 검색
- 대분류 / 소분류 필터
- 장바구니 수량 증감, 주문 취소
- 보류 주문 저장 / 복원
- 카드 / 현금 / 모바일 결제
- 현금 수납액 및 거스름돈 계산
- 성인 상품 확인
- 근무 시작 전 결제 제한

### 상품 / 재고
- 상품 등록 / 수정 / 삭제
- 대분류 + 소분류 관리
- 판매가 / 원가 / 마진
- 현재 재고 / 최소 재고
- 저재고 표시
- 유통기한 임박 / 당일 / 만료 관리
- 입고 / 재고 조정 / 폐기
- 재고 변경 이력

### 행사
- 1+1
- 2+1
- 퍼센트 할인
- 특가
- 행사 기간 / 활성 상태
- 동일 상품의 행사 기간 충돌 방지

### 판매 / 영수증 / 환불
- 판매 이력
- 영수증 검색 / 재출력 화면
- 전체 / 부분 환불
- 상품별 환불 수량 선택
- 환불 사유 / 메모 / 처리직원 기록
- 환불 시 재고 자동 복구
- 별도 `RefundTransaction` 이력 저장

### 근무 / 정산
- 근무 시작 및 초기 시재금
- 현금 입금 / 출금
- 결제수단별 매출 집계
- 예상 현금 / 실제 현금 / 차액
- 근무 마감 및 정산 이력

### 매출 분석
- 오늘 / 어제 / 최근 7일 / 이번 달 / 직접 기간
- 총매출 / 순매출 / 환불금액
- 판매 건수 / 객단가
- 판매 원가 / 매출총이익 / 마진율 / 할인금액
- 결제수단별 매출
- 카테고리별 매출
- 상품 TOP 5

### Audit Log
다음 주요 작업을 사용자·시간·대상·상세 내용과 함께 SQLite에 기록합니다.

- 상품 등록 / 수정 / 삭제
- 행사 등록 / 수정 / 삭제 / 활성 변경
- 입고 / 재고 조정 / 폐기
- 환불
- 현금 입금 / 출금
- 근무 시작 / 마감

## 사용자 권한

| 역할 | 설명 |
| --- | --- |
| ADMIN | POS, 재고, 관리 기능 사용 가능 |
| STAFF | POS, 재고 중심 사용 |

로컬 데모 계정:

```text
ADMIN : admin / admin1234
STAFF : staff / staff1234
```

## 기술 스택

| 기술 | 사용 목적 | 선택 이유 |
| --- | --- | --- |
| Flutter / Dart | Android 앱 | 모바일 UI와 앱 로직을 하나의 코드베이스로 관리 |
| Provider | 상태관리 | Auth / POS / Shift 상태를 UI와 분리해 단순하게 관리 |
| SQLite / sqflite | 로컬 DB | 서버 없이 판매·재고·환불·정산 데이터를 영구 저장 |
| path | DB 경로 | 플랫폼별 SQLite 경로 처리 |
| Material 3 | UI | Flutter 기본 컴포넌트를 이용한 일관된 모바일 UI |
| Git / GitHub | 버전 관리 | 기능별 변경 이력 및 포트폴리오 관리 |

## 아키텍처

```text
Flutter UI
   ↓
Provider
├─ AuthProvider
├─ PosProvider
└─ ShiftProvider
   ↓
Service
└─ AuditLogService
   ↓
LocalDatabase
   ↓
SQLite v5
```

- `AuthProvider`: 로그인 / 역할
- `PosProvider`: 상품, 장바구니, 판매, 환불, 행사, 재고
- `ShiftProvider`: 근무, 정산, 현금 입출금
- `AuditLogService`: 현재 로그인 사용자를 기준으로 감사 로그 저장
- `LocalDatabase`: SQLite 테이블 및 조회/저장 처리

## 프로젝트 구조

```text
lib/
├─ main.dart
├─ app.dart
├─ core/
│  └─ theme/
│     └─ pos_palette.dart
├─ data/
│  ├─ database/
│  │  └─ local_database.dart
│  ├─ demo/
│  │  └─ demo_products.dart
│  └─ models/
├─ providers/
│  ├─ auth_provider.dart
│  ├─ pos_provider.dart
│  └─ shift_provider.dart
├─ services/
│  └─ audit_log_service.dart
└─ features/
   ├─ auth/
   ├─ navigation/
   ├─ home/
   ├─ pos/
   ├─ inventory/
   ├─ management/
   ├─ sales/
   └─ shift/
```

## SQLite DB 구조

SQLite schema version: **5**

| 테이블 | 역할 | 주요 데이터 |
| --- | --- | --- |
| `products` | 상품 | 상품명, 카테고리, 판매가, 원가, 재고, 최소재고, 성인상품, 유통기한 |
| `sales` | 판매 헤더 | 영수증, 근무 ID, 결제수단, 판매금액, 직원, 상태 |
| `sale_items` | 판매 상품 | 상품, 판매가/원가 스냅샷, 수량, 행사, 환불수량 |
| `refund_transactions` | 환불 이벤트 | 환불번호, 사유, 처리직원, 환불금액, 시간 |
| `refund_items` | 환불 상품 | 상품, 수량, 환불금액 |
| `stock_movements` | 재고 이력 | 판매/입고/환불/폐기/조정, 변경 전후 재고 |
| `promotions` | 행사 | 1+1/2+1/할인/특가, 기간, 활성 여부 |
| `held_carts` | 보류 주문 | 직원, 합계, 보류시간 |
| `held_cart_items` | 보류 상품 | 상품, 수량 |
| `shifts` | 근무/정산 | 시재금, 근무시간, 마감, 매출/환불/현금 요약 |
| `cash_movements` | 현금 입출금 | 입금/출금, 금액, 사유, 직원 |
| `audit_logs` | 감사 로그 | 작업자, 역할, 작업, 대상, 상세 내용, 시간 |

논리 관계:

```text
products 1 ─ N sale_items
products 1 ─ N stock_movements
products 1 ─ N promotions

sales 1 ─ N sale_items
sales 1 ─ N refund_transactions
refund_transactions 1 ─ N refund_items

held_carts 1 ─ N held_cart_items

shifts 1 ─ N sales
shifts 1 ─ N cash_movements
```

현재 SQLite 스키마에는 FK 제약을 직접 선언하지 않았으며, 위 관계는 앱 로직에서 사용하는 논리 관계입니다.

## 상품 데이터

현재 편의점 운영 화면을 테스트할 수 있도록 **343개 상품**을 구성했습니다.

- 음료
- 주류
- 라면
- 간편식
- 베이커리
- 유제품
- 과자 / 간식
- 냉동 / 아이스크림
- 생활용품
- 기타 생활 / 상온식품
- 담배 / 궐련형 전자담배 / 카트리지

담배 계열은 46개이며 에쎄, 보헴, 말보로, 던힐, 메비우스, 레종, 더원, 테리아, MIIX, 릴 하이브리드 카트리지, AIM, 센티아, 네오, 핏 등을 포함합니다.

> 상품명은 실제 판매 상품 형태로 구성했지만 가격·원가·재고는 테스트용 값입니다. 바코드는 실제 유통 바코드가 아닌 `PM-xxxxx` 내부 코드입니다.

## UI 방향

단순한 흰색 ListTile 나열 대신 다음 기준으로 화면을 정리했습니다.

- `#F4F6F8` 회백색 배경
- 흰색 카드
- `#3182F6` 주요 액션 색상
- 19~26px 둥근 모서리
- 상태 Badge
- 숫자와 주요 지표를 크게 표시
- 불필요한 Divider 최소화

홈, POS, 재고, 상품관리, 관리, 매출분석 화면에 같은 디자인 방향을 적용했습니다.

## 실행 방법

### 요구 환경
- Flutter SDK
- Android Studio / Android SDK
- Android Emulator 또는 Android 기기

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

정상 기준:

```text
No issues found!
All tests passed!
```

## 현재 범위와 향후 확장

현재 우선순위는 **Flutter + SQLite 기반 단일 Android POS 완성**입니다.

현재 보류:
- 카메라 바코드 스캔
- 공급업체 / 발주
- 웹 관리자
- Docker

다중 단말이 필요해지는 단계에서는 다음 구조로 확장할 수 있습니다.

```text
Flutter POS A ─┐
Flutter POS B ─┼─ REST API ─ Spring Boot ─ PostgreSQL
Flutter POS C ─┘
```

이 단계에서는:
- JWT 인증
- ADMIN / STAFF RBAC
- 중앙 DB
- 재고 동시성 제어
- 서버 Transaction
- 서버 측 Audit Log
- SQLite 캐시 / 오프라인 동기화

등을 적용할 계획입니다. Docker는 서버 실행 환경을 통일할 필요가 있을 때 선택적으로 도입할 수 있습니다.

## 핵심 포인트

이 프로젝트는 단순 CRUD 앱이 아니라 다음 업무 흐름을 연결한 것이 핵심입니다.

```text
상품 등록
→ 입고 / 재고
→ POS 판매
→ 재고 차감
→ 결제 / 영수증
→ 부분 또는 전체 환불
→ 재고 복구
→ 근무 마감 / 정산
→ 기간별 매출 분석
→ Audit Log
```
