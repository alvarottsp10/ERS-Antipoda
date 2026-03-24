import 'package:flutter/material.dart';

import '../../application/view_budgets_mapper.dart';
import '../dialog/view_proposal_dialog.dart';
import 'budgeting_panel.dart';

class VersionCard extends StatelessWidget {
  const VersionCard({
    super.key,
    required this.version,
    required this.detail,
    required this.expandedVersionId,
    required this.index,
  });

  final Map<String, dynamic> version;
  final Map<String, dynamic> detail;
  final ValueNotifier<String?> expandedVersionId;
  final int index;

  @override
  Widget build(BuildContext context) {
    final data = mapViewBudgetVersionData(version, index);
    final budgeters = readBudgeters(detail);

    debugPrint('VERSION ID: ${version['id']}');
    debugPrint('PROPOSALS RAW: ${version['proposals']}');

    return ValueListenableBuilder<String?>(
      valueListenable: expandedVersionId,
      builder: (context, expandedId, _) {
        final isExpanded = isExpandedVersion(expandedId ?? '', data.versionId);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (data.versionId.isEmpty) {
                return;
              }

              expandedVersionId.value = isExpanded ? null : data.versionId;
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpanded
                      ? const Color(0xFFC94B47)
                      : BudgetingPanel.borderSoft,
                  width: isExpanded ? 1.4 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.versionTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  if (data.dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data.dateLabel,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DetailChip(
                        label:
                            'Valor total: ${formatViewBudgetAmount(data.totalValue)}',
                      ),
                      _DetailChip(
                        label:
                            'Horas totais: ${data.totalHours.toStringAsFixed(2)}h',
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (data.proposalTypology.isNotEmpty)
                          _DetailChip(
                            label: 'Tipologia: ${data.proposalTypology}',
                          ),
                        if (data.proposalProductType.isNotEmpty)
                          _DetailChip(
                            label: 'Produto: ${data.proposalProductType}',
                          ),
                        _DetailChip(
                          label: data.isSpecial ? 'Especial: Sim' : 'Especial: Nao',
                        ),
                        if (data.entryDateLabel != '-')
                          _DetailChip(
                            label: 'Entrada ORC: ${data.entryDateLabel}',
                          ),
                        if (data.exitDateLabel != '-')
                          _DetailChip(
                            label: 'Saida ORC: ${data.exitDateLabel}',
                          ),
                        if (data.phaseLabel.isNotEmpty)
                          _DetailChip(
                            label: 'Fase: ${data.phaseLabel}',
                          ),
                        if (data.isConcluded)
                          const _DetailChip(
                            label: 'Concluida',
                          ),
                      ],
                    ),
                    if (budgeters.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Orcamentistas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: BudgetingPanel.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: budgeters
                            .map(
                              (item) => _DetailChip(
                                label:
                                    '${readViewBudgetText(item['name'])}: ${(((item['hours'] as num?) ?? 0).toDouble()).toStringAsFixed(2)}h',
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    if (data.hasProposal) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            _openProposalDetails(
                              context,
                              data.proposal,
                              data.proposalItems,
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver proposta'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openProposalDetails(
    BuildContext context,
    Map<String, dynamic>? proposal,
    List<Map<String, dynamic>> proposalItems,
  ) {
    if (proposal == null) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => ViewProposalDialog(
        proposalTotalMaterial:
            (proposal['cost_material_total'] as num?)?.toDouble(),
        proposalTotalMO: (proposal['cost_labor_total'] as num?)?.toDouble(),
        proposalTotalProjeto:
            (proposal['cost_project_total'] as num?)?.toDouble(),
        proposalTotalVenda: (proposal['sell_total'] as num?)?.toDouble(),
        proposalMargemPct: ((proposal['margin_pct'] as num?)?.toDouble() ?? 0) / 100,
        proposalEquipmentBlocks: mapProposalItemsForDialog(proposalItems),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BudgetingPanel.borderSoft),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: BudgetingPanel.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
