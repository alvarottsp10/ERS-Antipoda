import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MOSTRA AS CAIXAS DOS WIDGETS (debug layout)
  debugPaintSizeEnabled = false;

  await Supabase.initialize(
    url: 'https://cvcjfyvhgxpmdlrfzprf.supabase.co',
    anonKey: 'sb_publishable_b2Wx-sghyn8Z6CLQJyh0Ow_ous95xDu',
  );

  runApp(const ErpApp());
}

class ErpApp extends StatelessWidget {
  const ErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
      ),
    );
  }
}
