import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/app_routes.dart';
import '../../budgeting/application/budgeting_dashboard_providers.dart';
import '../../budgeting/data/budgeting_repository.dart';
import '../application/app_access_models.dart';
import '../application/app_access_providers.dart';
import '../application/app_timer_mock_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const double _topBarHeight = 72;
  static const double _sidebarExpanded = 260;
  static const double _sidebarCollapsed = 72;

  bool _sidebarExpandedByHover = false;

  BudgetingRepository get _budgetingRepository => BudgetingRepository();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 1100;
    final accessAsync = ref.watch(appAccessProvider);
    final access = accessAsync.valueOrNull;
    final timerState = ref.watch(appTimerMockProvider);

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: _Sidebar(
                  collapsed: false,
                  access: access,
                  accessLoading: accessAsync.isLoading,
                  onNavigate: (route) {
                    Navigator.pop(context);
                    _handleNavigate(route);
                  },
                ),
              ),
            ),
      body: Builder(
        builder: (scaffoldContext) {
          return Stack(
            children: [
              Positioned.fill(
                top: _topBarHeight,
                child: Row(
                  children: [
                    if (isWide) const SizedBox(width: _sidebarCollapsed),
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
              if (isWide)
                Positioned(
                  top: _topBarHeight,
                  left: 0,
                  bottom: 0,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _sidebarExpandedByHover = true),
                    onExit: (_) => setState(() => _sidebarExpandedByHover = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: _sidebarExpandedByHover
                          ? _sidebarExpanded
                          : _sidebarCollapsed,
                      child: _Sidebar(
                        collapsed: !_sidebarExpandedByHover,
                        access: access,
                        accessLoading: accessAsync.isLoading,
                        onNavigate: _handleNavigate,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _topBarHeight,
                child: _TopBar(
                  access: access,
                  timerLabel: _formatElapsed(timerState.elapsed),
                  activeTimerOrderLabel: timerState.orderLabel,
                  timerRunning: timerState.isRunning,
                  timerPaused: timerState.isPaused,
                  onMenuPressed: () {
                    if (isWide) {
                      setState(
                        () => _sidebarExpandedByHover = !_sidebarExpandedByHover,
                      );
                    } else {
                      Scaffold.of(scaffoldContext).openDrawer();
                    }
                  },
                  onLogoutPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!mounted) {
                      return;
                    }
                    context.go(AppRoutes.login);
                  },
                  onPauseTimerPressed: () {
                    ref.read(appTimerMockProvider.notifier).pause();
                  },
                  onResumeTimerPressed: () {
                    ref.read(appTimerMockProvider.notifier).resume();
                  },
                  onStopTimerPressed: () => _handleStopTimerPressed(timerState),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleNavigate(String route) {
    context.go(route);
  }

  Future<void> _handleStopTimerPressed(AppTimerMockState timerState) async {
    final budgetAssignmentId = timerState.budgetAssignmentId?.trim() ?? '';
    if (budgetAssignmentId.isEmpty) {
      ref.read(appTimerMockProvider.notifier).stop();
      return;
    }

    final result = await showDialog<_WorkTimeEntryDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WorkTimeEntryDialog(
        repository: _budgetingRepository,
        title: 'Concluir registo de horas',
        submitLabel: 'Guardar entrada',
        initialDuration: timerState.elapsed,
        allowClearSession: true,
      ),
    );

    if (result == null) {
      return;
    }

    if (result.clearSession) {
      ref.read(appTimerMockProvider.notifier).stop();
      return;
    }

    try {
      await _budgetingRepository.addWorkTimeEntry(
        budgetAssignmentId: budgetAssignmentId,
        categoryDefinitionId: result.categoryDefinitionId,
        duration: result.duration,
      );
      ref.read(appTimerMockProvider.notifier).stop();
      ref.invalidate(budgetingMyBudgetsProvider);
      ref.invalidate(budgetingActiveBudgetsProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada de horas criada.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar entrada de horas: $error')),
      );
    }
  }

  String _formatElapsed(Duration value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    final hours = twoDigits(value.inHours);
    final minutes = twoDigits(value.inMinutes.remainder(60));
    final seconds = twoDigits(value.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.access,
    required this.timerLabel,
    required this.activeTimerOrderLabel,
    required this.timerRunning,
    required this.timerPaused,
    required this.onMenuPressed,
    required this.onLogoutPressed,
    required this.onPauseTimerPressed,
    required this.onResumeTimerPressed,
    required this.onStopTimerPressed,
  });

  final AppAccessState? access;
  final String timerLabel;
  final String activeTimerOrderLabel;
  final bool timerRunning;
  final bool timerPaused;
  final VoidCallback onMenuPressed;
  final Future<void> Function() onLogoutPressed;
  final VoidCallback onPauseTimerPressed;
  final VoidCallback onResumeTimerPressed;
  final VoidCallback onStopTimerPressed;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final fullName = access?.fullName?.trim();
    final initials = access?.initials?.trim().toUpperCase();
    final roleLabel = access?.roleLabel?.trim();
    final identityLabel = [
      if (fullName != null && fullName.isNotEmpty) fullName,
      if (initials != null && initials.isNotEmpty) '($initials)',
    ].join(' ');
    final accountSummary = [
      if (identityLabel.isNotEmpty) identityLabel,
      if (roleLabel != null && roleLabel.isNotEmpty) roleLabel,
    ].join(' - ');
    final tooltipText = accountSummary.isEmpty ? 'Conta' : accountSummary;

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
            if (!isWide)
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            if (!isWide) const SizedBox(width: 8),
            SizedBox(
              width: 148,
              height: 40,
              child: Image.asset(
                'assets/images/logo_white.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
            ),
            const Spacer(),
            if (timerRunning || timerPaused) ...[
              if (timerPaused)
                Tooltip(
                  message: activeTimerOrderLabel,
                  child: _PausedTimerPill(
                    timerLabel: timerLabel,
                    onResumePressed: onResumeTimerPressed,
                    onStopPressed: onStopTimerPressed,
                  ),
                ),
              if (timerRunning)
                Tooltip(
                  message: activeTimerOrderLabel,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onPauseTimerPressed,
                    child: _TimerPill(
                      timerLabel: timerLabel,
                      icon: Icons.pause_circle_outline,
                      foregroundColor: const Color(0xFF5E4410),
                      backgroundColor: const Color(0xFFE6D4A8),
                      borderColor: const Color(0xFFDFC68D),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: PopupMenuButton<String>(
                tooltip: tooltipText,
                onSelected: (value) async {
                  if (value == 'logout') {
                    await onLogoutPressed();
                  }
                },
                itemBuilder: (context) => [
                  if (accountSummary.isNotEmpty)
                    PopupMenuItem<String>(
                      enabled: false,
                      value: 'user',
                      child: Text(accountSummary),
                    ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black45,
                  child: access?.initials?.trim().isNotEmpty == true
                      ? Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              access!.initials!.trim().toUpperCase(),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                height: 1,
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.person_outline, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({
    required this.timerLabel,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    this.trailingLabel,
    this.trailingActions = const [],
  });

  final String timerLabel;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final String? trailingLabel;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor, size: 18),
          const SizedBox(width: 8),
          Text(
            timerLabel,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (trailingLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              trailingLabel!,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          if (trailingActions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...trailingActions,
          ],
        ],
      ),
    );
  }
}

class _PausedTimerPill extends StatelessWidget {
  const _PausedTimerPill({
    required this.timerLabel,
    required this.onResumePressed,
    required this.onStopPressed,
  });

  final String timerLabel;
  final VoidCallback onResumePressed;
  final VoidCallback onStopPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6D4A8).withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDFC68D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              timerLabel,
              style: const TextStyle(
                color: Color(0xFF5E4410),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const _TimerDivider(),
          _PausedTimerAction(
            icon: Icons.play_arrow_rounded,
            tooltip: 'Retomar',
            onTap: onResumePressed,
          ),
          const _TimerDivider(),
          _PausedTimerAction(
            icon: Icons.stop_rounded,
            tooltip: 'Concluir',
            onTap: onStopPressed,
          ),
        ],
      ),
    );
  }
}

class _PausedTimerAction extends StatelessWidget {
  const _PausedTimerAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF5E4410),
          ),
        ),
      ),
    );
  }
}

