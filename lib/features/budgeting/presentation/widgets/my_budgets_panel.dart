import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/application/app_access_providers.dart';
import '../../../app/application/app_timer_mock_provider.dart';
import '../../application/budgeting_dashboard_providers.dart';
import '../../application/budgeting_dashboard_view_models.dart';
import '../../data/budgeting_repository.dart';
import '../dialog/edit_budget_dialog.dart';
import 'budgeting_panel.dart';

class MyBudgetsPanel extends ConsumerWidget {
  const MyBudgetsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(budgetingMyBudgetsProvider);
    final currentUserId = ref.watch(appAccessProvider).valueOrNull?.userId;
    final repository = ref.watch(budgetingRepositoryProvider);

    return BudgetingPanel(
      title: 'Os meus orcamentos',
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Erro ao carregar os meus orcamentos: $error',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Sem orcamentos atribuidos.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final myAssignment = item.assignments
                  .cast<BudgetingAssignmentItem?>()
                  .firstWhere(
                    (assignment) => assignment?.assigneeUserId == currentUserId,
                    orElse: () => null,
                  );

              return _MyBudgetCard(
                item: item,
                myAssignment: myAssignment,
                timerState: ref.watch(appTimerMockProvider),
                onEdit: () async {
                  final changed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => EditBudgetDialog(
                      orderId: item.orderId,
                      latestVersionId: item.latestVersionId,
                      orderRef: item.orderRef,
                      customerName: item.customerName,
                      currentBudgetingPhaseId: item.budgetingPhaseId,
                      currentBudgetingPhaseName: item.budgetingPhaseName,
                      currentTypologyId: null,
                      currentTypologyName: '',
                      currentProductTypeId: null,
                      currentProductTypeName: '',
                      currentIsSpecial: item.isSpecial,
                      currentProposalId: item.activeProposalId,
                      currentProposalSellTotal: item.activeProposalSellTotal,
                      currentProposalCostTotal: item.activeProposalCostTotal,
                      currentProposalCostMaterialTotal:
                          item.activeProposalCostMaterialTotal,
                      currentProposalCostLaborTotal:
                          item.activeProposalCostLaborTotal,
                      currentProposalCostProjectTotal:
                          item.activeProposalCostProjectTotal,
                      currentProposalMarginPct: item.activeProposalMarginPct,
                      currentProposalSentAt: item.activeProposalSentAt,
                      currentProposalFeedbackAt: item.activeProposalFeedbackAt,
                      currentProposalValidUntil: item.activeProposalValidUntil,
                      currentProposalItems: item.activeProposalItems,
                    ),
                  );

                  if (changed == true) {
                    ref.invalidate(budgetingNewOrdersProvider);
                    ref.invalidate(budgetingActiveBudgetsProvider);
                    ref.invalidate(budgetingMyBudgetsProvider);
                  }
                },
                onToggleTimer: () {
                  if (myAssignment == null) {
                    return;
                  }
                  ref.read(appTimerMockProvider.notifier).toggle(
                        budgetAssignmentId: myAssignment.id,
                        orderId: item.orderId,
                        orderRef: item.orderRef,
                        orderName: item.customerName,
                      );
                },
                onStopTimer: myAssignment == null
                    ? null
                    : () async {
                        final timerState = ref.read(appTimerMockProvider);
                        final result =
                            await showDialog<_WorkTimeEntryDialogResult>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => _WorkTimeEntryDialog(
                            repository: repository,
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
                          await repository.addWorkTimeEntry(
                            budgetAssignmentId: myAssignment.id,
                            categoryDefinitionId: result.categoryDefinitionId,
                            duration: result.duration,
                          );
                          ref.read(appTimerMockProvider.notifier).stop();
                          ref.invalidate(budgetingActiveBudgetsProvider);
                          ref.invalidate(budgetingMyBudgetsProvider);

                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Entrada de horas criada.'),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao guardar entrada de horas: $error',
                              ),
                            ),
                          );
                        }
                      },
                onAddManualEntry: myAssignment == null
                    ? null
                    : () async {
                        final result =
                            await showDialog<_WorkTimeEntryDialogResult>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => _WorkTimeEntryDialog(
                            repository: repository,
                            title: 'Adicionar horas manualmente',
                            submitLabel: 'Guardar entrada',
                            initialDuration: Duration.zero,
                            allowClearSession: false,
                          ),
                        );

                        if (result == null) {
                          return;
                        }

                        try {
                          await repository.addWorkTimeEntry(
                            budgetAssignmentId: myAssignment.id,
                            categoryDefinitionId: result.categoryDefinitionId,
                            duration: result.duration,
                          );
                          ref.invalidate(budgetingActiveBudgetsProvider);
                          ref.invalidate(budgetingMyBudgetsProvider);

                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Entrada manual criada.'),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao guardar entrada manual: $error',
                              ),
                            ),
                          );
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _MyBudgetCard extends StatefulWidget {
  const _MyBudgetCard({
    required this.item,
    required this.myAssignment,
    required this.timerState,
    required this.onEdit,
    required this.onToggleTimer,
    required this.onStopTimer,
    required this.onAddManualEntry,
  });

  final BudgetingMyBudgetItem item;
  final BudgetingAssignmentItem? myAssignment;
  final AppTimerMockState timerState;
  final VoidCallback onEdit;
  final VoidCallback onToggleTimer;
  final VoidCallback? onStopTimer;
  final VoidCallback? onAddManualEntry;

  @override
  State<_MyBudgetCard> createState() => _MyBudgetCardState();
}

