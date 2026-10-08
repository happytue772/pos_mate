import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database/local_database.dart';
import '../data/models/app_user.dart';
import '../data/models/audit_log.dart';
import '../data/models/cash_movement.dart';
import '../data/models/cashier_shift.dart';
import '../data/models/sale.dart';
import '../services/audit_log_service.dart';

class ShiftProvider extends ChangeNotifier {
  final LocalDatabase _database = LocalDatabase.instance;
  final AuditLogService _audit = AuditLogService.instance;

  CashierShift? _activeShift;

  final List<CashierShift> _shiftHistory = [];
  final List<CashMovement> _cashMovements = [];

  int _nextShiftId = 1;
  int _nextCashMovementId = 1;

  bool _isLoading = true;

  bool get isLoading => _isLoading;
  CashierShift? get activeShift => _activeShift;
  bool get hasActiveShift => _activeShift != null;

  List<CashierShift> get shiftHistory {
    return List.unmodifiable(_shiftHistory.reversed);
  }

  List<CashMovement> get cashMovements {
    return List.unmodifiable(_cashMovements.reversed);
  }

  ShiftProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final savedShifts = await _database.getShifts();
      final savedCashMovements = await _database.getCashMovements();

      _shiftHistory.clear();

      _cashMovements
        ..clear()
        ..addAll(savedCashMovements);

      final openShifts = <CashierShift>[];

      for (final shift in savedShifts) {
        if (shift.status == ShiftStatus.open) {
          openShifts.add(shift);
        } else {
          _shiftHistory.add(shift);
        }
      }

      if (openShifts.isNotEmpty) {
        openShifts.sort((a, b) => a.id.compareTo(b.id));
        _activeShift = openShifts.last;
      }

