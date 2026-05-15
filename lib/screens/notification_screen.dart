import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';

enum NotifCategory { payment, completed, progress, info }

class NotifItem {
  final String id, title, description, eventId; final NotifCategory category; final DateTime timestamp;
  final Map<String, dynamic> eventData; final IconData icon; final Color color;
  NotifItem({required this.id, required this.title, required this.description, required this.category, required this.timestamp, required this.eventId, required this.eventData, required this.icon, required this.color});
}

class NotificationScreen extends StatefulWidget {
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Semua';
  final Map<String, DateTime> _dismissedNotifs = {};
  late AnimationController _emptyAnimCtrl;
  final List<Map<String, dynamic>> _filters = [
    {'label': 'Semua', 'icon': Icons.all_inbox_rounded}, {'label': 'Pembayaran', 'icon': Icons.payment_rounded},
    {'label': 'Selesai', 'icon': Icons.check_circle_outline_rounded}, {'label': 'Info', 'icon': Icons.info_outline_rounded},
  ];

  @override
  void initState() { super.initState(); _loadDismissed(); _emptyAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true); }
  Future<void> _loadDismissed() async {
    final p = await SharedPreferences.getInstance();
    setState(() { for (final k in p.getKeys().where((k) => k.startsWith('dismissed_'))) { final t = p.getString(k); if (t != null) { final d = DateTime.tryParse(t); if (d != null) _dismissedNotifs[k.replaceFirst('dismissed_', '')] = d; } } });
  }
  Future<void> _saveDismissed(String id) async { final p = await SharedPreferences.getInstance(); final n = DateTime.now(); await p.setString('dismissed_$id', n.toIso8601String()); setState(() { _dismissedNotifs[id] = n; }); }
  Future<void> _resetDismissed() async { final p = await SharedPreferences.getInstance(); for (final k in p.getKeys().where((k) => k.startsWith('dismissed_'))) { await p.remove(k); } setState(() { _dismissedNotifs.clear(); }); }
  @override
  void dispose() { _emptyAnimCtrl.dispose(); super.dispose(); }

  List<NotifItem> _gen(List<QueryDocumentSnapshot> docs) {
    final List<NotifItem> n = []; final now = DateTime.now();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>; final eid = doc.id; final en = data['name'] ?? 'Event';
      final st = data['status'] ?? 'Active'; final ca = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
      final ps = (data['participants'] as List?) ?? []; final pc = (data['paidCount'] ?? 0).toInt(); final tp = (data['totalParticipants'] ?? ps.length).toInt();
      if (st == 'Active') {
        for (final p in ps) { if (p is Map<String, dynamic> && p['isPaid'] != true) {
          final nm = p['name'] ?? 'Peserta'; final am = (p['amount'] ?? 0).toDouble();
          final dur = now.difference(ca); final dt = _fmtDur(dur); final urg = dur.inDays >= 3;
          n.add(NotifItem(id: '${eid}_unpaid_$nm', title: '$nm belum membayar', description: 'Belum membayar Rp ${_fmtNum(am)} untuk "$en" selama $dt',
            category: NotifCategory.payment, timestamp: ca, eventId: eid, eventData: data,
            icon: urg ? Icons.warning_amber_rounded : Icons.access_time_rounded, color: urg ? AppColors.danger : AppColors.warning));
        }}
        if (pc > 0 && pc < tp) n.add(NotifItem(id: '${eid}_progress', title: 'Progres pembayaran "$en"', description: '$pc dari $tp peserta sudah membayar',
          category: NotifCategory.progress, timestamp: ca, eventId: eid, eventData: data, icon: Icons.trending_up_rounded, color: AppColors.warning));
      }
      if (st == 'Completed') n.add(NotifItem(id: '${eid}_completed', title: 'Event "$en" selesai! 🎉', description: 'Semua $tp peserta sudah membayar. Terima kasih!',
        category: NotifCategory.completed, timestamp: ca, eventId: eid, eventData: data, icon: Icons.celebration_rounded, color: AppColors.primary));
      n.add(NotifItem(id: '${eid}_created', title: 'Event "$en" dibuat', description: 'Event dengan $tp peserta di ${data['location'] ?? 'lokasi'}',
        category: NotifCategory.info, timestamp: ca, eventId: eid, eventData: data, icon: Icons.event_available_rounded, color: AppColors.info));
    }
    n.sort((a, b) { if (a.category == NotifCategory.payment && b.category != NotifCategory.payment) return -1; if (b.category == NotifCategory.payment && a.category != NotifCategory.payment) return 1; return b.timestamp.compareTo(a.timestamp); });
    return n;
  }

  List<NotifItem> _filter(List<NotifItem> items) {
    final now = DateTime.now();
    final f = items.where((n) { if (_dismissedNotifs.containsKey(n.id)) { if (now.difference(_dismissedNotifs[n.id]!).inHours < 6) return false; } return true; }).toList();
    if (_selectedFilter == 'Semua') return f;
    if (_selectedFilter == 'Pembayaran') return f.where((n) => n.category == NotifCategory.payment || n.category == NotifCategory.progress).toList();
    if (_selectedFilter == 'Selesai') return f.where((n) => n.category == NotifCategory.completed).toList();
    if (_selectedFilter == 'Info') return f.where((n) => n.category == NotifCategory.info).toList();
    return f;
  }

  Map<String, List<NotifItem>> _group(List<NotifItem> items) {
    final now = DateTime.now(); final td = DateTime(now.year, now.month, now.day);
    final yd = td.subtract(const Duration(days: 1)); final wa = td.subtract(const Duration(days: 7));
    final Map<String, List<NotifItem>> g = {};
    for (final i in items) { final d = DateTime(i.timestamp.year, i.timestamp.month, i.timestamp.day);
      String gr; if (d.isAtSameMomentAs(td) || d.isAfter(td)) gr = 'Hari Ini'; else if (d.isAtSameMomentAs(yd)) gr = 'Kemarin'; else if (d.isAfter(wa)) gr = 'Minggu Ini'; else gr = 'Lebih Lama';
      g.putIfAbsent(gr, () => []); g[gr]!.add(i);
    } return g;
  }

  String _fmtDur(Duration d) { if (d.inDays > 0) return '${d.inDays} hari'; if (d.inHours > 0) return '${d.inHours} jam'; if (d.inMinutes > 0) return '${d.inMinutes} menit'; return 'baru saja'; }
  String _fmtNum(double a) => a.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  String _timeAgo(DateTime dt) { final d = DateTime.now().difference(dt); if (d.inDays > 30) return '${(d.inDays / 30).floor()} bln lalu'; if (d.inDays > 0) return '${d.inDays} hari lalu'; if (d.inHours > 0) return '${d.inHours} jam lalu'; if (d.inMinutes > 0) return '${d.inMinutes} mnt lalu'; return 'Baru saja'; }

  @override
  Widget build(BuildContext context) {
    final cu = FirebaseAuth.instance.currentUser;
    if (cu == null) return Scaffold(backgroundColor: AppColors.scaffoldBg, body: Center(child: Text('Silakan login terlebih dahulu', style: GoogleFonts.poppins(color: AppColors.textSecondary))));
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('Notifikasi', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryDark)),
        backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
        actions: [if (_dismissedNotifs.isNotEmpty) IconButton(icon: Icon(Icons.refresh_rounded, size: 22, color: AppColors.textSecondary), tooltip: 'Reset notifikasi', onPressed: _resetDismissed)]),
      body: Column(children: [
        // Filter chips
        Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _filters.map((f) {
            final sel = _selectedFilter == f['label'];
            return Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
              avatar: Icon(f['icon'] as IconData, size: 16, color: sel ? Colors.white : AppColors.textSecondary),
              label: Text(f['label'] as String, style: GoogleFonts.poppins(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Colors.white : AppColors.textBody)),
              selected: sel, onSelected: (_) => setState(() => _selectedFilter = f['label'] as String),
              backgroundColor: AppColors.scaffoldBg, selectedColor: AppColors.primary, checkmarkColor: Colors.white, showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: sel ? AppColors.primary : AppColors.border)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ));
          }).toList()))),
        // List
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').where('createdBy', isEqualTo: cu.uid).snapshots(),
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            if (s.hasError) return _errState();
            final docs = s.data?.docs ?? []; if (docs.isEmpty) return _emptyState();
            final all = _gen(docs); final filtered = _filter(all); if (filtered.isEmpty) return _emptyState();
            final grouped = _group(filtered); final order = ['Hari Ini', 'Kemarin', 'Minggu Ini', 'Lebih Lama'];
            return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: grouped.entries.fold<int>(0, (s, e) => s + 1 + e.value.length),
              itemBuilder: (c, index) {
                int cursor = 0;
                for (final gn in order) { if (!grouped.containsKey(gn)) continue; final items = grouped[gn]!;
                  if (index == cursor) return _sectionHeader(gn); cursor++;
                  if (index < cursor + items.length) return _notifCard(items[index - cursor]); cursor += items.length;
                } return const SizedBox.shrink();
              });
          },
        )),
      ]),
    );
  }

  Widget _sectionHeader(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Row(children: [
    Text(t, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
    const SizedBox(width: 8), Expanded(child: Container(height: 1, color: AppColors.border)),
  ]));

  Widget _notifCard(NotifItem item) {
    final suf = _dismissedNotifs[item.id]?.millisecondsSinceEpoch ?? 0;
    return Dismissible(key: Key('${item.id}_$suf'), direction: DismissDirection.endToStart,
      onDismissed: (_) => _saveDismissed(item.id),
      background: Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(gradient: AppGradients.danger, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24)),
      child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: item.eventId, eventData: item.eventData))),
        child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: item.color.withOpacity(0.15)), boxShadow: AppShadows.soft),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(item.icon, color: item.color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8), Text(_timeAgo(item.timestamp), style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 4),
              Text(item.description, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textBody, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (item.category == NotifCategory.payment) ...[const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule_rounded, size: 12, color: item.color), const SizedBox(width: 4),
                    Text(item.color == AppColors.danger ? 'Mendesak' : 'Menunggu', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: item.color))]))],
            ])),
            Padding(padding: const EdgeInsets.only(top: 10, left: 4), child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint)),
          ]))),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    AnimatedBuilder(animation: _emptyAnimCtrl, builder: (c, ch) => Transform.translate(offset: Offset(0, -8 * _emptyAnimCtrl.value), child: ch),
      child: Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
        child: Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary.withOpacity(0.5)))),
    const SizedBox(height: 20),
    Text('Belum ada notifikasi', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    const SizedBox(height: 8),
    Text('Notifikasi akan muncul saat ada event\ndengan pembayaran tertunda', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
  ]));

  Widget _errState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger.withOpacity(0.6)),
    const SizedBox(height: 12),
    Text('Gagal memuat notifikasi', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textBody)),
  ]));
}