class _TimerDivider extends StatelessWidget {
  const _TimerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: const Color(0xFFB99753).withOpacity(0.55),
    );
  }
}

class _WorkTimeEntryDialogResult {
  const _WorkTimeEntryDialogResult({
    required this.categoryDefinitionId,
    required this.duration,
    this.clearSession = false,
  });

  const _WorkTimeEntryDialogResult.clear()
    : categoryDefinitionId = 0,
      duration = Duration.zero,
      clearSession = true;

  final int categoryDefinitionId;
  final Duration duration;
  final bool clearSession;
}

class _WorkTimeEntryDialog extends StatefulWidget {
  const _WorkTimeEntryDialog({
    required this.repository,
    required this.title,
    required this.submitLabel,
    required this.initialDuration,
    this.allowClearSession = false,
  });

  final BudgetingRepository repository;
  final String title;
  final String submitLabel;
  final Duration initialDuration;
  final bool allowClearSession;

  @override
  State<_WorkTimeEntryDialog> createState() => _WorkTimeEntryDialogState();
}

class _WorkTimeEntryDialogState extends State<_WorkTimeEntryDialog> {
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final totalMinutes = widget.initialDuration.inMinutes;
    _hoursController = TextEditingController(
      text: (totalMinutes ~/ 60).toString(),
    );
    _minutesController = TextEditingController(
      text: (totalMinutes % 60).toString(),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<List<WorkTimeCategoryOption>>(
          future: widget.repository.fetchWorkTimeCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text('Erro ao carregar categorias: ${snapshot.error}');
            }

            final categories = snapshot.data ?? const <WorkTimeCategoryOption>[];
            if (categories.isEmpty) {
              return const Text('Sem categorias ativas para registo de horas.');
            }

            _selectedCategoryId ??= categories.first.id;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Horas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutos'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (widget.allowClearSession)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                const _WorkTimeEntryDialogResult.clear(),
              );
            },
            child: const Text('Limpar sessao'),
          ),
        FilledButton(
          onPressed: () {
            final result = _buildResult();
            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Indique categoria e uma duracao maior que zero.'),
                ),
              );
              return;
            }
            Navigator.of(context).pop(result);
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  _WorkTimeEntryDialogResult? _buildResult() {
    final categoryId = _selectedCategoryId;
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final totalMinutes = (hours * 60) + minutes;

    if (categoryId == null || totalMinutes <= 0) {
      return null;
    }

    return _WorkTimeEntryDialogResult(
      categoryDefinitionId: categoryId,
      duration: Duration(minutes: totalMinutes),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.access,
    required this.accessLoading,
    required this.onNavigate,
  });

  final bool collapsed;
  final AppAccessState? access;
  final bool accessLoading;
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    final canAccessCrmManagement = access?.canAccessCrmManagement ?? false;
    final canAccessBudgetManagement =
        access?.canAccessBudgetManagement ?? false;
    final isCommercialOnly =
        (access?.isCommercial ?? false) && !canAccessCrmManagement;
    final canAccessCrm =
        (access?.isCommercial ?? false) || canAccessCrmManagement;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE7E7E7),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Color(0x22000000),
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: accessLoading
                  ? _SidebarLoading(collapsed: collapsed)
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _NavItem(
                          collapsed: collapsed,
                          icon: Icons.dashboard_outlined,
                          label: 'Dashboard',
                          onTap: () => onNavigate(AppRoutes.dashboard),
                        ),
                        if (!isCommercialOnly)
                          _NavItem(
                            collapsed: collapsed,
                            icon: Icons.assignment_outlined,
                            label: 'Pedidos e Projetos',
                            onTap: () => onNavigate(AppRoutes.orders),
                          ),
                        if (canAccessCrm)
                          _NavItem(
                            collapsed: collapsed,
                            icon: Icons.people_alt_outlined,
                            label:
                                canAccessCrmManagement ? 'CRM - Manager' : 'CRM',
                            onTap: () => onNavigate(AppRoutes.crm),
                          ),
                        if (!isCommercialOnly)
                          _NavItem(
                            collapsed: collapsed,
                            icon: Icons.request_quote_outlined,
                            label: canAccessBudgetManagement
                                ? 'Orcamentacao - Manager'
                                : 'Orcamentacao',
                            onTap: () => onNavigate(AppRoutes.budgeting),
                          ),
                        if (!isCommercialOnly)
                          _NavItem(
                            collapsed: collapsed,
                            icon: Icons.engineering_outlined,
                            label: 'Projeto',
                            onTap: () => onNavigate(AppRoutes.projeto),
                          ),
                        if (!isCommercialOnly)
                          _NavItem(
                            collapsed: collapsed,
                            icon: Icons.factory_outlined,
                            label: 'Producao',
                            onTap: () {},
                          ),
                        if (!isCommercialOnly)
                          _NavItem(
                            collapsed: collapsed,
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock',
                            onTap: () {},
                          ),
                        _NavItem(
                          collapsed: collapsed,
                          icon: Icons.bar_chart_outlined,
                          label: 'Relatorios',
                          onTap: () {},
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            if (!accessLoading && !isCommercialOnly)
              _NavItem(
                collapsed: collapsed,
                icon: Icons.settings_outlined,
                label: 'Configuracoes',
                onTap: () {},
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SidebarLoading extends StatelessWidget {
  const _SidebarLoading({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _NavLoadingIcon(),
          _NavLoadingIcon(),
          _NavLoadingIcon(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      children: const [
        _NavLoadingTile(),
        _NavLoadingTile(),
        _NavLoadingTile(),
      ],
    );
  }
}

class _NavLoadingIcon extends StatelessWidget {
  const _NavLoadingIcon();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _NavLoadingTile extends StatelessWidget {
  const _NavLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD6D6D6),
        borderRadius: BorderRadius.circular(10),
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
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Icon(icon, color: const Color(0xFF1F2937)),
                ),
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: collapsed ? 0 : 170,
                    margin: EdgeInsets.only(left: collapsed ? 0 : 12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: collapsed ? 0 : 1,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        offset:
                            collapsed ? const Offset(-0.08, 0) : Offset.zero,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}







