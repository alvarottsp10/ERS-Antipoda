import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/projeto_repository.dart';

const _kRed = Color(0xFFC0392B);
const _kNavy = Color(0xFF2C3E50);
const _kGrey = Color(0xFFF4F5F7);
const _kBorder = Color(0xFFE0E0E0);
const _kBlue = Color(0xFF2980B9);
const _kOrange = Color(0xFFE67E22);
const _kPurple = Color(0xFF8E44AD);
const _kGreen = Color(0xFF27AE60);
const _kYellow = Color(0xFFF39C12);

const _departments = [
  'projeto',
  'eletrico',
  'desenvolvimento',
  'orcamentacao',
];

const _subcatMap = {
  'projeto': ['Horas Design', 'Doc Aprovação', 'Doc Fabrico', 'Doc Técnica', 'Aditamento', 'Não Conformidade'],
  'eletrico': ['Horas Design', 'Doc Aprovação', 'Doc Fabrico', 'Doc Técnica', 'Aditamento', 'Não Conformidade'],
  'orcamentacao': ['Orçamento', 'Ordem de Produção'],
  'desenvolvimento': [],
};

const _internalCats = ['reuniao', 'formacao', 'outro'];

String _internalCatLabel(String c) {
  switch (c) {
    case 'reuniao': return 'Reunião';
    case 'formacao': return 'Formação';
    default: return 'Outro';
  }
}

String _deptLabel(String d) {
  switch (d) {
    case 'projeto': return 'Projeto';
    case 'eletrico': return 'Elétrico';
    case 'desenvolvimento': return 'Desenvolvimento';
    case 'orcamentacao': return 'Orçamentação';
    default: return d;
  }
}

String _htLabel(String ht) {
  switch (ht) {
    case 'extra': return 'Extra';
    case 'weekend': return 'Fim Semana';
    default: return 'Normal';
  }
}

Color _htColor(String ht) {
  switch (ht) {
    case 'extra': return _kOrange;
    case 'weekend': return _kPurple;
    default: return _kBlue;
  }
}

