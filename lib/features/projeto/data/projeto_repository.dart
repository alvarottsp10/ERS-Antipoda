import 'package:supabase_flutter/supabase_flutter.dart';

class ProjetoRepository {
  final SupabaseClient _sb = Supabase.instance.client;

  String get _uid => _sb.auth.currentUser!.id;

  Future<bool> isAdmin() async {
    try {
      final res = await _sb
          .from('profile_roles')
          .select('roles!inner(code)')
          .eq('user_id', _uid)
          .eq('roles.code', 'ADMIN')
          .limit(1);
      return (res as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> currentUserName() async {
    try {
      final res = await _sb
          .from('profiles')
          .select('full_name')
          .eq('user_id', _uid)
          .single();
      return (res['full_name'] ?? '') as String;
    } catch (_) {
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final res = await _sb
          .from('orders')
          .select('id, order_ref, customers(name)')
          .order('order_ref', ascending: true);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final res = await _sb
          .from('departments')
          .select('id, name')
          .order('name', ascending: true);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getActiveTimer() async {
    try {
      final res = await _sb
          .from('active_timers')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();
      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> startTimer({
    required String workType,
    required String hourType,
    String? orderId,
    String? department,
    String? subcategory,
    String? internalCategory,
    String? internalDescription,
    List<String> relatedOrderIds = const [],
  }) async {
    await _sb.from('active_timers').delete().eq('user_id', _uid);
    await _sb.from('active_timers').insert({
      'user_id': _uid,
      'order_id': orderId,
      'work_type': workType,
      'hour_type': hourType,
      'department': department,
      'subcategory': subcategory,
      'internal_category': internalCategory,
      'internal_description': internalDescription,
      'related_order_ids': relatedOrderIds,
      'start_time': DateTime.now().toUtc().toIso8601String(),
      'is_paused': false,
      'total_paused_seconds': 0,
    });
  }

  Future<void> pauseTimer() async {
    await _sb.from('active_timers').update({
      'is_paused': true,
      'paused_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', _uid);
  }

  Future<void> resumeTimer(int currentTotalPausedSeconds) async {
    final timer = await getActiveTimer();
    if (timer == null) return;
    final pausedAt = DateTime.parse(timer['paused_at']);
    final addedPause = DateTime.now().toUtc().difference(pausedAt).inSeconds;
    await _sb.from('active_timers').update({
      'is_paused': false,
      'paused_at': null,
      'total_paused_seconds': currentTotalPausedSeconds + addedPause,
    }).eq('user_id', _uid);
  }

  Future<void> stopTimer({String? notes}) async {
    final timer = await getActiveTimer();
    if (timer == null) return;

    final startTime = DateTime.parse(timer['start_time']);
    final now = DateTime.now().toUtc();
    int totalPaused = (timer['total_paused_seconds'] as num?)?.toInt() ?? 0;

    if (timer['is_paused'] == true && timer['paused_at'] != null) {
      final pausedAt = DateTime.parse(timer['paused_at']);
      totalPaused += now.difference(pausedAt).inSeconds;
    }

    final elapsed = now.difference(startTime).inSeconds - totalPaused;
    final duration = elapsed < 0 ? 0 : elapsed;

    await _sb.from('time_entries').insert({
      'user_id': _uid,
      'order_id': timer['order_id'],
      'work_type': timer['work_type'],
      'hour_type': timer['hour_type'],
      'department': timer['department'],
      'subcategory': timer['subcategory'],
      'internal_category': timer['internal_category'],
      'internal_description': timer['internal_description'],
      'related_order_ids': timer['related_order_ids'] ?? [],
      'start_time': timer['start_time'],
      'end_time': now.toIso8601String(),
      'duration_seconds': duration,
      'notes': notes,
      'is_manual': false,
    });

    await _sb.from('active_timers').delete().eq('user_id', _uid);
  }

  Future<List<Map<String, dynamic>>> fetchHistory({int limit = 300}) async {
    try {
      final res = await _sb
          .from('time_entries')
          .select()
          .eq('user_id', _uid)
          .order('start_time', ascending: false)
          .limit(limit);
      final entries = (res as List).cast<Map<String, dynamic>>();
      for (final e in entries) {
        if (e['order_id'] != null) {
          try {
            final order = await _sb
                .from('orders')
                .select('order_ref, customers(name)')
                .eq('id', e['order_id'])
                .maybeSingle();
            e['orders'] = order;
          } catch (_) {}
        }
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteEntry(String entryId) async {
    await _sb.from('time_entries').delete().eq('id', entryId);
  }

  Future<void> updateEntry({
    required String entryId,
    required String workType,
    required String hourType,
    String? orderId,
    String? department,
    String? subcategory,
    String? internalCategory,
    String? internalDescription,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final duration = endTime.difference(startTime).inSeconds;
    await _sb.from('time_entries').update({
      'work_type': workType,
      'hour_type': hourType,
      'order_id': orderId,
      'department': department,
      'subcategory': subcategory,
      'internal_category': internalCategory,
      'internal_description': internalDescription,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'duration_seconds': duration < 0 ? 0 : duration,
      'notes': notes,
    }).eq('id', entryId);
  }

  Future<void> addManualEntry({
    required String workType,
    required String hourType,
    String? orderId,
    String? department,
    String? subcategory,
    String? internalCategory,
    String? internalDescription,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final duration = endTime.difference(startTime).inSeconds;
    await _sb.from('time_entries').insert({
      'user_id': _uid,
      'order_id': orderId,
      'work_type': workType,
      'hour_type': hourType,
      'department': department,
      'subcategory': subcategory,
      'internal_category': internalCategory,
      'internal_description': internalDescription,
      'related_order_ids': [],
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'duration_seconds': duration < 0 ? 0 : duration,
      'notes': notes,
      'is_manual': true,
    });
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final res = await _sb
          .from('profiles')
          .select('user_id, full_name')
          .order('full_name', ascending: true);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminEntries({
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      var q = _sb
          .from('time_entries')
          .select('*, profiles!inner(full_name)');

      if (userId != null) q = q.eq('user_id', userId);
      if (from != null) q = q.gte('start_time', from.toUtc().toIso8601String());
      if (to != null) {
        final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59).toUtc();
        q = q.lte('start_time', toEnd.toIso8601String());
      }

      final res = await q.order('start_time', ascending: false).limit(500);
      final entries = (res as List).cast<Map<String, dynamic>>();
      for (final e in entries) {
        if (e['order_id'] != null) {
          try {
            final order = await _sb
                .from('orders')
                .select('order_ref, customers(name)')
                .eq('id', e['order_id'])
                .maybeSingle();
            e['orders'] = order;
          } catch (_) {}
        }
      }
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrderHours(String orderId) async {
    try {
      final res = await _sb
          .from('time_entries')
          .select('department, duration_seconds, work_type')
          .eq('order_id', orderId);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}