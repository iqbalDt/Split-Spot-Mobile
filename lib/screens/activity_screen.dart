import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';

class ActivityScreen extends StatefulWidget {
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Scaffold(backgroundColor: AppColors.scaffoldBg, body: Center(child: Text('Silakan login terlebih dahulu', style: GoogleFonts.poppins(color: AppColors.textSecondary))));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text("Riwayat Event", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryDark)),
        backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').where('createdBy', isEqualTo: currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          if (snapshot.hasError) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger.withOpacity(0.6)), const SizedBox(height: 12),
            Text('Gagal memuat riwayat', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textBody)),
          ]));
          final docs = snapshot.data?.docs ?? [];
          final completedDocs = docs.where((d) { final data = d.data() as Map<String, dynamic>; return data['status'] == 'Completed'; }).toList();
          completedDocs.sort((a, b) {
            final aD = a.data() as Map<String, dynamic>; final bD = b.data() as Map<String, dynamic>;
            final aT = aD['createdAt'] as Timestamp?; final bT = bD['createdAt'] as Timestamp?;
            if (aT == null && bT == null) return 0; if (aT == null) return 1; if (bT == null) return -1;
            return bT.compareTo(aT);
          });
          if (completedDocs.isEmpty) return _buildEmptyState();
          return ListView.builder(padding: const EdgeInsets.all(16), itemCount: completedDocs.length, itemBuilder: (c, i) {
            final doc = completedDocs[i]; return _buildActivityCard(c, doc.id, doc.data() as Map<String, dynamic>);
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      child: Icon(Icons.history_rounded, size: 40, color: AppColors.primary.withOpacity(0.5))),
    const SizedBox(height: 16),
    Text('Belum Ada Riwayat', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    const SizedBox(height: 8),
    Text('Event yang sudah selesai akan muncul di sini', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
  ]));

  Widget _buildActivityCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Event'; final location = data['location'] ?? '';
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final totalAmount = (data['totalAmount'] ?? 0).toDouble();
    final totalParticipants = (data['totalParticipants'] ?? 0).toInt();

    return Dismissible(key: Key(docId), direction: DismissDirection.endToStart,
      confirmDismiss: (d) async => await _showDeleteConfirmation(context, name),
      onDismissed: (d) => _deleteEvent(docId, name),
      background: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(gradient: AppGradients.danger, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26), SizedBox(height: 4),
          Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))])),
      child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EventDetailScreen(eventId: docId, eventData: data))),
        child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on, size: 12, color: AppColors.textSecondary), const SizedBox(width: 3),
                Flexible(child: Text(location, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary), const SizedBox(width: 3),
                Text('${date.day} ${_getMonthName(date.month)} ${date.year}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 4),
              Row(children: [Icon(Icons.people_outline, size: 12, color: AppColors.textSecondary), const SizedBox(width: 3),
                Text('$totalParticipants peserta', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Rp ${_formatNumber(totalAmount)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check, size: 12, color: AppColors.primaryDark), const SizedBox(width: 3),
                  Text('Selesai', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark))])),
            ]),
          ])),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext c, String n) => showDialog<bool>(context: c, builder: (dc) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    title: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24), const SizedBox(width: 8), Text('Hapus Event?', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold))]),
    content: Text('Event "$n" akan dihapus permanen dari riwayat. Tindakan ini tidak bisa dibatalkan.', style: GoogleFonts.poppins(color: AppColors.textBody, fontSize: 14)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dc, false), child: Text('Batal', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
      ElevatedButton(onPressed: () => Navigator.pop(dc, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
    ],
  ));

  Future<void> _deleteEvent(String id, String n) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [const Icon(Icons.delete_outline, color: Colors.white, size: 18), const SizedBox(width: 8), Text('Event "$n" berhasil dihapus')]),
        backgroundColor: AppColors.textDark, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppColors.danger)); }
  }

  String _formatNumber(double a) => a.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  String _getMonthName(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][m - 1];
}
