import 'package:erp_app/features/crm/application/crm_commercial_providers.dart';
import 'package:erp_app/features/crm/application/crm_dashboard_providers.dart';
import 'package:erp_app/features/crm/application/crm_dashboard_view_models.dart';
import 'package:erp_app/features/crm/application/crm_order_actions_service.dart';
import 'package:erp_app/features/crm/application/crm_process_folder_helper.dart';
import 'package:erp_app/features/crm/application/crm_send_proposal_models.dart';
import 'package:erp_app/features/budgeting/application/budgeting_dashboard_providers.dart';
import 'package:erp_app/features/crm/domain/crm_models.dart';
import 'package:erp_app/features/crm/presentation/dialogs/send_proposal_dialog.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crm_panel.dart';

class OrdersInProgressPanel extends ConsumerStatefulWidget {
  const OrdersInProgressPanel({
    super.key,
    this.useCurrentCommercialOnly = false,
  });

  final bool useCurrentCommercialOnly;

  @override
  ConsumerState<OrdersInProgressPanel> createState() =>
      _OrdersInProgressPanelState();
}

class _OrdersInProgressPanelState extends ConsumerState<OrdersInProgressPanel> {
  final _actionsService = const CrmOrderActionsService();
  static const _actionWidth = 88.0;
  static const _dialogBackground = Color(0xFFE7E7E7);
  static const _dialogBorder = Color(0xFFC9C9C9);
  static const _dangerRed = Color(0xFFB1121D);

  Widget _leftCell(Widget child) {
    return Align(alignment: Alignment.centerLeft, child: child);
  }

  Widget _column({
    required int flex,
    required Widget child,
  }) {
    return Expanded(flex: flex, child: _leftCell(child));
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  String _infoFolderPath(CrmOrderInProgressItem item) {
    final year = item.orderRef.length >= 4 ? item.orderRef.substring(0, 4) : '';
    return r'Y:\9999 - TECNOLOGIA E SERVIÇOS DE INFORMAÇÃO\040 - DEV\01 - ERP APP\2000 - PROCESSOS'
        r'\'
        '$year'
        r'\'
        '${item.orderRef} - ${item.customerName}'
        r'\000 - DEP.COMERCIAL\00 - Especificações';
  }

  Future<DateTime?> _pickDate(
    BuildContext context, {
    required DateTime? initialValue,
    required String helpText,
  }) async {
    final now = DateTime.now();
    final initialDate =
        initialValue ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: helpText,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _dangerRed,
              onPrimary: Colors.white,
              surface: _dialogBackground,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: _dialogBackground,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: _dialogBackground,
              surfaceTintColor: Colors.transparent,
              dayBackgroundColor: WidgetStatePropertyAll(Colors.transparent),
              todayBackgroundColor: WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return null;
    }

    return DateTime(picked.year, picked.month, picked.day);
  }

  void _invalidatePanels() {
    ref.invalidate(crmOrdersInProgressProvider);
    ref.invalidate(crmSentProposalsProvider);
    ref.invalidate(crmOwnOrdersInProgressProvider);
    ref.invalidate(crmOwnSentProposalsProvider);
    ref.invalidate(budgetingNewOrdersProvider);
    ref.invalidate(budgetingActiveBudgetsProvider);
    ref.invalidate(budgetingMyBudgetsProvider);
  }

  IconData _expectedDeliveryIcon(CrmOrderInProgressItem item) {
    if (!item.hasExpectedDeliveryDate) {
      return Icons.event_busy_outlined;
    }

    if (item.isExpectedDeliveryOverdue) {
      return Icons.warning_amber_rounded;
    }

    if (item.isExpectedDeliverySoon) {
      return Icons.schedule;
    }

    return Icons.check_circle_outline;
  }

  Color _expectedDeliveryColor(
    BuildContext context,
    CrmOrderInProgressItem item,
  ) {
    if (!item.hasExpectedDeliveryDate) {
      return Theme.of(context).colorScheme.outline;
    }

    if (item.isExpectedDeliveryOverdue) {
      return Theme.of(context).colorScheme.error;
    }

    if (item.isExpectedDeliverySoon) {
      return Colors.orange.shade700;
    }

    return Colors.green.shade700;
  }

