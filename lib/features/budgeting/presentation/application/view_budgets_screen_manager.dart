import 'package:flutter/material.dart';

import '../../data/budgeting_repository.dart';

class ViewBudgetsScreenManager extends ChangeNotifier {
  ViewBudgetsScreenManager({
    required BudgetingRepository repository,
  }) : _repository = repository;

  final BudgetingRepository _repository;

  final TextEditingController customerController = TextEditingController();
  final TextEditingController orderRefController = TextEditingController();

  int? selectedYear;

  final ValueNotifier<String?> selectedOrderId = ValueNotifier<String?>(null);
  final ValueNotifier<String?> expandedVersionId = ValueNotifier<String?>(null);
  final ValueNotifier<Future<Map<String, dynamic>>?> orderDetailFuture =
      ValueNotifier<Future<Map<String, dynamic>>?>(null);

  List<Map<String, dynamic>> orders = const [];
  bool ordersLoading = false;
  Object? ordersError;
  bool _isDisposed = false;

  Future<List<Map<String, dynamic>>> buildOrdersFuture() {
    return _repository.fetchOrdersWithFilters(
      customerQuery: customerController.text,
      orderRefQuery: orderRefController.text,
      year: selectedYear,
    );
  }

  Future<void> loadOrders() async {
    ordersLoading = true;
    ordersError = null;
    notifyListeners();

    try {
      final fetchedOrders = await buildOrdersFuture();
      if (_isDisposed) {
        return;
      }

      orders = fetchedOrders;
      ordersLoading = false;
      notifyListeners();
    } catch (error) {
      if (_isDisposed) {
        return;
      }

      ordersError = error;
      ordersLoading = false;
      notifyListeners();
    }
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

  void setSelectedYear(int? value) {
    selectedYear = value;
    notifyListeners();
  }

  void applyFilters() {
    loadOrders();
  }

  void clearFilters() {
    customerController.clear();
    orderRefController.clear();
    selectedYear = null;
    notifyListeners();
    loadOrders();
  }

  List<Map<String, dynamic>> getVisibleOrders() {
    final customerQuery = customerController.text.trim().toLowerCase();
    final orderRefQuery = orderRefController.text.trim().toLowerCase();

    return orders.where((item) {
      final customerName =
          (item['customer_name'] ?? '').toString().trim().toLowerCase();
      final orderRef = (item['order_ref'] ?? '').toString().trim().toLowerCase();
      final matchesCustomer =
          customerQuery.isEmpty || customerName.contains(customerQuery);
      final matchesOrderRef =
          orderRefQuery.isEmpty || orderRef.contains(orderRefQuery);
      final matchesYear =
          selectedYear == null || item['requested_year'] == selectedYear;
      return matchesCustomer && matchesOrderRef && matchesYear;
    }).toList(growable: false);
  }

  List<int> getAvailableYears() {
    final years = orders
        .map((item) => item['requested_year'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
    if (selectedYear != null && !years.contains(selectedYear)) {
      years.add(selectedYear!);
    }
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  @override
  void dispose() {
    _isDisposed = true;
    customerController.dispose();
    orderRefController.dispose();
    selectedOrderId.dispose();
    expandedVersionId.dispose();
    orderDetailFuture.dispose();
    super.dispose();
  }
}
