import 'package:flutter/material.dart';

import '../data/budgeting_repository.dart';

class ViewBudgetsScreenManager {
  ViewBudgetsScreenManager({
    required BudgetingRepository repository,
  }) : _repository = repository;

  final BudgetingRepository _repository;

  final customerController = TextEditingController();
  final orderRefController = TextEditingController();

  final selectedOrderId = ValueNotifier<String?>(null);
  final expandedVersionId = ValueNotifier<String?>(null);
  final orderDetailFuture = ValueNotifier<Future<Map<String, dynamic>>?>(null);

  int? selectedYear;

  List<Map<String, dynamic>> orders = const [];
  bool ordersLoading = false;
  Object? ordersError;

  void dispose() {
    customerController.dispose();
    orderRefController.dispose();
    selectedOrderId.dispose();
    expandedVersionId.dispose();
    orderDetailFuture.dispose();
  }

  void loadOrderDetail(String? orderId) {
    selectedOrderId.value = orderId;
    expandedVersionId.value = null;
    orderDetailFuture.value =
        orderId == null ? null : _repository.fetchOrderDetail(orderId);
  }

  void selectOrder(String? orderId) {
    if (selectedOrderId.value == orderId) {
      return;
    }

    loadOrderDetail(orderId);
  }
}