class _MyBudgetCardState extends State<_MyBudgetCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final myAssignment = widget.myAssignment;
    final timerState = widget.timerState;
    final otherAssignments = item.assignments
        .where((assignment) => assignment.id != myAssignment?.id)
        .toList(growable: false);
    final isTimerRunningForThisOrder =
        timerState.isRunning && timerState.orderId == item.orderId;
    final isTimerPausedForThisOrder =
        timerState.isPaused && timerState.orderId == item.orderId;
    final leadAssignment = item.assignments
        .cast<BudgetingAssignmentItem?>()
        .firstWhere(
          (assignment) => assignment?.assignmentRole == 'lead',
          orElse: () => null,
        );
    final supportAssignment = item.assignments
        .cast<BudgetingAssignmentItem?>()
        .firstWhere(
          (assignment) => assignment?.assignmentRole != 'lead',
          orElse: () => null,
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BudgetingPanel.borderSoft),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('my-budget-${item.orderId}'),
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (value) {
            setState(() => _isExpanded = value);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _buildProcessLabel(item),
                style: const TextStyle(
                  fontSize: 14,
                  color: BudgetingPanel.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              _MetaChip(
                label: 'Lead: ${_displayValue(leadAssignment?.assigneeName ?? '')}',
                backgroundColor: const Color(0xFFF1ECE0),
                foregroundColor: const Color(0xFF5A4820),
              ),
              if (supportAssignment != null)
                _MetaChip(
                  label:
                      'Support: ${_displayValue(supportAssignment.assigneeName)}',
                  backgroundColor: const Color(0xFFE3E7ED),
                  foregroundColor: const Color(0xFF29394E),
                ),
              _MetaChip(
                label: item.budgetingPhaseName.isEmpty
                    ? 'Fase: -'
                    : 'Fase: ${item.budgetingPhaseName}',
                backgroundColor: const Color(0xFFDCE7DA),
                foregroundColor: const Color(0xFF234126),
              ),
              _MetaChip(
                label: 'Horas Totais: ${item.totalWorkedHours.toStringAsFixed(2)}h',
                backgroundColor: const Color(0xFFE3E7ED),
                foregroundColor: const Color(0xFF29394E),
              ),
            ],
          ),
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isExpanded
                ? Row(
                    key: const ValueKey('expanded-header-actions'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isTimerPausedForThisOrder)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton.icon(
                            onPressed:
                                myAssignment == null ? null : widget.onToggleTimer,
                            icon: Icon(
                              isTimerRunningForThisOrder
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                            ),
                            label: Text(
                              isTimerRunningForThisOrder
                                  ? 'Pausar cronometro'
                                  : 'Iniciar cronometro',
                            ),
                          ),
                        ),
                      if (isTimerPausedForThisOrder)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton.icon(
                            onPressed: widget.onToggleTimer,
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text('Retomar cronometro'),
                          ),
                        ),
                      if (isTimerPausedForThisOrder)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilledButton.tonalIcon(
                            onPressed: widget.onStopTimer,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Concluir'),
                          ),
                        ),
                      if (widget.onAddManualEntry != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: OutlinedButton.icon(
                            onPressed: widget.onAddManualEntry,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Adicionar horas'),
                          ),
                        ),
                      if (isTimerRunningForThisOrder || isTimerPausedForThisOrder)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _MetaChip(
                            label: _formatElapsed(timerState.elapsed),
                            backgroundColor: const Color(0xFFE6D4A8),
                            foregroundColor: const Color(0xFF5E4410),
                          ),
                        ),
                      if (isTimerPausedForThisOrder)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: _MetaChip(
                            label: 'Pausado',
                            backgroundColor: Color(0xFFF1ECE0),
                            foregroundColor: Color(0xFF5A4820),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: widget.onEdit,
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black54,
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('collapsed-header-actions'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Editar',
                        onPressed: widget.onEdit,
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black54,
                      ),
                    ],
                  ),
          ),
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.start,
                    children: [
                      _InfoBlock(
                        label: 'Tipologia',
                        value: _displayValue(item.primaryTypologyName),
                        minWidth: 220,
                      ),
                      _InfoBlock(
                        label: 'Produto',
                        value: _displayValue(item.primaryProductTypeName),
                        minWidth: 220,
                      ),
                      if (myAssignment != null)
                        _AssignmentCard(
                          assignment: myAssignment,
                          highlight: true,
                        ),
                      ...otherAssignments.map(
                        (assignment) => _AssignmentCard(assignment: assignment),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildProcessLabel(BudgetingMyBudgetItem item) {
    final process =
        item.orderRef.trim().isEmpty ? '(sem referencia)' : item.orderRef.trim();
    final customer = item.customerName.trim();
    if (customer.isEmpty) {
      return process;
    }
    return '$process - $customer';
  }

  String _displayValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _formatElapsed(Duration value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    final hours = twoDigits(value.inHours);
    final minutes = twoDigits(value.inMinutes.remainder(60));
    final seconds = twoDigits(value.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
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

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    this.highlight = false,
  });

  final BudgetingAssignmentItem assignment;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isLead = assignment.assignmentRole == 'lead';
    final isSupport = !isLead;

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280, minHeight: 56),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFE9EFE3)
            : (isSupport
                  ? const Color(0xFFE3E7ED)
                  : const Color(0xFFF4F0E5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? const Color(0xFFB8C9AA)
              : (isSupport ? const Color(0xFFC9D3E0) : const Color(0xFFD8C59A)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment.assigneeName.isEmpty
                ? '(sem utilizador)'
                : assignment.assigneeName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${assignment.workedHours.toStringAsFixed(2)} horas',
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    required this.minWidth,
    this.highlight = false,
  });

  final String label;
  final String value;
  final double minWidth;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFEAF0E3)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFBFD0B1) : const Color(0xFFD3D3D3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value.trim(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}






