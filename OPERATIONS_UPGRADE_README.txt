POS Mate 운영 기능 확장 최종 적용본
====================================

이번 적용 기능
1. 빠른 판매 / 즐겨찾기
- POS 상품 카드의 별표로 즐겨찾기 등록/해제
- POS 상단 빠른 판매 영역에 즐겨찾기 상품 표시
- 빠른 판매 카드 탭으로 장바구니에 즉시 추가
- SQLite product_favorites 테이블에 저장되어 앱 재실행 후에도 유지
- 즐겨찾기는 현재 단말/매장 공용 기준

2. 가격 변경 이력
- 상품 수정 시 판매가 또는 원가가 바뀌면 자동 이력 생성
- 변경 전/후 판매가, 원가, 변경 직원, 변경 시간 기록
- 관리 > 가격 변경 이력에서 검색/조회
- Audit Log에도 가격 변경 기록

3. 거래 취소(VOID)
- 관리 > 거래 취소 메뉴 추가
- 현재 열려 있는 근무(Shift)에서 결제된 미환불 거래만 취소 가능
- 취소 사유 필수
- 취소 시 판매 상품 재고 자동 복구
- 거래 상태 SaleStatus.voided 저장
- 처리자 / 취소 시간 / 취소 사유 저장
- Audit Log 기록
- 매출 분석 및 정산에서 취소 거래 금액 제외
- 이미 부분/전체 환불된 거래는 취소 불가
- 과거 마감 Shift 거래는 정산 일관성을 위해 취소 불가

4. 직원 회원가입 / 로그인
- 관리자 계정은 admin / admin1234 한 개로 고정
- 직원 회원가입 아이디는 staff1 ~ staff99 형식만 허용
- staff01 / staff0 / staff100 등은 불가
- 직원 이름 / 비밀번호 등록
- SQLite staff_accounts 저장
- 직원 로그인 가능
- STAFF는 기존 Navigation 정책대로 POS/재고 중심 사용
- ADMIN은 관리 화면 사용 가능
- 관리 > 직원 관리에서 직원 계정 활성/비활성 가능
- 가입/상태변경 Audit Log 기록

5. 로그아웃
- 홈 우측 로그아웃 버튼
- 근무 중에는 로그아웃 차단
- 근무 마감 후 계정 전환 가능

DB 변경
- SQLite schema version: 5 -> 6
- 신규 테이블:
  product_favorites
  price_change_history
  staff_accounts
- sales 신규 컬럼:
  voided_at
  voided_by
  void_reason

중요한 현재 제약
- 직원 비밀번호는 현재 로컬 SQLite 프로토타입 방식으로 저장합니다.
- 다중 단말/원격 로그인 단계에서는 Spring Boot 서버에서 안전한 비밀번호 해시,
  JWT/RBAC, 중앙 PostgreSQL 방식으로 전환하는 것이 맞습니다.

적용 파일
- lib/data/database/local_database.dart
- lib/data/models/app_user.dart
- lib/data/models/audit_log.dart
- lib/data/models/price_change_history.dart
- lib/data/models/sale.dart
- lib/data/models/staff_account.dart
- lib/providers/auth_provider.dart
- lib/providers/pos_provider.dart
- lib/providers/shift_provider.dart
- lib/services/audit_log_service.dart
- lib/features/auth/login_page.dart
- lib/features/auth/staff_register_page.dart
- lib/features/home/home_page.dart
- lib/features/pos/pos_page.dart
- lib/features/management/management_page.dart
- lib/features/management/audit_log_page.dart
- lib/features/management/price_change_history_page.dart
- lib/features/management/staff_manage_page.dart
- lib/features/sales/void_sale_page.dart
- lib/features/sales/sales_analytics_page.dart
- lib/features/navigation/main_navigation_page.dart
- lib/core/theme/pos_palette.dart

적용 후 권장 확인
1. dart format .
2. flutter analyze
3. flutter test
4. flutter run

테스트 시나리오
A. staff1 회원가입 -> staff1 로그인 -> POS/재고 접근 확인
B. admin 로그인 -> 직원 관리에서 staff1 비활성 -> staff1 로그인 차단 확인
C. 상품 별표 -> 빠른 판매 표시 -> 앱 재시작 -> 즐겨찾기 유지 확인
D. 상품 판매가/원가 수정 -> 가격 변경 이력 확인
E. 근무 시작 -> 판매 -> 관리/거래 취소 -> 재고 복구 및 매출 제외 확인
F. 거래 취소 후 Audit Log 확인
