import 'package:flutter/material.dart';

import '../data/models/app_user.dart';
import '../data/models/cashier_shift.dart';
import '../data/models/sale.dart';

class ShiftProvider extends ChangeNotifier {
  CashierShift? _activeShift;

  final List<CashierShift> _shiftHistory = [];

  int _nextShiftId = 1;

  CashierShift? get activeShift => _activeShift;

  bool get hasActiveShift => _activeShift != null;

  List<CashierShift> get shiftHistory {
    return List.unmodifiable(_shiftHistory.reversed);
  }

  bool startShift({required AppUser user, required int openingCash}) {
    if (_activeShift != null) {
      return false;
    }

    if (openingCash < 0) {
      return false;
    }

    _activeShift = CashierShift(
      id: _nextShiftId++,
      cashierId: user.id,
      cashierName: user.name,
      openedAt: DateTime.now(),
      openingCash: openingCash,
    );

    notifyListeners();

    return true;
  }

  ShiftSummary? calculateCurrentSummary(List<Sale> sales) {
    final shift = _activeShift;

    if (shift == null) {
      return null;
    }

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
        .where((sale) => sale.refundedAmount > 0)
        .length;

    final activeSales = shiftSales.where((sale) => sale.netAmount > 0).length;

    final expectedCash = shift.openingCash + cashSales;

    return ShiftSummary(
      completedSalesCount: activeSales,
      totalSales: totalSales,
      cashSales: cashSales,
      cardSales: cardSales,
      mobileSales: mobileSales,
      refundCount: refundCount,
      refundAmount: refundAmount,
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

    final summary = calculateCurrentSummary(sales);

    if (summary == null) {
      return null;
    }

    shift.status = ShiftStatus.closed;
    shift.closedAt = DateTime.now();
    shift.actualCash = actualCash;
    shift.summary = summary;
    shift.cashDifference = actualCash - summary.expectedCash;
    _shiftHistory.add(shift);
    _activeShift = null;

    notifyListeners();
    return shift;
  }
}