      _updateNextIds(savedShifts);
    } catch (error) {
      debugPrint('근무 SQLite 초기화 오류: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateNextIds(List<CashierShift> allShifts) {
    if (allShifts.isEmpty) {
      _nextShiftId = 1;
    } else {
      final maxShiftId = allShifts
          .map((shift) => shift.id)
          .reduce((a, b) => a > b ? a : b);

      _nextShiftId = maxShiftId + 1;
    }

    if (_cashMovements.isEmpty) {
      _nextCashMovementId = 1;
    } else {
      final maxId = _cashMovements
          .map((movement) => movement.id)
          .reduce((a, b) => a > b ? a : b);

      _nextCashMovementId = maxId + 1;
    }
  }

  void _persistShift(CashierShift shift) {
    unawaited(_saveShiftSafely(shift));
  }

  Future<void> _saveShiftSafely(CashierShift shift) async {
    try {
      await _database.upsertShift(shift);
    } catch (error) {
      debugPrint('근무 저장 오류 (id=${shift.id}): $error');
    }
  }

  void _persistCashMovement(CashMovement movement) {
    unawaited(_saveCashMovementSafely(movement));
  }

  Future<void> _saveCashMovementSafely(CashMovement movement) async {
    try {
      await _database.upsertCashMovement(movement);
    } catch (error) {
      debugPrint('현금 입출금 저장 오류 (id=${movement.id}): $error');
    }
  }

  void _writeAudit({
    required AuditAction action,
    required String targetType,
    required String detail,
    String? targetId,
    String? targetName,
  }) {
    unawaited(
      _audit.logCurrent(
        action: action,
        targetType: targetType,
        targetId: targetId,
        targetName: targetName,
        detail: detail,
      ),
    );
  }

  bool startShift({required AppUser user, required int openingCash}) {
    if (_isLoading || _activeShift != null || openingCash < 0) {
      return false;
    }

    final shift = CashierShift(
      id: _nextShiftId++,
      cashierId: user.id,
      cashierName: user.name,
      openedAt: DateTime.now(),
      openingCash: openingCash,
    );

    _activeShift = shift;
    _persistShift(shift);

    _writeAudit(
      action: AuditAction.shiftOpen,
      targetType: 'SHIFT',
      targetId: shift.id.toString(),
      targetName: shift.cashierName,
      detail: '근무 시작 · 초기 시재금 ${shift.openingCash}원',
    );

    notifyListeners();
    return true;
  }

  List<CashMovement> cashMovementsForShift(int shiftId) {
    return _cashMovements
        .where((movement) => movement.shiftId == shiftId)
        .toList();
  }

  bool addCashMovement({
    required CashMovementType type,
    required int amount,
    required String reason,
    required String cashierName,
  }) {
    final shift = _activeShift;

    if (shift == null || amount <= 0 || reason.trim().isEmpty) {
      return false;
    }

    final movement = CashMovement(
      id: _nextCashMovementId++,
      shiftId: shift.id,
      type: type,
      amount: amount,
      reason: reason.trim(),
      cashierName: cashierName,
      createdAt: DateTime.now(),
    );

    _cashMovements.add(movement);
    _persistCashMovement(movement);

    _writeAudit(
      action: type == CashMovementType.deposit
          ? AuditAction.cashDeposit
          : AuditAction.cashWithdrawal,
      targetType: 'SHIFT',
      targetId: shift.id.toString(),
      targetName: shift.cashierName,
      detail: '${type.label} ${movement.amount}원 · 사유 ${movement.reason}',
    );

    notifyListeners();
    return true;
  }

  ShiftSummary? calculateCurrentSummary(List<Sale> sales) {
    final shift = _activeShift;

    if (shift == null) {
      return null;
    }

    return _calculateSummary(shift: shift, sales: sales);
  }

  ShiftSummary _calculateSummary({
    required CashierShift shift,
    required List<Sale> sales,
  }) {
    final shiftSales = sales.where((sale) => sale.shiftId == shift.id).toList();

    final cashSales = shiftSales
        .where((sale) => sale.paymentMethod == PaymentMethod.cash)
        .fold<int>(0, (sum, sale) => sum + sale.netAmount);

    final cardSales = shiftSales
        .where((sale) => sale.paymentMethod == PaymentMethod.card)
        .fold<int>(0, (sum, sale) => sum + sale.netAmount);

    final mobileSales = shiftSales
        .where((sale) => sale.paymentMethod == PaymentMethod.mobile)
        .fold<int>(0, (sum, sale) => sum + sale.netAmount);

    final totalSales = shiftSales.fold<int>(
      0,
      (sum, sale) => sum + sale.netAmount,
    );

    final refundAmount = shiftSales.fold<int>(
      0,
      (sum, sale) => sum + sale.refundedAmount,
    );

    final refundCount = shiftSales
        .where((sale) => sale.status != SaleStatus.completed)
        .length;

    final completedSalesCount = shiftSales
        .where((sale) => sale.netAmount > 0)
        .length;

    final movements = cashMovementsForShift(shift.id);

    final cashInAmount = movements
        .where((movement) => movement.type == CashMovementType.deposit)
        .fold<int>(0, (sum, movement) => sum + movement.amount);

    final cashOutAmount = movements
        .where((movement) => movement.type == CashMovementType.withdrawal)
        .fold<int>(0, (sum, movement) => sum + movement.amount);

    final expectedCash =
        shift.openingCash + cashSales + cashInAmount - cashOutAmount;

    return ShiftSummary(
      completedSalesCount: completedSalesCount,
      totalSales: totalSales,
      cashSales: cashSales,
      cardSales: cardSales,
      mobileSales: mobileSales,
      refundCount: refundCount,
      refundAmount: refundAmount,
      cashInAmount: cashInAmount,
      cashOutAmount: cashOutAmount,
      expectedCash: expectedCash,
    );
  }

  CashierShift? closeShift({
    required int actualCash,
    required List<Sale> sales,
  }) {
    final shift = _activeShift;

    if (shift == null || actualCash < 0) {
      return null;
    }

    final summary = _calculateSummary(shift: shift, sales: sales);

    shift.status = ShiftStatus.closed;
    shift.closedAt = DateTime.now();
    shift.actualCash = actualCash;
    shift.summary = summary;
    shift.cashDifference = actualCash - summary.expectedCash;

    _shiftHistory.add(shift);
    _persistShift(shift);

    _writeAudit(
      action: AuditAction.shiftClose,
      targetType: 'SHIFT',
      targetId: shift.id.toString(),
      targetName: shift.cashierName,
      detail:
          '근무 마감 · 예상현금 ${summary.expectedCash}원 · '
          '실제현금 $actualCash원 · 차액 ${shift.cashDifference ?? 0}원',
    );

    _activeShift = null;

    notifyListeners();
    return shift;
  }
}