String _fmtHms(int s) {
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String _fmtHm(int s) {
  if (s <= 0) return '0h 0m';
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  return '${h}h ${m}m';
}

String _fmtDate(DateTime dt) {
  final l = dt.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String _fmtDateTime(DateTime dt) {
  final l = dt.toLocal();
  return '${_fmtDate(l)} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String _orderLabel(Map<String, dynamic> o) {
  final ref = (o['order_ref'] ?? '').toString();
  final customer = (o['customers'] is Map ? o['customers']['name'] : null)?.toString() ?? '';
  return customer.isEmpty ? ref : '$ref — $customer';
}

class ProjetoScreen extends StatefulWidget {
  const ProjetoScreen({super.key});

  @override
  State<ProjetoScreen> createState() => _ProjetoScreenState();
}

class _ProjetoScreenState extends State<ProjetoScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _repo = ProjetoRepository();

  late TabController _tabs;
  int _tabCount = 4;

  bool _isAdmin = false;
  String _userName = '';
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _adminEntries = [];

  bool _loading = true;

  bool _timerRunning = false;
  bool _timerPaused = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  Map<String, dynamic>? _activeTimer;

  String _workType = 'project';
  String _hourType = 'normal';
  Map<String, dynamic>? _selectedOrder;
  String? _selectedDept;
  String? _selectedSubcat;
  String _internalCat = 'reuniao';
  final _internalDescCtrl = TextEditingController();
  final List<String> _meetingOrderIds = [];

  final _histSearchCtrl = TextEditingController();
  String _histWtFilter = 'all';
  String _histHtFilter = 'all';

  String? _adminUserFilter;
  DateTime? _adminFrom;
  DateTime? _adminTo;

  DateTime? _bgPauseTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    final admin = await _repo.isAdmin();
    final name = await _repo.currentUserName();
    final orders = await _repo.fetchOrders();
    final history = await _repo.fetchHistory();

    List<Map<String, dynamic>> users = [];
    List<Map<String, dynamic>> adminEntries = [];

    if (admin) {
      users = await _repo.fetchUsers();
      adminEntries = await _repo.fetchAdminEntries();
    }

    final timer = await _repo.getActiveTimer();

    setState(() {
      _isAdmin = admin;
      _userName = name;
      _orders = orders;
      _history = history;
      _users = users;
      _adminEntries = adminEntries;
      _tabCount = admin ? 5 : 4;
      _loading = false;
    });

    _tabs = TabController(length: _tabCount, vsync: this);

    if (timer != null) {
      _restoreTimer(timer);
    }
  }

  void _restoreTimer(Map<String, dynamic> t) {
    _activeTimer = t;
    _workType = (t['work_type'] ?? 'project') as String;
    _hourType = (t['hour_type'] ?? 'normal') as String;
    _selectedDept = t['department'] as String?;
    _selectedSubcat = t['subcategory'] as String?;
    _internalCat = (t['internal_category'] ?? 'reuniao') as String;
    _internalDescCtrl.text = (t['internal_description'] ?? '') as String;

    if (t['order_id'] != null) {
      try {
        _selectedOrder = _orders.firstWhere((o) => o['id'] == t['order_id']);
      } catch (_) {}
    }

    final isPaused = t['is_paused'] == true;
    _timerRunning = true;
    _timerPaused = isPaused;
    _recalcElapsed(t);

    if (!isPaused) _startTicker();
  }

  void _recalcElapsed(Map<String, dynamic> t) {
    final start = DateTime.parse(t['start_time']);
    final totalPaused = (t['total_paused_seconds'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().toUtc();

    int currentPause = 0;
    if (t['is_paused'] == true && t['paused_at'] != null) {
      currentPause = now.difference(DateTime.parse(t['paused_at'])).inSeconds;
    }

    final elapsed = now.difference(start).inSeconds - totalPaused - currentPause;
    setState(() => _elapsedSeconds = elapsed < 0 ? 0 : elapsed);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeTimer != null && !_timerPaused) {
        _recalcElapsed(_activeTimer!);
      }
    });
  }

  Future<void> _startTimer() async {
    if (_workType == 'project' && _selectedOrder == null) {
      _snack('Seleciona uma obra primeiro.');
      return;
    }
    if (_workType == 'internal' && _internalDescCtrl.text.trim().isEmpty) {
      _snack('Adiciona uma descrição.');
      return;
    }

    await _repo.startTimer(
      workType: _workType,
      hourType: _hourType,
      orderId: _selectedOrder?['id'] as String?,
      department: _selectedDept,
      subcategory: _selectedSubcat,
      internalCategory: _workType == 'internal' ? _internalCat : null,
      internalDescription: _workType == 'internal' ? _internalDescCtrl.text.trim() : null,
      relatedOrderIds: _meetingOrderIds,
    );

    final t = await _repo.getActiveTimer();
    setState(() {
      _activeTimer = t;
      _timerRunning = true;
      _timerPaused = false;
      _elapsedSeconds = 0;
    });
    _startTicker();
  }

  Future<void> _pauseTimer() async {
    _ticker?.cancel();
    await _repo.pauseTimer();
    final t = await _repo.getActiveTimer();
    setState(() {
      _activeTimer = t;
      _timerPaused = true;
    });
  }

  Future<void> _resumeTimer() async {
    final totalPaused = (_activeTimer?['total_paused_seconds'] as num?)?.toInt() ?? 0;
    await _repo.resumeTimer(totalPaused);
    final t = await _repo.getActiveTimer();
    setState(() {
      _activeTimer = t;
      _timerPaused = false;
    });
    _startTicker();
  }

  Future<void> _stopTimer() async {
    _ticker?.cancel();
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminar sessão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Duração: ${_fmtHm(_elapsedSeconds)}'),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Terminar')),
        ],
      ),
    );

    if (confirmed != true) {
      if (!_timerPaused) _startTicker();
      return;
    }

    await _repo.stopTimer(notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
    final history = await _repo.fetchHistory();
    setState(() {
      _activeTimer = null;
      _timerRunning = false;
      _timerPaused = false;
      _elapsedSeconds = 0;
      _history = history;
      _selectedOrder = null;
      _selectedDept = null;
      _selectedSubcat = null;
      _internalDescCtrl.clear();
      _meetingOrderIds.clear();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _bgPauseTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_bgPauseTime != null && _timerRunning && !_timerPaused && _workType == 'project') {
        final diff = DateTime.now().difference(_bgPauseTime!);
        if (diff.inMinutes >= 5) {
          _ticker?.cancel();
          _repo.pauseTimer().then((_) async {
            final t = await _repo.getActiveTimer();
            setState(() {
              _activeTimer = t;
              _timerPaused = true;
            });
            if (mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Timer pausado'),
                  content: const Text('A app esteve em segundo plano mais de 5 minutos. O timer foi pausado automaticamente.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ok')),
                  ],
                ),
              );
            }
          });
        }
      }
      _bgPauseTime = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _internalDescCtrl.dispose();
    _histSearchCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!_loading) _tabs.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _calcPeriodSeconds(DateTime from, DateTime to) {
    return _history.where((e) {
      final st = DateTime.parse(e['start_time']);
      return st.isAfter(from) && st.isBefore(to);
    }).fold(0, (sum, e) => sum + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
  }

  List<Map<String, dynamic>> get _filteredHistory {
    final q = _histSearchCtrl.text.toLowerCase();
    return _history.where((e) {
      if (_histWtFilter != 'all' && e['work_type'] != _histWtFilter) return false;
      if (_histHtFilter != 'all' && e['hour_type'] != _histHtFilter) return false;
      if (q.isNotEmpty) {
        final order = (e['orders'] is Map ? e['orders']['order_ref'] : null)?.toString().toLowerCase() ?? '';
        final dept = (e['department'] ?? '').toString().toLowerCase();
        final notes = (e['notes'] ?? '').toString().toLowerCase();
        final desc = (e['internal_description'] ?? '').toString().toLowerCase();
        if (!order.contains(q) && !dept.contains(q) && !notes.contains(q) && !desc.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<Map<String, dynamic>> entries) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      final key = _fmtDate(DateTime.parse(e['start_time']).toLocal());
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildHeader(),
        if (_timerRunning) _buildTimerBanner(),
        Expanded(
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildTabRegistar(),
                    _buildTabHistorico(),
                    _buildTabDados(),
                    _buildTabObras(),
                    if (_isAdmin) _buildTabEquipa(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.engineering_outlined, color: _kNavy, size: 22),
          const SizedBox(width: 10),
          const Text('Projeto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kNavy)),
          const Spacer(),
          if (_userName.isNotEmpty)
            Text(_userName, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTimerBanner() {
    final color = _timerPaused ? _kOrange : _kRed;
    final label = _timerPaused ? 'PAUSADO' : 'EM TRABALHO';
    String title = '';
    if (_workType == 'project' && _selectedOrder != null) {
      title = _orderLabel(_selectedOrder!);
    } else if (_workType == 'internal') {
      title = _internalCatLabel(_internalCat);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(width: 8),
                    Text(_fmtHms(_elapsedSeconds),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
                if (title.isNotEmpty)
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_timerPaused)
            _BannerBtn(icon: Icons.play_arrow, color: _kGreen, onTap: _resumeTimer)
          else
            _BannerBtn(icon: Icons.pause, color: _kOrange, onTap: _pauseTimer),
          const SizedBox(width: 6),
          _BannerBtn(icon: Icons.stop, color: _kRed, onTap: _stopTimer),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _kRed,
        unselectedLabelColor: Colors.black54,
        indicatorColor: _kRed,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          const Tab(text: 'Registar'),
          const Tab(text: 'Histórico'),
          const Tab(text: 'Dados'),
          const Tab(text: 'Obras'),
          if (_isAdmin) const Tab(text: 'Equipa'),
        ],
      ),
    );
  }

  Widget _buildTabRegistar() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final todaySecs = _calcPeriodSeconds(todayStart, now);
    final weekSecs = _calcPeriodSeconds(weekStart, now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Hoje', value: _fmtHm(todaySecs + (_timerRunning ? _elapsedSeconds : 0)))),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Esta Semana', value: _fmtHm(weekSecs + (_timerRunning ? _elapsedSeconds : 0)))),
            ],
          ),
          const SizedBox(height: 20),
          if (!_timerRunning) _buildWorkForm(),
          if (_timerRunning)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Timer em curso — usa o banner acima para pausar ou terminar.',
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _ToggleBtn(label: 'Projeto', icon: Icons.work_outline, active: _workType == 'project', onTap: () => setState(() { _workType = 'project'; }))),
            const SizedBox(width: 10),
            Expanded(child: _ToggleBtn(label: 'Interno', icon: Icons.group_outlined, active: _workType == 'internal', onTap: () => setState(() { _workType = 'internal'; }))),
          ],
        ),
        const SizedBox(height: 16),

        if (_workType == 'project') ...[
          _label('Obra'),
          const SizedBox(height: 6),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedOrder,
            isExpanded: true,
            decoration: _inputDeco('Selecionar obra...'),
            items: _orders.map((o) => DropdownMenuItem(value: o, child: Text(_orderLabel(o), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _selectedOrder = v),
          ),
          const SizedBox(height: 12),
          _label('Departamento'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedDept,
            isExpanded: true,
            decoration: _inputDeco('Selecionar departamento...'),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('—')),
              ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(_deptLabel(d)))),
            ],
            onChanged: (v) => setState(() {
              _selectedDept = v;
              _selectedSubcat = null;
            }),
          ),
          if (_selectedDept != null && (_subcatMap[_selectedDept] ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            _label('Subcategoria'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedSubcat,
              isExpanded: true,
              decoration: _inputDeco('Selecionar subcategoria...'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('—')),
                ...(_subcatMap[_selectedDept!] ?? []).map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() => _selectedSubcat = v),
            ),
          ],
        ],

        if (_workType == 'internal') ...[
          _label('Categoria'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _internalCat,
            isExpanded: true,
            decoration: _inputDeco(''),
            items: _internalCats.map((c) => DropdownMenuItem(value: c, child: Text(_internalCatLabel(c)))).toList(),
            onChanged: (v) => setState(() => _internalCat = v ?? 'outro'),
          ),
          const SizedBox(height: 12),
          _label('Descrição'),
          const SizedBox(height: 6),
          TextField(
            controller: _internalDescCtrl,
            maxLines: 3,
            decoration: _inputDeco('Descreve a actividade...'),
          ),
          if (_internalCat == 'reuniao') ...[
            const SizedBox(height: 12),
            _label('Obras relacionadas (opcional)'),
            const SizedBox(height: 6),
            ..._orders.map((o) {
              final oid = o['id'] as String;
              final selected = _meetingOrderIds.contains(oid);
              return CheckboxListTile(
                dense: true,
                value: selected,
                title: Text(_orderLabel(o), style: const TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() {
                  if (v == true) _meetingOrderIds.add(oid);
                  else _meetingOrderIds.remove(oid);
                }),
              );
            }),
          ],
        ],

        const SizedBox(height: 20),
        _label('Tipo de Horas'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _HtBtn(label: 'Normal', value: 'normal', current: _hourType, onTap: () => setState(() => _hourType = 'normal'))),
            const SizedBox(width: 8),
            Expanded(child: _HtBtn(label: 'Extra', value: 'extra', current: _hourType, onTap: () => setState(() => _hourType = 'extra'))),
            const SizedBox(width: 8),
            Expanded(child: _HtBtn(label: 'Fim Semana', value: 'weekend', current: _hourType, onTap: () => setState(() => _hourType = 'weekend'))),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ],
    );
  }

  Widget _buildTabHistorico() {
    final filtered = _filteredHistory;
    final grouped = _groupByDate(filtered);
    final dates = grouped.keys.toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _histSearchCtrl,
                      decoration: _inputDeco('Pesquisar...', icon: Icons.search),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showManualEntryDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Manual'),
                    style: OutlinedButton.styleFrom(foregroundColor: _kNavy),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _histWtFilter,
                      decoration: _inputDeco('Tipo'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todos')),
                        DropdownMenuItem(value: 'project', child: Text('Projeto')),
                        DropdownMenuItem(value: 'internal', child: Text('Interno')),
                      ],
                      onChanged: (v) => setState(() => _histWtFilter = v ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _histHtFilter,
                      decoration: _inputDeco('Horas'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todas')),
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'extra', child: Text('Extra')),
                        DropdownMenuItem(value: 'weekend', child: Text('F. Semana')),
                      ],
                      onChanged: (v) => setState(() => _histHtFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Sem registos.', style: TextStyle(color: Colors.black45)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: dates.length,
                  itemBuilder: (_, di) {
                    final date = dates[di];
                    final entries = grouped[date]!;
                    final dayTotal = entries.fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Text(date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kNavy)),
                              const Spacer(),
                              Text(_fmtHm(dayTotal), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                        ...entries.map((e) => _EntryCard(
                          entry: e,
                          onDelete: () async {
                            final ok = await _confirmDelete();
                            if (!ok) return;
                            await _repo.deleteEntry(e['id'] as String);
                            final h = await _repo.fetchHistory();
                            setState(() => _history = h);
                          },
                          onTap: () => _showEditEntry(e),
                        )),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabDados() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PeriodStatsCard(label: 'Hoje', entries: _history, from: todayStart, to: now),
          const SizedBox(height: 12),
          _PeriodStatsCard(label: 'Esta Semana', entries: _history, from: weekStart, to: now),
          const SizedBox(height: 12),
          _PeriodStatsCard(label: 'Este Mês', entries: _history, from: monthStart, to: now),
        ],
      ),
    );
  }

  Widget _buildTabObras() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (_, i) {
        final o = _orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: _kNavy, child: Icon(Icons.work_outline, color: Colors.white, size: 18)),
            title: Text((o['order_ref'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text((o['customers'] is Map ? o['customers']['name'] : '')?.toString() ?? ''),
            trailing: const Icon(Icons.chevron_right, color: Colors.black38),
            onTap: () => _showOrderHours(o),
          ),
        );
      },
    );
  }

  Widget _buildTabEquipa() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _adminUserFilter,
                      isExpanded: true,
                      decoration: _inputDeco('Utilizador'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                        ..._users.map((u) => DropdownMenuItem<String?>(
                          value: u['user_id'] as String,
                          child: Text((u['full_name'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (v) async {
                        setState(() => _adminUserFilter = v);
                        await _reloadAdmin();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickAdminDates(),
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(_adminFrom != null ? '${_fmtDate(_adminFrom!)} – ${_adminTo != null ? _fmtDate(_adminTo!) : '…'}' : 'Período'),
                    style: OutlinedButton.styleFrom(foregroundColor: _kNavy),
                  ),
                  if (_adminFrom != null) ...[
                    const SizedBox(width: 6),
                    IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () async {
                      setState(() { _adminFrom = null; _adminTo = null; });
                      await _reloadAdmin();
                    }),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${_adminEntries.length} registos · ${_fmtHm(_adminEntries.fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0)))}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('CSV'),
                    style: TextButton.styleFrom(foregroundColor: _kNavy),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _adminEntries.isEmpty
              ? const Center(child: Text('Sem registos.', style: TextStyle(color: Colors.black45)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _adminEntries.length,
                  itemBuilder: (_, i) => _AdminEntryTile(entry: _adminEntries[i]),
                ),
        ),
      ],
    );
  }

  Future<void> _reloadAdmin() async {
    final entries = await _repo.fetchAdminEntries(userId: _adminUserFilter, from: _adminFrom, to: _adminTo);
    setState(() => _adminEntries = entries);
  }

  Future<void> _pickAdminDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _adminFrom != null && _adminTo != null ? DateTimeRange(start: _adminFrom!, end: _adminTo!) : null,
    );
    if (range == null) return;
    setState(() { _adminFrom = range.start; _adminTo = range.end; });
    await _reloadAdmin();
  }

  void _exportCsv() {
    final rows = <String>['Data,Utilizador,Tipo,Horas,Obra,Departamento,Subcategoria,Descrição,Duração,Notas'];
    for (final e in _adminEntries) {
      final date = _fmtDateTime(DateTime.parse(e['start_time']));
      final user = (e['profiles'] is Map ? e['profiles']['full_name'] : '')?.toString() ?? '';
      final wt = e['work_type'] == 'project' ? 'Projeto' : 'Interno';
      final ht = _htLabel(e['hour_type'] ?? 'normal');
      final order = (e['orders'] is Map ? e['orders']['order_ref'] : '')?.toString() ?? '';
      final dept = e['department'] ?? '';
      final subcat = e['subcategory'] ?? '';
      final desc = e['internal_description'] ?? '';
      final dur = _fmtHm((e['duration_seconds'] as num?)?.toInt() ?? 0);
      final notes = (e['notes'] ?? '').toString().replaceAll(',', ';');
      rows.add('"$date","$user","$wt","$ht","$order","$dept","$subcat","$desc","$dur","$notes"');
    }
    Clipboard.setData(ClipboardData(text: rows.join('\n')));
    _snack('CSV copiado para o clipboard.');
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registo'),
        content: const Text('Tens a certeza que queres eliminar este registo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showOrderHours(Map<String, dynamic> order) async {
    final entries = await _repo.fetchOrderHours(order['id'] as String);
    if (!mounted) return;

    final total = entries.fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
    final byDept = <String, int>{};
    for (final e in entries) {
      final d = (e['department'] ?? 'N/A') as String;
      byDept[d] = (byDept[d] ?? 0) + ((e['duration_seconds'] as num?)?.toInt() ?? 0);
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_orderLabel(order)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(_fmtHm(total), style: const TextStyle(fontWeight: FontWeight.w700, color: _kRed)),
                ],
              ),
              if (byDept.isNotEmpty) ...[
                const Divider(height: 20),
                const Align(alignment: Alignment.centerLeft, child: Text('Por departamento', style: TextStyle(fontSize: 12, color: Colors.black54))),
                const SizedBox(height: 8),
                ...byDept.entries.map((kv) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_deptLabel(kv.key), style: const TextStyle(fontSize: 13)),
                      Text(_fmtHm(kv.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }

  void _showEditEntry(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (_) => _EntryEditDialog(
        entry: entry,
        orders: _orders,
        onSave: (data) async {
          await _repo.updateEntry(
            entryId: entry['id'] as String,
            workType: data['workType'],
            hourType: data['hourType'],
            orderId: data['orderId'],
            department: data['department'],
            subcategory: data['subcategory'],
            internalCategory: data['internalCategory'],
            internalDescription: data['internalDescription'],
            startTime: data['startTime'],
            endTime: data['endTime'],
            notes: data['notes'],
          );
          final h = await _repo.fetchHistory();
          setState(() => _history = h);
        },
      ),
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (_) => _EntryEditDialog(
        entry: null,
        orders: _orders,
        onSave: (data) async {
          await _repo.addManualEntry(
            workType: data['workType'],
            hourType: data['hourType'],
            orderId: data['orderId'],
            department: data['department'],
            subcategory: data['subcategory'],
            internalCategory: data['internalCategory'],
            internalDescription: data['internalDescription'],
            startTime: data['startTime'],
            endTime: data['endTime'],
            notes: data['notes'],
          );
          final h = await _repo.fetchHistory();
          setState(() => _history = h);
        },
      ),
    );
  }

  InputDecoration _inputDeco(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon, size: 18) : null,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
  );

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kNavy));
}

