import 'dart:io' as io;
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../../application/budgeting_excel_parser.dart';
import '../../data/budgeting_repository.dart';

class _EditableBudgetEquipmentBlock {
  _EditableBudgetEquipmentBlock({
    required this.mainEquipment,
    required this.mainDescription,
    required this.quantity,
    required this.costTotal,
    required this.margin,
    required this.detectedAttributes,
  });

  factory _EditableBudgetEquipmentBlock.fromRaw(BudgetEquipmentBlock block) {
    return _EditableBudgetEquipmentBlock(
      mainEquipment: block.mainEquipment,
      mainDescription: block.mainDescription,
      quantity: block.quantity,
      costTotal: block.costTotal,
      margin: block.margin,
      detectedAttributes: Map<String, String>.from(block.detectedAttributes),
    );
  }

  String mainEquipment;
  String mainDescription;
  String quantity;
  double costTotal;
  double margin;
  Map<String, String> detectedAttributes;

  Map<String, dynamic> toMap() {
    return {
      'main_equipment': mainEquipment,
      'main_description': mainDescription,
      'quantity': quantity,
      'cost_total': costTotal,
      'margin': margin,
      'detected_attributes': detectedAttributes,
    };
  }
}

class UploadProposalDialog extends StatefulWidget {
  const UploadProposalDialog({
    super.key,
    required this.orderVersionId,
    required this.orderRef,
  });

  final String orderVersionId;
  final String orderRef;

  @override
  State<UploadProposalDialog> createState() => _UploadProposalDialogState();
}

class _UploadProposalDialogState extends State<UploadProposalDialog> {
  final _repository = BudgetingRepository();

  bool _picking = false;
  bool _submitting = false;
  bool _dragHover = false;

  DropzoneViewController? _dz;

  String? _fileName;
  int? _fileSize;
  Uint8List? _fileBytes;

  double? _totalMaterial;
  double? _totalMO;
  double? _totalProjeto;
  double? _totalVenda;
  double? _margemPct;
  List<BudgetEquipmentBlock> _equipmentBlocks = const [];
  List<_EditableBudgetEquipmentBlock> _editableEquipmentBlocks = const [];

  bool get _hasFile => _fileBytes != null && (_fileBytes?.isNotEmpty ?? false);

  static const String _sheetResumo = 'Resumo';
  static const String _cellTotalMaterial = 'D9';
  static const String _cellTotalMO = 'D10';
  static const String _cellTotalProjeto = 'D11';
  static const String _cellTotalVenda = 'D22';

