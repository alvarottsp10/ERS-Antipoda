import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class BudgetSheetBounds {
  const BudgetSheetBounds({
    required this.sheetName,
    required this.startRow,
    required this.endRow,
  });

  final String sheetName;
  final int startRow; // 0-based
  final int endRow; // 0-based, inclusive

  @override
  String toString() {
    return 'BudgetSheetBounds(sheetName: $sheetName, startRow: $startRow, endRow: $endRow)';
  }
}

class BudgetEquipmentBlock {
  const BudgetEquipmentBlock({
    required this.linStart,
    required this.linEnd,
    required this.mainRow,
    required this.mainClass,
    required this.mainEquipment,
    required this.mainDescription,
    required this.quantity,
    required this.unitSaleValue,
    required this.totalSaleValue,
    required this.costTotal,
    required this.margin,
    required this.detectedAttributes,
  });

  final int linStart; // 0-based
  final int linEnd; // 0-based, inclusive
  final int mainRow; // 0-based
  final String mainClass; // coluna D
  final String mainEquipment; // coluna E
  final String mainDescription; // coluna G
  final String quantity; // coluna H
  final String unitSaleValue; // coluna Z
  final String totalSaleValue; // coluna AA
  final double costTotal;
  final double margin;
  final Map<String, String> detectedAttributes;

  @override
  String toString() {
    return 'BudgetEquipmentBlock(linStart: $linStart, linEnd: $linEnd, mainRow: $mainRow, mainClass: $mainClass, mainEquipment: $mainEquipment, mainDescription: $mainDescription, quantity: $quantity, unitSaleValue: $unitSaleValue, totalSaleValue: $totalSaleValue, detectedAttributes: $detectedAttributes)';
  }
}

List<BudgetEquipmentBlock> extractBudgetEquipmentBlocks(
  SpreadsheetDecoder decoder,
  BudgetSheetBounds bounds,
) {
  final table = decoder.tables[bounds.sheetName];
  if (table == null) {
    return const [];
  }

  final rows = table.rows;
  if (rows.isEmpty) {
    return const [];
  }

  final blocks = <BudgetEquipmentBlock>[];
  int currentStart = bounds.startRow;

  for (int row = bounds.startRow; row <= bounds.endRow; row++) {
    if (_isBreakRow(rows, row)) {
      final blockEnd = row - 1;
      final block = _buildEquipmentBlock(rows, currentStart, blockEnd);
      if (block != null) {
        blocks.add(block);
      }
      currentStart = row + 1;
    }
  }

  final lastBlock = _buildEquipmentBlock(rows, currentStart, bounds.endRow);
  if (lastBlock != null) {
    blocks.add(lastBlock);
  }

  return blocks;
}

BudgetEquipmentBlock? _buildEquipmentBlock(
  List<List<dynamic>> rows,
  int startRow,
  int endRow,
) {
  if (endRow < startRow) {
    return null;
  }

  final mainRow = _findFirstNonEmptyRowInRange(rows, startRow, endRow);
  if (mainRow == null) {
    return null;
  }

  final costTotal = _calculateBlockCost(rows, startRow, endRow);
  final saleTotal = double.tryParse(_safeCellString(rows, mainRow, 26)) ?? 0;

  double margin = 0;
  if (saleTotal > 0) {
    margin = 1 - (costTotal / saleTotal);
  }

  final mainDescription = _safeCellString(rows, mainRow, 6);

  return BudgetEquipmentBlock(
    linStart: startRow,
    linEnd: endRow,
    mainRow: mainRow,
    mainClass: _safeCellString(rows, mainRow, 3), // D
    mainEquipment: _safeCellString(rows, mainRow, 4), // E
    mainDescription: mainDescription, // G
    quantity: _safeCellString(rows, mainRow, 7), // H
    unitSaleValue: _safeCellString(rows, mainRow, 25), // Z
    totalSaleValue: _safeCellString(rows, mainRow, 26), // AA
    costTotal: costTotal,
    margin: margin,
    detectedAttributes: _extractDetectedAttributes(mainDescription),
  );
}

Map<String, String> _extractDetectedAttributes(String description) {
  final text = description.trim();
  if (text.isEmpty) {
    return const {};
  }

  final matches = RegExp(
    r'\b([A-Za-z][A-Za-z0-9_]*)\s*[:=]\s*(.+?)(?=(?:\s+[A-Za-z][A-Za-z0-9_]*\s*[:=])|[,;]|$)',
    caseSensitive: false,
  ).allMatches(text);

  final attributes = <String, String>{};
  for (final match in matches) {
    final key = match.group(1)?.trim().toUpperCase() ?? '';
    final value = match.group(2)?.trim() ?? '';
    if (key.isEmpty || value.isEmpty) {
      continue;
    }
    attributes[key] = value;
  }

  return attributes;
}

