import 'package:flutter/material.dart';

class ViewProposalDialog extends StatelessWidget {
  const ViewProposalDialog({
    super.key,
    this.proposalFileName,
    this.proposalTotalMaterial,
    this.proposalTotalMO,
    this.proposalTotalProjeto,
    this.proposalTotalVenda,
    this.proposalMargemPct,
    this.proposalEquipmentBlocks = const [],
  });

  final String? proposalFileName;
  final double? proposalTotalMaterial;
  final double? proposalTotalMO;
  final double? proposalTotalProjeto;
  final double? proposalTotalVenda;
  final double? proposalMargemPct;
  final List<Map<String, dynamic>> proposalEquipmentBlocks;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE7E7E7),
      surfaceTintColor: Colors.transparent,
      title: const Text('Proposta ativa'),
      content: SizedBox(
        width: 920,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((proposalFileName ?? '').trim().isNotEmpty) ...[
              Text(
                proposalFileName!,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'TOTAL MATERIAL: ${_formatAmount(proposalTotalMaterial)}',
            ),
            Text(
              'TOTAL M.O.: ${_formatAmount(proposalTotalMO)}',
            ),
            Text(
              'TOTAL PROJETO: ${_formatAmount(proposalTotalProjeto)}',
            ),
            Text(
              'VALOR VENDA: ${_formatAmount(proposalTotalVenda)}',
            ),
            const SizedBox(height: 6),
            Text(
              'MARGEM (%): ${_formatMargin(proposalMargemPct)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Equipamentos',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (proposalEquipmentBlocks.isEmpty)
              const Text(
                'Sem equipamentos disponiveis para visualizar.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: proposalEquipmentBlocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = proposalEquipmentBlocks[index];
                    final attributes =
                        Map<String, dynamic>.from(
                          (item['detected_attributes'] as Map?) ?? const {},
                        );

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCFCFCF)),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          title: Text(
                            _readText(item['main_equipment'], '(sem equipamento)'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            _readText(item['main_description'], '(sem descricao)'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quantidade: ${_readText(item['quantity'], '-')}',
                                  ),
                                  Text(
                                    'Custo total: ${_formatAmount(_readDouble(item['cost_total']))}',
                                  ),
                                  Text(
                                    'Margem: ${_formatMargin(_readDouble(item['margin']))}',
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Caracteristicas',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  if (attributes.isEmpty)
                                    const Text('Sem caracteristicas detetadas.')
                                  else
                                    ...attributes.entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '${_readText(entry.key, '-').toUpperCase()}: ${_readText(entry.value, '-')}',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  String _formatAmount(double? value) {
    if (value == null) {
      return '-';
    }
    return value.toStringAsFixed(2);
  }

  String _formatMargin(double? value) {
    if (value == null) {
      return '-';
    }
    return '${(value * 100).toStringAsFixed(2)}%';
  }

  String _readText(dynamic value, String fallback) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(
      text.replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.'),
    );
  }
}
