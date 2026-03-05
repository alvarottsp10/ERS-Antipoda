import 'package:flutter/material.dart';
import 'landing_screen.dart';
import '../../crm/presentation/crm_dashboard_screen.dart';
import '../../budgeting/presentation/budget_dashboard_screen_manager.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarOpen = true;

  static const double _topBarHeight = 72;
  static const double _sidebarExpanded = 260;
  static const double _sidebarCollapsed = 72;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 1100;
    final sidebarWidth =
        _sidebarOpen ? _sidebarExpanded : _sidebarCollapsed;

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: _Sidebar(
                  collapsed: false,
                  onNavigate: (route) {
                    Navigator.pop(context);
                    _handleNavigate(context, route);
                  },
                ),
              ),
            ),
      body: Stack(
        children: [
          // Conteúdo abaixo da TopBar
          Positioned.fill(
            top: _topBarHeight,
            child: Row(
              children: [
                if (isWide)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: sidebarWidth,
                    child: _Sidebar(
                      collapsed: !_sidebarOpen,
                      onNavigate: (route) => _handleNavigate(context, route),
                    ),
                  ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF4F5F7),
                    padding: const EdgeInsets.all(18),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),

          // TopBar fixa
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _topBarHeight,
            child: _TopBar(
              onMenuPressed: () {
                if (isWide) {
                  setState(() => _sidebarOpen = !_sidebarOpen);
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

    Widget _screenForRoute(String route) {
    switch (route) {
      case '/crm':
        return const CrmDashboardScreen();
      case '/budgeting':
        return const BudgetDashboardScreen();
      default:
        return const LandingScreen(); // o teu “dashboard” atual
    }
  }

  void _handleNavigate(BuildContext context, String route) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AppShell(child: _screenForRoute(route)),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onMenuPressed});

  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFB1121D),
            Color(0xFF2A0E1C),
            Color(0xFF0B1220),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const SizedBox(width: 12),
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Image.asset(
              'assets/images/logo_white.png',
              height: 48,
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon:
                  const Icon(Icons.notifications_none, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black45,
                child: Text(
                  'AR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.onNavigate,
  });

  final bool collapsed;
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE7E7E7),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x22000000),
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: () => onNavigate('/dashboard'),
                ),
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.people_alt_outlined,
                  label: 'CRM',
                  onTap: () => onNavigate('/crm'),
                ),
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.request_quote_outlined,
                  label: 'Orçamentação',
                  onTap: () => onNavigate('/budgeting'),
                ),
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.engineering_outlined,
                  label: 'Projeto',
                  onTap: () => onNavigate('/project'),
                ),
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.factory_outlined,
                  label: 'Produção',
                  onTap: () => onNavigate('/production'),
                ),
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock',
                  onTap: () => onNavigate('/stock'),
                ),
                _NavItem(
                  collapsed: collapsed,
                  icon: Icons.bar_chart_outlined,
                  label: 'Relatórios',
                  onTap: () => onNavigate('/reports'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _NavItem(
            collapsed: collapsed,
            icon: Icons.settings_outlined,
            label: 'Configurações',
            onTap: () => onNavigate('/settings'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.collapsed,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool collapsed;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF1F2937)),
        tooltip: label,
      );
    }

    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1F2937)),
      title: Text(label),
      onTap: onTap,
    );
  }
}