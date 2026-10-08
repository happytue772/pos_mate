POS Mate Audit Log 최종 적용본

[전체 교체]
lib/data/database/local_database.dart
lib/providers/pos_provider.dart
lib/providers/shift_provider.dart
lib/features/management/management_page.dart
lib/features/navigation/main_navigation_page.dart

[신규 생성]
lib/data/models/audit_log.dart
lib/services/audit_log_service.dart
lib/features/management/audit_log_page.dart

핵심 구조:
MainNavigationPage
→ 현재 로그인 사용자 AuditLogService에 등록
→ PosProvider / ShiftProvider가 중요 업무 수행 시 자동 Audit Log 기록
→ 개별 화면마다 Audit 코드를 반복해서 넣지 않음

DB 버전:
4 → 5

적용 후:
cd C:\dev\projects\pos_mate
dart format .
flutter analyze
flutter test

정상이라면 실행 중 q로 종료한 뒤:
flutter run

기록 대상:
상품 등록/수정/삭제
행사 등록/수정/삭제/활성화
입고
재고 조정
폐기
환불
현금 입금/출금
근무 시작/마감