  Widget _headerRow() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pedido',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Versão',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cliente',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Entrada',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Prev. Entrega',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estado Comercial',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estado Orçamentação',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Orçamentista',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(width: _actionWidth),
        ],
      ),
    );
  }

  Widget _dataRow(
    BuildContext context,
    CrmOrderInProgressItem item,
    List<WorkflowPhaseOption> editableCommercialPhases,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _column(
            flex: 14,
            child: Text(
              item.orderRef,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _column(
            flex: 10,
            child: Text(
              item.versionLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _column(
            flex: 22,
            child: Text(
              item.customerName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _column(
            flex: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _formatDate(item.requestedAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _column(
            flex: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expectedDeliveryIcon(item),
                  size: 16,
                  color: _expectedDeliveryColor(context, item),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _formatDate(item.expectedDeliveryDate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _column(
            flex: 16,
            child: Text(
              item.commercialPhaseName.isEmpty ? '-' : item.commercialPhaseName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _column(
            flex: 16,
            child: Text(
              item.budgetingPhaseName.isEmpty ? '-' : item.budgetingPhaseName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _column(
            flex: 14,
            child: Text(
              item.budgeterName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _actionWidth,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Alterar Estado',
                  onPressed: () => _openEditOrderDialog(
                    context,
                    item,
                    editableCommercialPhases,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  tooltip: item.canSendProposal
                      ? 'Enviar Proposta'
                      : (item.sendProposalBlockReason ?? 'Proposta indisponível'),
                  onPressed: item.canSendProposal
                      ? () => _openSendProposalDialog(context, item)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commercialsAsync = ref.watch(crmCommercialOptionsProvider);
    final phasesAsync = ref.watch(crmCommercialWorkflowPhasesProvider);
    final itemsAsync = widget.useCurrentCommercialOnly
        ? ref.watch(crmOwnOrdersInProgressProvider)
        : ref.watch(crmOrdersInProgressProvider);
    final commercialFilter = ref.watch(crmCommercialFilterProvider);
    final commercialPhaseFilter = ref.watch(crmCommercialPhaseFilterProvider);

    if (commercialsAsync.isLoading || phasesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (commercialsAsync.hasError || phasesAsync.hasError) {
      final error = commercialsAsync.error ?? phasesAsync.error;
      return CrmPanel(
        title: 'Pedidos em curso',
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Erro a carregar comerciais: $error'),
        ),
      );
    }

    final commercials = commercialsAsync.value ?? const [];
    final commercialPhases = phasesAsync.value ?? const [];
    final editableCommercialPhases =
        _actionsService.editableCommercialPhases(commercialPhases);

    return CrmPanel(
      title: 'Pedidos em curso',
      actions: widget.useCurrentCommercialOnly
          ? const []
          : [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            isExpanded: true,
            value: commercialFilter,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Comercial',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos', overflow: TextOverflow.ellipsis),
              ),
              ...commercials.map((commercial) {
                return DropdownMenuItem<String?>(
                  value: commercial.userId,
                  child: Text(
                    commercial.fullName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              ref.read(crmCommercialFilterProvider.notifier).state = value;
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<int?>(
            isExpanded: true,
            value: commercialPhaseFilter,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Estado',
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text(
                  'Todos',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              ...commercialPhases.map((phase) {
                return DropdownMenuItem<int?>(
                  value: phase.id,
                  child: Text(
                    phase.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              ref.read(crmCommercialPhaseFilterProvider.notifier).state = value;
            },
          ),
        ),
      ],
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Erro a carregar pedidos: $error'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Sem pedidos para os filtros atuais.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _headerRow(),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _dataRow(context, item, editableCommercialPhases);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditOrderDialog(
    BuildContext context,
    CrmOrderInProgressItem item,
    List<WorkflowPhaseOption> editableCommercialPhases,
  ) async {
    final orderId = item.orderId;
    int? commercialPhaseId = item.commercialPhaseId;
    DateTime? expectedDeliveryDate = item.expectedDeliveryDate;
    final expectedDeliveryController = TextEditingController(
      text: _formatDate(expectedDeliveryDate),
    );
    String? action;
    final infoFolderPath = _infoFolderPath(item);
    final uploadSupported = CrmProcessFolderHelper.isSupported;
    final initialFolderExists = uploadSupported
        ? await CrmProcessFolderHelper.folderExists(infoFolderPath)
        : false;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var folderExists = initialFolderExists;
        var isDraggingFiles = false;
        var isUploadingFiles = false;
        String? uploadMessage;
        String dragDebugMessage = 'Sem eventos de arrastar.';

        Future<void> uploadFiles(
          List<String> sourcePaths,
          void Function(void Function()) setDialogState,
        ) async {
          if (sourcePaths.isEmpty) {
            return;
          }

          if (!folderExists) {
            setDialogState(() {
              uploadMessage =
                  'A pasta info nao existe: $infoFolderPath';
            });
            return;
          }

          setDialogState(() {
            isUploadingFiles = true;
            uploadMessage = null;
          });

          final copied = await CrmProcessFolderHelper.copyFilesToFolder(
            sourcePaths: sourcePaths,
            targetFolder: infoFolderPath,
          );

          if (!context.mounted) {
            return;
          }

          setDialogState(() {
            isUploadingFiles = false;
            uploadMessage = copied > 0
                ? '$copied ficheiro(s) enviados para a pasta info.'
                : 'Nao foi possivel copiar ficheiros para a pasta info.';
          });
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                  maxHeight: 760,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _dialogBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _dialogBorder,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_outlined),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Editar Pedido',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Pedido',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Theme(
                                data: Theme.of(dialogContext).copyWith(
                                  canvasColor: _dialogBackground,
                                  colorScheme: Theme.of(dialogContext)
                                    .colorScheme
                                    .copyWith(primary: _dangerRed),
                                ),
                                child: DropdownButtonFormField<int?>(
                                  initialValue: commercialPhaseId,
                                  isExpanded: true,
                                  dropdownColor: _dialogBackground,
                                  decoration: const InputDecoration(
                                    labelText: 'Estado Comercial',
                                    prefixIcon: Icon(Icons.flag_outlined),
                                  ),
                                  items: editableCommercialPhases.map((phase) {
                                    return DropdownMenuItem<int?>(
                                      value: phase.id,
                                      child: Text(
                                        phase.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => commercialPhaseId = value,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: expectedDeliveryController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Prev. Entrega',
                                  prefixIcon: Icon(Icons.event_outlined),
                                ),
                                onTap: () async {
                                  final picked = await _pickDate(
                                    dialogContext,
                                    initialValue: expectedDeliveryDate,
                                    helpText:
                                        'Selecionar data prevista de entrega',
                                  );
                                  if (picked == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    expectedDeliveryDate = picked;
                                    expectedDeliveryController.text =
                                        _formatDate(expectedDeliveryDate);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (uploadSupported) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: folderExists
                                      ? () async {
                                          final opened =
                                              await CrmProcessFolderHelper
                                                  .openFolder(infoFolderPath);
                                          if (!context.mounted) {
                                            return;
                                          }
                                          if (!opened) {
                                            setDialogState(() {
                                              uploadMessage =
                                                  'Nao foi possivel abrir a pasta info.';
                                            });
                                          }
                                        }
                                      : null,
                                  icon: Icon(
                                    folderExists
                                        ? Icons.check_circle
                                        : Icons.folder_off_outlined,
                                    color: folderExists
                                        ? Colors.green.shade700
                                        : Colors.grey.shade500,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: folderExists
                                        ? _dangerRed
                                        : Colors.grey.shade500,
                                    side: BorderSide(
                                      color: folderExists
                                          ? _dangerRed
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  label: const Text('Abrir Pasta'),
                                ),
                              ),
                            ],
                          ),
                          if (!folderExists) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Pasta info nao encontrada.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _dangerRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (folderExists) ...[
                            const SizedBox(height: 12),
                            DropTarget(
                              onDragDone: (details) async {
                                debugPrint(
                                  'CRM drop done with ${details.files.length} file(s).',
                                );
                                final paths = details.files
                                    .map((file) => file.path)
                                    .where((path) => path.trim().isNotEmpty)
                                    .toList(growable: false);
                                setDialogState(() {
                                  dragDebugMessage =
                                      'Drop recebido: ${details.files.length} ficheiro(s).';
                                });
                                await uploadFiles(paths, setDialogState);
                                setDialogState(() => isDraggingFiles = false);
                              },
                              onDragEntered: (_) {
                                debugPrint('CRM drop target drag entered.');
                                setDialogState(() {
                                  isDraggingFiles = true;
                                  dragDebugMessage = 'Drag entrou na caixa.';
                                });
                              },
                              onDragExited: (_) {
                                debugPrint('CRM drop target drag exited.');
                                setDialogState(() {
                                  isDraggingFiles = false;
                                  dragDebugMessage = 'Drag saiu da caixa.';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDraggingFiles
                                        ? _dangerRed
                                        : _dialogBorder,
                                    width: isDraggingFiles ? 2 : 1,
                                  ),
                                  color: isDraggingFiles
                                      ? Colors.red.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.22),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.upload_file_outlined,
                                      color: isDraggingFiles
                                          ? _dangerRed
                                          : Colors.black54,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Arrastar ficheiros aqui',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'ou selecionar pela janela do Windows',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Para emails do Outlook, abre a pasta e larga diretamente no Explorer.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: isUploadingFiles
                                          ? null
                                          : () async {
                                              final files =
                                                  await CrmProcessFolderHelper
                                                      .pickFiles();
                                              if (!context.mounted) {
                                                return;
                                              }
                                              await uploadFiles(
                                                files,
                                                setDialogState,
                                              );
                                            },
                                      icon: const Icon(Icons.attach_file_outlined),
                                      label: const Text('Selecionar ficheiros'),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      dragDebugMessage,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isUploadingFiles) ...[
                                      const SizedBox(height: 10),
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (uploadMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            uploadMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: uploadMessage!.contains('enviados')
                                  ? Colors.green.shade800
                                  : _dangerRed,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              action = 'cancel';
                              Navigator.pop(dialogContext, 'cancel');
                            },
                            icon: const Icon(Icons.block_outlined),
                            label: const Text('Anular Pedido'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _dangerRed,
                              side: const BorderSide(color: _dangerRed),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                foregroundColor: _dangerRed,
                              ),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                action = 'save';
                                Navigator.pop(dialogContext, 'save');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _dangerRed,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    expectedDeliveryController.dispose();

    if (result == null || action == null) {
      return;
    }

    final repository = ref.read(crmRepositoryProvider);

    if (action == 'cancel') {
      final cancelValidation = _actionsService.validateOrderCancellation(item);
      if (cancelValidation != null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cancelValidation)));
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: _dialogBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _dialogBorder),
            ),
            title: const Text('Anular pedido'),
            content: Text(
              'Queres mesmo anular o pedido ${item.orderRef}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(foregroundColor: _dangerRed),
                child: const Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dangerRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sim, anular'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      await repository.cancelOrderFromCrm(orderId: orderId);
      _invalidatePanels();
      return;
    }

    final phaseValidation =
        _actionsService.validateCommercialPhaseSelection(commercialPhaseId);
    if (phaseValidation != null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(phaseValidation)));
      return;
    }

    final expectedDeliveryValidation =
        _actionsService.validateExpectedDeliveryDate(expectedDeliveryDate);
    if (expectedDeliveryValidation != null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(expectedDeliveryValidation)));
      return;
    }

    await repository.setOrderCommercialPhase(
      orderId: orderId,
      commercialPhaseId: commercialPhaseId!,
    );
    await repository.updateLatestOrderVersionExpectedDelivery(
      orderId: orderId,
      expectedDeliveryDate: expectedDeliveryDate!,
    );

    _invalidatePanels();
  }

  Future<void> _openSendProposalDialog(
    BuildContext context,
    CrmOrderInProgressItem item,
  ) async {
    final validationMessage = _actionsService.validateProposalId(item);
    if (validationMessage != null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    final proposalId = item.proposalId!;

    final result = await showDialog<CrmSendProposalResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SendProposalDialog(
        orderRef: item.orderRefForProposal,
        proposalId: proposalId,
      ),
    );

    if (result == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enviar proposta'),
          content: Text(
            'Queres enviar a proposta ${item.orderRefForProposal}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final repository = ref.read(crmRepositoryProvider);
    await repository.sendProposal(
      proposalId: proposalId,
      sentAt: result.sentAt,
      feedbackAt: result.feedbackAt,
      validUntil: result.validUntil,
      note: result.note,
    );

    _invalidatePanels();
  }
}
