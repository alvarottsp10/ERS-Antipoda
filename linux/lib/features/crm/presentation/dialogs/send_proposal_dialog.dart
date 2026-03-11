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

  DateTime? _sentAt;
  DateTime? _feedbackAt;
  DateTime? _validUntil;

  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    _sentAt = DateTime(today.year, today.month, today.day);
    _validUntil = _sentAt!.add(const Duration(days: 30));
    _feedbackAt = null;
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
                            'Enviar Proposta — ${widget.orderRef}',
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
                      controller: TextEditingController(text: _fmtDate(_sentAt)),
                      decoration: const InputDecoration(
                        labelText: 'Data de Envio',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      validator: (_) => _sentAt == null ? 'Obrigatório' : null,
                      onTap: () => _pickDate(
                        context,
                        _sentAt,
                        (value) => setState(() => _sentAt = value),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _fmtDate(_feedbackAt)),
                      decoration: const InputDecoration(
                        labelText: 'Data de Feedback',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      validator: (_) => _feedbackAt == null ? 'Obrigatório' : null,
                      onTap: () => _pickDate(
                        context,
                        _feedbackAt,
                        (value) => setState(() => _feedbackAt = value),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: _fmtDate(_validUntil)),
                      decoration: const InputDecoration(
                        labelText: 'Validade da Proposta',
                        prefixIcon: Icon(Icons.date_range_outlined),
                      ),
                      validator: (_) => _validUntil == null ? 'Obrigatório' : null,
                      onTap: () => _pickDate(
                        context,
                        _validUntil,
                        (value) => setState(() => _validUntil = value),
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
                            if (!_formKey.currentState!.validate()) return;
                            Navigator.of(context).pop({
                              'proposal_id': widget.proposalId,
                              'sent_at': _sentAt,
                              'feedback_at': _feedbackAt,
                              'valid_until': _validUntil,
                              'note': _noteCtrl.text.trim(),
                            });
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