int? _findFirstNonEmptyRowInRange(
  List<List<dynamic>> rows,
  int startRow,
  int endRow,
) {
  for (int row = startRow; row <= endRow; row++) {
    final d = _safeCellString(rows, row, 3);
    final e = _safeCellString(rows, row, 4);
    final g = _safeCellString(rows, row, 6);

    if (d.isNotEmpty || e.isNotEmpty || g.isNotEmpty) {
      return row;
    }
  }

  return null;
}

double _calculateBlockCost(
  List<List<dynamic>> rows,
  int startRow,
  int endRow,
) {
  double total = 0;

  for (int row = startRow; row <= endRow; row++) {
    final value = _safeCell(rows, row, 15); // coluna P

    if (value is num) {
      total += value.toDouble();
    } else if (value != null) {
      final parsed = double.tryParse(value.toString());
      if (parsed != null) {
        total += parsed;
      }
    }
  }

  return total;
}

bool _isBreakRow(List<List<dynamic>> rows, int row) {
  return _safeCellString(rows, row, 3).toUpperCase() == 'BREAK';
}

BudgetSheetBounds? resolveBudgetSheetBounds(
  SpreadsheetDecoder decoder,
  String orderRef,
) {
  final sheetName = _detectBudgetSheetName(decoder, orderRef);
  if (sheetName == null) {
    return null;
  }

  final table = decoder.tables[sheetName];
  if (table == null) {
    return null;
  }

  final rows = table.rows;

  const startRow = 8;

  int? endRow = _findEndRowByTotalEquipamentos(rows);
  endRow ??= _findLastBreakRow(rows);

  if (endRow == null || endRow < startRow) {
    return null;
  }

  return BudgetSheetBounds(
    sheetName: sheetName,
    startRow: startRow,
    endRow: endRow,
  );
}

String? _detectBudgetSheetName(
  SpreadsheetDecoder decoder,
  String orderRef,
) {
  final sheetNames = decoder.tables.keys.toList();
  if (sheetNames.isEmpty) return null;

  final normalizedOrder =
      _normalizeProcessNameWithoutVersion(orderRef).toLowerCase();

  for (final name in sheetNames) {
    if (name.trim().toLowerCase() == normalizedOrder) {
      return name;
    }
  }

  if (sheetNames.length >= 2) {
    return sheetNames[1];
  }

  String? bestSheet;
  int bestScore = -1;

  for (final entry in decoder.tables.entries) {
    final name = entry.key;
    final rows = entry.value.rows;

    if (name.trim().toLowerCase() == 'resumo') continue;

    int score = 0;

    if (rows.length > 8) {
      final d9 = _safeCellString(rows, 8, 3).toUpperCase();
      final e9 = _safeCellString(rows, 8, 4);
      final g9 = _safeCellString(rows, 8, 6);

      if (d9.isNotEmpty) score += 2;
      if (e9.isNotEmpty) score += 2;
      if (g9.isNotEmpty) score += 1;
    }

    for (int i = 0; i < rows.length; i++) {
      final d = _safeCellString(rows, i, 3).toUpperCase();
      final v = _safeCellString(rows, i, 21).toUpperCase();

      if (d == 'BREAK') score += 3;
      if (v == 'TOTAL EQUIPAMENTOS') score += 10;
    }

    if (score > bestScore) {
      bestScore = score;
      bestSheet = name;
    }
  }

  return bestSheet;
}

int? _findEndRowByTotalEquipamentos(List<List<dynamic>> rows) {
  for (int i = 0; i < rows.length; i++) {
    final v = _safeCellString(rows, i, 21).toUpperCase();
    if (v == 'TOTAL EQUIPAMENTOS') {
      return i - 2;
    }
  }
  return null;
}

int? _findLastBreakRow(List<List<dynamic>> rows) {
  int? lastBreak;
  for (int i = 0; i < rows.length; i++) {
    final d = _safeCellString(rows, i, 3).toUpperCase();
    if (d == 'BREAK') {
      lastBreak = i;
    }
  }
  return lastBreak;
}

String _normalizeProcessNameWithoutVersion(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return s;

  final parts = s.split(' ');
  if (parts.isNotEmpty) {
    final last = parts.last.trim();
    if (RegExp(r'^[A-Za-z]$').hasMatch(last)) {
      parts.removeLast();
      s = parts.join(' ');
    }
  }

  return s.trim();
}

dynamic _safeCell(List<List<dynamic>> rows, int row, int col) {
  if (row < 0 || row >= rows.length) return null;
  final r = rows[row];
  if (col < 0 || col >= r.length) return null;
  return r[col];
}

String _safeCellString(List<List<dynamic>> rows, int row, int col) {
  final v = _safeCell(rows, row, col);
  return v?.toString().trim() ?? '';
}
