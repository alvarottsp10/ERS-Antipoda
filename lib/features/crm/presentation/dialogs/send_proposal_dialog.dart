import 'package:erp_app/features/crm/application/crm_send_proposal_models.dart';
import 'package:erp_app/features/crm/application/crm_send_proposal_service.dart';
import 'package:flutter/material.dart';

class SendProposalDialog extends StatefulWidget {
  const SendProposalDialog({
    super.key,
    required this.orderRef,
    required this.proposalId,
  });

  final String orderRef;
  final String proposalId;

  @override
  State<SendProposalDialog> createState() => _SendProposalDialogState();
}

class _SendProposalDialogState extends State<SendProposalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = const CrmSendProposalService();
  final _noteCtrl = TextEditingController();

  late CrmSendProposalDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = _service.createInitialDraft(
      proposalId: widget.proposalId,
      orderRef: widget.orderRef,
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? currentValue,
    ValueChanged<DateTime> onPicked,
  ) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      onPicked(picked);
    }
  }

  String _fmtDate(DateTime? value) {
    if (value == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFE7E7E7);
    const border = Color(0xFFC9C9C9);
    const textDark = Color(0xFF151515);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.send_rounded, color: textDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enviar Proposta - ${widget.orderRef}',
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _SendProposalSectionTitle('Envio'),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _fmtDate(_draft.sentAt),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Data de Envio',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      validator: (_) => _service.validateSentAt(_draft.sentAt),
                      onTap: () => _pickDate(
                        context,
                        _draft.sentAt,
                        (value) => setState(() {
                          _draft = _draft.copyWith(sentAt: value);
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _fmtDate(_draft.feedbackAt),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Data de Feedback',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      validator: (_) =>
                          _service.validateFeedbackAt(_draft.feedbackAt),
                      onTap: () => _pickDate(
                        context,
                        _draft.feedbackAt,
                        (value) => setState(() {
                          _draft = _draft.copyWith(feedbackAt: value);
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _fmtDate(_draft.validUntil),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Validade da Proposta',
                        prefixIcon: Icon(Icons.date_range_outlined),
                      ),
                      validator: (_) =>
                          _service.validateValidUntil(_draft.validUntil),
                      onTap: () => _pickDate(
                        context,
                        _draft.validUntil,
                        (value) => setState(() {
                          _draft = _draft.copyWith(validUntil: value);
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Nota de acompanhamento (opcional)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            final result = _service.buildResult(
                              _draft.copyWith(note: _noteCtrl.text),
                            );

                            Navigator.of(context).pop(result);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB7E4C7),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
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
        ),
      ),
    );
  }
}

class _SendProposalSectionTitle extends StatelessWidget {
  const _SendProposalSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF151515),
      ),
    );
  }
}
