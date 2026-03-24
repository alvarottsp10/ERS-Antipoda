import 'dart:async';

import 'package:erp_app/core/routing/app_routes.dart';
import 'package:erp_app/features/app/presentation/app_shell.dart';
import 'package:erp_app/features/app/presentation/landing_screen.dart';
import 'package:erp_app/features/auth/presentation/login_screen.dart';
import 'package:erp_app/features/budgeting/presentation/budget_dashboard_screen_manager.dart';
import 'package:erp_app/features/crm/presentation/crm_dashboard_screen.dart';
import 'package:erp_app/features/orders_projects/presentation/orders_projects_screen.dart';
import 'package:erp_app/features/projeto/presentation/projeto_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isLoginRoute = state.matchedLocation == AppRoutes.login;

    if (!isLoggedIn && !isLoginRoute) {
      return AppRoutes.login;
    }

    if (isLoggedIn && isLoginRoute) {
      return AppRoutes.dashboard;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: AppRoutes.crm,
          builder: (context, state) => const CrmDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.budgeting,
          builder: (context, state) => const BudgetDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.orders,
          builder: (context, state) => const OrdersProjectsScreen(),
        ),
        GoRoute(
          path: AppRoutes.projeto,
          builder: (context, state) => const ProjetoScreen(),
        ),
      ],
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}