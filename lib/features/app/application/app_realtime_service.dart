import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AppRealtimeService {
  AppRealtimeService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  RealtimeChannel watchTables({
    required String channelName,
    required List<String> tables,
    required void Function() onChanged,
  }) {
    debugPrint('Realtime creating channel: $channelName for tables: $tables');
    final channel = _supabase.channel(channelName);

    for (final table in tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          debugPrint(
            'Realtime event on $table: '
            '${payload.eventType} schema=${payload.schema} table=${payload.table}',
          );
          onChanged();
        },
      );
    }

    channel.subscribe((status, error) {
      debugPrint(
        'Realtime channel $channelName status: $status'
        '${error != null ? ' error=$error' : ''}',
      );
    });
    return channel;
  }

  Future<void> disposeChannel(RealtimeChannel channel) {
    debugPrint('Realtime disposing channel: ${channel.topic}');
    return _supabase.removeChannel(channel);
  }
}
