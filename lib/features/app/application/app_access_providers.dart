import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_access_models.dart';

final appAccessSupabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(appAccessSupabaseProvider);
  return supabase.auth.onAuthStateChange;
});

final currentAuthUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  final supabase = ref.watch(appAccessSupabaseProvider);
  return supabase.auth.currentUser;
});

final currentUserRolesProvider =
    FutureProvider<({Set<int> ids, Set<String> codes})>((ref) async {
  final supabase = ref.watch(appAccessSupabaseProvider);
  final userId = ref.watch(currentAuthUserProvider)?.id;

  if (userId == null || userId.trim().isEmpty) {
    return (ids: <int>{}, codes: <String>{});
  }

  final response = await supabase
      .from('profile_roles')
      .select('role_id, roles!inner(id,code)')
      .eq('user_id', userId);

  final ids = <int>{};
  final codes = <String>{};
  for (final row in (response as List).cast<Map<String, dynamic>>()) {
    final roleId = (row['role_id'] as num?)?.toInt();
    if (roleId != null) {
      ids.add(roleId);
    }

    final rolesMap = row['roles'];
    if (rolesMap is Map<String, dynamic>) {
      final embeddedRoleId = (rolesMap['id'] as num?)?.toInt();
      if (embeddedRoleId != null) {
        ids.add(embeddedRoleId);
      }

      final code = (rolesMap['code'] ?? '').toString().trim().toUpperCase();
      if (code.isNotEmpty) {
        codes.add(code);
      }
    }
  }

  return (ids: ids, codes: codes);
});

final currentUserFullNameProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.watch(appAccessSupabaseProvider);
  final user = ref.watch(currentAuthUserProvider);
  final userId = user?.id;

  if (userId == null || userId.trim().isEmpty) {
    return null;
  }

  try {
    final response = await supabase
        .from('profiles')
        .select('full_name')
        .eq('user_id', userId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      final fullName = (response['full_name'] ?? '').toString().trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }
  } catch (_) {
    // Fall through to auth metadata when the profile row is not readable.
  }

  final metadataName = (user?.userMetadata?['full_name'] ?? '')
      .toString()
      .trim();
  if (metadataName.isNotEmpty) {
    return metadataName;
  }

  return null;
});

final currentUserInitialsProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.watch(appAccessSupabaseProvider);
  final userId = ref.watch(currentAuthUserProvider)?.id;

  if (userId == null || userId.trim().isEmpty) {
    return null;
  }

  try {
    final response = await supabase
        .from('profiles')
        .select('initials')
        .eq('user_id', userId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      final initials = (response['initials'] ?? '').toString().trim();
      if (initials.isNotEmpty) {
        return initials;
      }
    }
  } catch (_) {
    // Ignore profile lookup issues and let the model derive initials from name.
  }

  return null;
});

final appAccessProvider = FutureProvider<AppAccessState>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  final roles = await ref.watch(currentUserRolesProvider.future);
  final fullName = await ref.watch(currentUserFullNameProvider.future);
  final initials = await ref.watch(currentUserInitialsProvider.future);

  return AppAccessState(
    userId: user?.id,
    fullName: fullName,
    initialsValue: initials,
    roleIds: roles.ids,
    roleCodes: roles.codes,
  );
});