class _BannerBtn extends StatelessWidget {
  const _BannerBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.label, required this.icon, required this.active, required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? _kNavy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _kNavy : _kBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _HtBtn extends StatelessWidget {
  const _HtBtn({required this.label, required this.value, required this.current, required this.onTap});
  final String label, value, current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    final color = _htColor(value);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : _kBorder, width: active ? 1.5 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? color : Colors.black54))),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kNavy)),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onDelete, required this.onTap});
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isProject = entry['work_type'] == 'project';
    final ht = (entry['hour_type'] ?? 'normal') as String;
    final dur = (entry['duration_seconds'] as num?)?.toInt() ?? 0;

    String title;
    String subtitle;
    if (isProject) {
      final dept = entry['department'] != null ? _deptLabel(entry['department']) : '';
      final order = (entry['orders'] is Map ? entry['orders']['order_ref'] : '')?.toString() ?? '';
      title = [dept, order].where((s) => s.isNotEmpty).join(' · ');
      subtitle = entry['subcategory'] ?? '';
    } else {
      title = _internalCatLabel((entry['internal_category'] ?? 'outro') as String);
      subtitle = (entry['internal_description'] ?? '') as String;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isProject ? _kNavy.withOpacity(0.08) : _kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(isProject ? Icons.work_outline : Icons.group_outlined,
                  size: 18, color: isProject ? _kNavy : _kGreen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.isEmpty ? '—' : title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
                  if (entry['notes'] != null && (entry['notes'] as String).isNotEmpty)
                    Text(entry['notes'] as String, style: const TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmtHm(dur), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kNavy)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _htColor(ht).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(_htLabel(ht), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _htColor(ht))),
                ),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black26),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminEntryTile extends StatelessWidget {
  const _AdminEntryTile({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final user = (entry['profiles'] is Map ? entry['profiles']['full_name'] : '')?.toString() ?? '';
    final isProject = entry['work_type'] == 'project';
    final ht = (entry['hour_type'] ?? 'normal') as String;
    final dur = (entry['duration_seconds'] as num?)?.toInt() ?? 0;
    final order = (entry['orders'] is Map ? entry['orders']['order_ref'] : '')?.toString() ?? '';
    final dept = entry['department'] != null ? _deptLabel(entry['department']) : '';
    final desc = (entry['internal_description'] ?? '') as String;
    final date = _fmtDateTime(DateTime.parse(entry['start_time']));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _kNavy.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(user, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kNavy)),
                    ),
                    const SizedBox(width: 8),
                    Text(date, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isProject ? [dept, order].where((s) => s.isNotEmpty).join(' · ') : '${_internalCatLabel((entry['internal_category'] ?? 'outro') as String)}${desc.isNotEmpty ? ' — $desc' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmtHm(dur), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kNavy)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _htColor(ht).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                child: Text(_htLabel(ht), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _htColor(ht))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodStatsCard extends StatelessWidget {
  const _PeriodStatsCard({required this.label, required this.entries, required this.from, required this.to});
  final String label;
  final List<Map<String, dynamic>> entries;
  final DateTime from, to;

  @override
  Widget build(BuildContext context) {
    final period = entries.where((e) {
      final st = DateTime.parse(e['start_time']);
      return st.isAfter(from) && st.isBefore(to);
    }).toList();

    final total = period.fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
    final project = period.where((e) => e['work_type'] == 'project').fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
    final internal = total - project;
    final normal = period.where((e) => e['hour_type'] == 'normal').fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
    final extra = period.where((e) => e['hour_type'] == 'extra').fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));
    final weekend = period.where((e) => e['hour_type'] == 'weekend').fold(0, (s, e) => s + ((e['duration_seconds'] as num?)?.toInt() ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kNavy)),
              const Spacer(),
              Text(_fmtHm(total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _kRed)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            const Text('Tipo de trabalho', style: TextStyle(fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 6),
            Row(
              children: [
                _MiniStat(label: 'Projeto', value: _fmtHm(project), color: _kNavy),
                const SizedBox(width: 10),
                _MiniStat(label: 'Interno', value: _fmtHm(internal), color: _kGreen),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Tipo de horas', style: TextStyle(fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 6),
            Row(
              children: [
                _MiniStat(label: 'Normal', value: _fmtHm(normal), color: _kBlue),
                const SizedBox(width: 8),
                _MiniStat(label: 'Extra', value: _fmtHm(extra), color: _kOrange),
                const SizedBox(width: 8),
                _MiniStat(label: 'F.Semana', value: _fmtHm(weekend), color: _kPurple),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Sem registos neste período.', style: TextStyle(color: Colors.black38, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _EntryEditDialog extends StatefulWidget {
  const _EntryEditDialog({required this.entry, required this.orders, required this.onSave});
  final Map<String, dynamic>? entry;
  final List<Map<String, dynamic>> orders;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_EntryEditDialog> createState() => _EntryEditDialogState();
}

class _EntryEditDialogState extends State<_EntryEditDialog> {
  String _workType = 'project';
  String _hourType = 'normal';
  Map<String, dynamic>? _order;
  String? _dept;
  String? _subcat;
  String _internalCat = 'reuniao';
  late TextEditingController _descCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _descCtrl = TextEditingController(text: e?['internal_description'] as String? ?? '');
    _notesCtrl = TextEditingController(text: e?['notes'] as String? ?? '');

    if (e != null) {
      _workType = (e['work_type'] ?? 'project') as String;
      _hourType = (e['hour_type'] ?? 'normal') as String;
      _dept = e['department'] as String?;
      _subcat = e['subcategory'] as String?;
      _internalCat = (e['internal_category'] ?? 'reuniao') as String;
      _start = DateTime.parse(e['start_time']).toLocal();
      _end = DateTime.parse(e['end_time']).toLocal();
      if (e['order_id'] != null) {
        try { _order = widget.orders.firstWhere((o) => o['id'] == e['order_id']); } catch (_) {}
      }
    } else {
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, now.day, now.hour, 0);
      _end = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() { if (isStart) _start = dt; else _end = dt; });
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.entry == null;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isNew ? 'Registo Manual' : 'Editar Registo',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kNavy)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _ToggleBtn(label: 'Projeto', icon: Icons.work_outline, active: _workType == 'project', onTap: () => setState(() => _workType = 'project'))),
                    const SizedBox(width: 10),
                    Expanded(child: _ToggleBtn(label: 'Interno', icon: Icons.group_outlined, active: _workType == 'internal', onTap: () => setState(() => _workType = 'internal'))),
                  ],
                ),
                const SizedBox(height: 14),

                if (_workType == 'project') ...[
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _order,
                    isExpanded: true,
                    decoration: _deco('Obra'),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>>(value: null, child: Text('—')),
                      ...widget.orders.map((o) => DropdownMenuItem(value: o, child: Text(_orderLabel(o), overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _order = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _dept,
                    isExpanded: true,
                    decoration: _deco('Departamento'),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('—')),
                      ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(_deptLabel(d)))),
                    ],
                    onChanged: (v) => setState(() { _dept = v; _subcat = null; }),
                  ),
                  if (_dept != null && (_subcatMap[_dept] ?? []).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _subcat,
                      isExpanded: true,
                      decoration: _deco('Subcategoria'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('—')),
                        ...(_subcatMap[_dept!] ?? []).map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) => setState(() => _subcat = v),
                    ),
                  ],
                ],

                if (_workType == 'internal') ...[
                  DropdownButtonFormField<String>(
                    value: _internalCat,
                    isExpanded: true,
                    decoration: _deco('Categoria'),
                    items: _internalCats.map((c) => DropdownMenuItem(value: c, child: Text(_internalCatLabel(c)))).toList(),
                    onChanged: (v) => setState(() => _internalCat = v ?? 'outro'),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _descCtrl, maxLines: 2, decoration: _deco('Descrição')),
                ],

                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _HtBtn(label: 'Normal', value: 'normal', current: _hourType, onTap: () => setState(() => _hourType = 'normal'))),
                  const SizedBox(width: 8),
                  Expanded(child: _HtBtn(label: 'Extra', value: 'extra', current: _hourType, onTap: () => setState(() => _hourType = 'extra'))),
                  const SizedBox(width: 8),
                  Expanded(child: _HtBtn(label: 'F.Semana', value: 'weekend', current: _hourType, onTap: () => setState(() => _hourType = 'weekend'))),
                ]),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(true),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(_fmtDateTime(_start), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDateTime(false),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(_fmtDateTime(_end), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Duração: ${_fmtHm(_end.difference(_start).inSeconds.abs())}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 14),
                TextField(controller: _notesCtrl, maxLines: 2, decoration: _deco('Notas (opcional)')),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                    const Spacer(),
                    FilledButton(
                      onPressed: _saving ? null : () async {
                        setState(() => _saving = true);
                        Navigator.pop(context);
                        widget.onSave({
                          'workType': _workType,
                          'hourType': _hourType,
                          'orderId': _order?['id'] as String?,
                          'department': _dept,
                          'subcategory': _subcat,
                          'internalCategory': _workType == 'internal' ? _internalCat : null,
                          'internalDescription': _workType == 'internal' ? _descCtrl.text.trim() : null,
                          'startTime': _start.toUtc(),
                          'endTime': _end.toUtc(),
                          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                        });
                      },
                      style: FilledButton.styleFrom(backgroundColor: _kRed),
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
  }
}