  void _closeDialog([Map<String, dynamic>? result]) {
    if (!mounted) {
      return;
    }

    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || route == null || !route.isCurrent) {
        return;
      }
      navigator.pop(result);
    });
  }


  Future<void> _submitImport() async {
    if (_submitting || !_hasFile || _margemPct == null) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final equipmentBlocks = _editableEquipmentBlocks
          .map((item) => item.toMap())
          .toList(growable: false);
      final response = await _repository.importProposalFromExcel(
        orderVersionId: widget.orderVersionId,
        fileName: _fileName,
        totalMaterial: _totalMaterial,
        totalMo: _totalMO,
        totalProjeto: _totalProjeto,
        totalVenda: _totalVenda,
        margemPct: _margemPct,
        equipmentBlocks: equipmentBlocks,
      );

      if (!mounted) {
        return;
      }

      _closeDialog({
        'file_name': _fileName,
        'total_material': _totalMaterial,
        'total_mo': _totalMO,
        'total_projeto': _totalProjeto,
        'total_venda': _totalVenda,
        'margem_pct': _margemPct,
        'equipment_blocks': equipmentBlocks,
        ...response,
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar proposta: $error')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _pickExcel() async {
    setState(() => _picking = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xlsm'],
        withData: true,
      );

      if (res == null || res.files.isEmpty) {
        setState(() => _picking = false);
        return;
      }

      final f = res.files.first;
      final bytes = f.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('N\u00e3o foi poss\u00edvel ler o ficheiro.')),
        );
        setState(() => _picking = false);
        return;
      }

      setState(() {
        _fileName = f.name;
        _fileSize = f.size;
        _fileBytes = bytes;
        _picking = false;
      });

      await _parseResumoAndComputeMargin();
      final decoder = SpreadsheetDecoder.decodeBytes(_fileBytes!, update: false);
      _loadBudgetBlocks(decoder);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar ficheiro: $e')),
      );
      setState(() => _picking = false);
    }
  }

  String _fmtSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    final normalized =
        s.replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  (int row, int col) _a1ToIndex(String a1) {
    final m = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(a1.trim());
    if (m == null) return (0, 0);

    final colLetters = m.group(1)!.toUpperCase();
    final rowNumber = int.parse(m.group(2)!);

    int col = 0;
    for (int i = 0; i < colLetters.length; i++) {
      col = col * 26 + (colLetters.codeUnitAt(i) - 64);
    }
    col -= 1;
    final row = rowNumber - 1;
    return (row, col);
  }

  double? _readCellDoubleFromRows(List<List<dynamic>> rows, String a1) {
    final (r, c) = _a1ToIndex(a1);
    if (r < 0 || c < 0) return null;
    if (r >= rows.length) return null;
    final row = rows[r];
    if (c >= row.length) return null;
    return _toDouble(row[c]);
  }

  Future<void> _parseResumoAndComputeMargin() async {
    final bytes = _fileBytes;
    if (bytes == null || bytes.isEmpty) return;

    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
      final table = decoder.tables[_sheetResumo];

      if (table == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folha "Resumo" n\u00e3o encontrada no Excel.')),
        );
        return;
      }

      final rows = table.rows;

      final totalMaterial = _readCellDoubleFromRows(rows, _cellTotalMaterial);
      final totalMO = _readCellDoubleFromRows(rows, _cellTotalMO);
      final totalProjeto = _readCellDoubleFromRows(rows, _cellTotalProjeto);
      final totalVenda = _readCellDoubleFromRows(rows, _cellTotalVenda);

      if (totalMaterial == null ||
          totalMO == null ||
          totalProjeto == null ||
          totalVenda == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'N\u00e3o foi poss\u00edvel ler os totais. Confirma as c\u00e9lulas (D9/D10/D11/D22).',
            ),
          ),
        );
        return;
      }

      final somaCustos = totalMaterial + totalMO + totalProjeto;
      final margemPct = 1 - (somaCustos / totalVenda);

      if (!mounted) return;
      setState(() {
        _totalMaterial = totalMaterial;
        _totalMO = totalMO;
        _totalProjeto = totalProjeto;
        _totalVenda = totalVenda;
        _margemPct = margemPct;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro a ler Excel: $e')),
      );
    }
  }

  void _loadBudgetBlocks(SpreadsheetDecoder decoder) {
    final bounds = resolveBudgetSheetBounds(
      decoder,
      widget.orderRef,
    );

    if (bounds == null) {
      if (!mounted) return;
      setState(() {
        _equipmentBlocks = const [];
        _editableEquipmentBlocks = const [];
      });
      return;
    }

    final blocks = extractBudgetEquipmentBlocks(decoder, bounds);

    if (!mounted) return;
    setState(() {
      _equipmentBlocks = blocks;
      _editableEquipmentBlocks = blocks
          .map(_EditableBudgetEquipmentBlock.fromRaw)
          .toList(growable: false);
    });
  }

  String _formatDecimal(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE7E7E7),
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: (_picking || _submitting) ? null : _closeDialog,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 6),
          const Expanded(child: Text('Carregar proposta (Excel)')),
        ],
      ),
      content: SizedBox(
        width: 920,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.orderRef.isEmpty ? '(sem refer\u00eancia)' : widget.orderRef,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _dragHover
                      ? Colors.white.withOpacity(0.55)
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dragHover
                        ? Colors.blueGrey
                        : const Color(0xFFC9C9C9),
                    width: _dragHover ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DropzoneView(
                        onCreated: (c) => _dz = c,
                        onHover: () => setState(() => _dragHover = true),
                        onLeave: () => setState(() => _dragHover = false),
                        onDropFile: (file) async {
                          if (_dz == null) return;

                          setState(() {
                            _picking = true;
                            _dragHover = false;
                          });

                          try {
                            final name = await _dz!.getFilename(file);
                            final size = await _dz!.getFileSize(file);
                            final mime = await _dz!.getFileMIME(file);

                            final lower = name.toLowerCase();
                            final isExcel = lower.endsWith('.xlsx') ||
                                lower.endsWith('.xlsm') ||
                                mime.contains('spreadsheet') ||
                                mime.contains('excel');

                            if (!isExcel) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Formato inv\u00e1lido ($mime). Usa .xlsx ou .xlsm',
                                  ),
                                ),
                              );
                              setState(() => _picking = false);
                              return;
                            }

                            final bytes = await _dz!.getFileData(file);
                            if (bytes.isEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('N\u00e3o foi poss\u00edvel ler o ficheiro.'),
                                ),
                              );
                              setState(() => _picking = false);
                              return;
                            }

                            setState(() {
                              _fileName = name;
                              _fileSize = size;
                              _fileBytes = bytes;
                              _picking = false;
                            });

                            await _parseResumoAndComputeMargin();
                            final decoder = SpreadsheetDecoder.decodeBytes(
                              _fileBytes!,
                              update: false,
                            );
                            _loadBudgetBlocks(decoder);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro no drag&drop: $e')),
                            );
                            setState(() => _picking = false);
                          }
                        },
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.upload_file_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasFile
                                ? 'Selecionado: ${_fileName ?? '-'} (${_fmtSize(_fileSize)})'
                                : 'Arrasta um .xlsx/.xlsm para aqui ou usa o bot\u00e3o',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _picking ? null : _pickExcel,
                          child: _picking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_hasFile ? 'Trocar' : 'Escolher ficheiro'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              DropTarget(
                onDragEntered: (_) => setState(() => _dragHover = true),
                onDragExited: (_) => setState(() => _dragHover = false),
                onDragDone: (detail) async {
                  if (detail.files.isEmpty) return;

                  final f = detail.files.first;
                  final name = f.name;
                  final lower = name.toLowerCase();
                  final isExcel =
                      lower.endsWith('.xlsx') || lower.endsWith('.xlsm');

                  if (!isExcel) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Formato inv\u00e1lido. Usa .xlsx ou .xlsm'),
                      ),
                    );
                    setState(() => _dragHover = false);
                    return;
                  }

                  setState(() {
                    _picking = true;
                    _dragHover = false;
                  });

                  try {
                    final bytes = await io.File(f.path).readAsBytes();
                    if (bytes.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('N\u00e3o foi poss\u00edvel ler o ficheiro.'),
                        ),
                      );
                      setState(() => _picking = false);
                      return;
                    }

                    setState(() {
                      _fileName = name;
                      _fileSize = bytes.length;
                      _fileBytes = bytes;
                      _picking = false;
                    });

                    await _parseResumoAndComputeMargin();
                    final decoder = SpreadsheetDecoder.decodeBytes(
                      _fileBytes!,
                      update: false,
                    );
                    _loadBudgetBlocks(decoder);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro no drag&drop: $e')),
                    );
                    setState(() => _picking = false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _dragHover
                        ? Colors.white.withOpacity(0.55)
                        : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dragHover
                          ? Colors.blueGrey
                          : const Color(0xFFC9C9C9),
                      width: _dragHover ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasFile
                              ? 'Selecionado: ${_fileName ?? '-'} (${_fmtSize(_fileSize)})'
                              : 'Arrasta um .xlsx/.xlsm para aqui ou usa o bot\u00e3o',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _picking ? null : _pickExcel,
                        child: _picking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_hasFile ? 'Trocar' : 'Escolher ficheiro'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_margemPct != null) ...[
              Text('TOTAL MATERIAL: ${_totalMaterial?.toStringAsFixed(2)}'),
              Text('TOTAL M.O.: ${_totalMO?.toStringAsFixed(2)}'),
              Text('TOTAL PROJETO: ${_totalProjeto?.toStringAsFixed(2)}'),
              Text('VALOR VENDA: ${_totalVenda?.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              Text(
                'MARGEM (%): ${(100 * (_margemPct ?? 0)).toStringAsFixed(2)}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ] else
              const Text(
                'Carrega um Excel para calcular a margem (%).',
                style: TextStyle(color: Colors.black54, fontSize: 12.5),
              ),
            if (_editableEquipmentBlocks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Preview de equipamentos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _editableEquipmentBlocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _editableEquipmentBlocks[index];
                    final attributeKeys = item.detectedAttributes.keys.toList(
                      growable: false,
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
                            item.mainEquipment.trim().isEmpty
                                ? '(sem equipamento)'
                                : item.mainEquipment.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            item.mainDescription.trim().isEmpty
                                ? '(sem descricao)'
                                : item.mainDescription.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          children: [
                            TextFormField(
                              initialValue: item.mainEquipment,
                              decoration: const InputDecoration(
                                labelText: 'Equipamento',
                              ),
                              onChanged: (value) {
                                setState(() => item.mainEquipment = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue: item.mainDescription,
                              decoration: const InputDecoration(
                                labelText: 'Descricao',
                              ),
                              minLines: 2,
                              maxLines: 3,
                              onChanged: (value) {
                                setState(() => item.mainDescription = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.quantity,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantidade',
                                    ),
                                    onChanged: (value) {
                                      setState(() => item.quantity = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _formatDecimal(item.costTotal),
                                    decoration: const InputDecoration(
                                      labelText: 'Custo total',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (value) {
                                      final parsed = _toDouble(value);
                                      if (parsed == null) {
                                        return;
                                      }
                                      setState(() => item.costTotal = parsed);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _formatDecimal(item.margin * 100),
                                    decoration: const InputDecoration(
                                      labelText: 'Margem %',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (value) {
                                      final parsed = _toDouble(value);
                                      if (parsed == null) {
                                        return;
                                      }
                                      setState(() => item.margin = parsed / 100);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Caracteristicas',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (attributeKeys.isEmpty)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Sem caracteristicas detetadas.'),
                              )
                            else
                              ...attributeKeys.map((key) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TextFormField(
                                    initialValue: item.detectedAttributes[key],
                                    decoration: InputDecoration(labelText: key),
                                    onChanged: (value) {
                                      setState(() {
                                        item.detectedAttributes[key] = value;
                                      });
                                    },
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_picking || _submitting) ? null : _closeDialog,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_picking || _submitting || !_hasFile || _margemPct == null)
              ? null
              : _submitImport,
          child: Text(_submitting ? 'A importar...' : 'Continuar'),
        ),
      ],
    );
  }
}
