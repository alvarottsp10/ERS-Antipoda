import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTimerMockState {
  const AppTimerMockState({
    required this.budgetAssignmentId,
    required this.orderId,
    required this.orderRef,
    required this.orderName,
    required this.startedAt,
    required this.elapsed,
    required this.isPaused,
  });

  final String? budgetAssignmentId;
  final String? orderId;
  final String? orderRef;
  final String? orderName;
  final DateTime? startedAt;
  final Duration elapsed;
  final bool isPaused;

  bool get isRunning => orderId != null && startedAt != null && !isPaused;
  bool get hasActiveTimer => orderId != null && startedAt != null;

  String get orderLabel {
    final ref = orderRef?.trim() ?? '';
    final name = orderName?.trim() ?? '';
    if (ref.isEmpty && name.isEmpty) {
      return '';
    }
    if (ref.isEmpty) {
      return name;
    }
    if (name.isEmpty) {
      return ref;
    }
    return '$ref - $name';
  }

  AppTimerMockState copyWith({
    String? budgetAssignmentId,
    String? orderId,
    String? orderRef,
    String? orderName,
    DateTime? startedAt,
    Duration? elapsed,
    bool? isPaused,
    bool clearOrder = false,
    bool clearStartedAt = false,
  }) {
    return AppTimerMockState(
      budgetAssignmentId: clearOrder
          ? null
          : (budgetAssignmentId ?? this.budgetAssignmentId),
      orderId: clearOrder ? null : (orderId ?? this.orderId),
      orderRef: clearOrder ? null : (orderRef ?? this.orderRef),
      orderName: clearOrder ? null : (orderName ?? this.orderName),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      elapsed: elapsed ?? this.elapsed,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

class AppTimerMockController extends StateNotifier<AppTimerMockState> {
  AppTimerMockController()
      : super(
          const AppTimerMockState(
            budgetAssignmentId: null,
            orderId: null,
            orderRef: null,
            orderName: null,
            startedAt: null,
            elapsed: Duration.zero,
            isPaused: false,
          ),
        );

  Timer? _ticker;

  void start({
    required String budgetAssignmentId,
    required String orderId,
    required String orderRef,
    required String orderName,
  }) {
    _ticker?.cancel();
    final startedAt = DateTime.now();
    state = AppTimerMockState(
      budgetAssignmentId: budgetAssignmentId,
      orderId: orderId,
      orderRef: orderRef,
      orderName: orderName,
      startedAt: startedAt,
      elapsed: Duration.zero,
      isPaused: false,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final activeStartedAt = state.startedAt;
      if (activeStartedAt == null || state.isPaused) {
        return;
      }
      state = state.copyWith(
        elapsed: DateTime.now().difference(activeStartedAt),
      );
    });
  }

  void pause() {
    if (!state.isRunning || state.startedAt == null) {
      return;
    }

    _ticker?.cancel();
    state = state.copyWith(
      elapsed: DateTime.now().difference(state.startedAt!),
      isPaused: true,
    );
  }

  void resume() {
    if (!state.hasActiveTimer || !state.isPaused) {
      return;
    }

    _ticker?.cancel();
    final startedAt = DateTime.now().subtract(state.elapsed);
    state = state.copyWith(
      startedAt: startedAt,
      isPaused: false,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final activeStartedAt = state.startedAt;
      if (activeStartedAt == null || state.isPaused) {
        return;
      }
      state = state.copyWith(
        elapsed: DateTime.now().difference(activeStartedAt),
      );
    });
  }

  void stop() {
    _ticker?.cancel();
    state = const AppTimerMockState(
      budgetAssignmentId: null,
      orderId: null,
      orderRef: null,
      orderName: null,
      startedAt: null,
      elapsed: Duration.zero,
      isPaused: false,
    );
  }

  void toggle({
    required String budgetAssignmentId,
    required String orderId,
    required String orderRef,
    required String orderName,
  }) {
    if (state.hasActiveTimer && state.orderId == orderId) {
      if (state.isPaused) {
        resume();
      } else {
        pause();
      }
      return;
    }

    start(
      budgetAssignmentId: budgetAssignmentId,
      orderId: orderId,
      orderRef: orderRef,
      orderName: orderName,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final appTimerMockProvider =
    StateNotifierProvider<AppTimerMockController, AppTimerMockState>((ref) {
      return AppTimerMockController();
    });
