import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('=== HomeScreen: currentUser UID = ${currentUser?.uid} ===');
    if (currentUser == null) return Scaffold(backgroundColor: AppColors.scaffoldBg, body: Center(child: Text('Silakan login terlebih dahulu', style: GoogleFonts.poppins(color: AppColors.textSecondary))));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true, pinned: false, snap: true, expandedHeight: 110, backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0,
          flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 16), title: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Halo, ${currentUser.displayName?.split(' ').first ?? 'User'} 👋', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400)),
            Text('Event Saya', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ])),
        ),
        SliverToBoxAdapter(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').where('createdBy', isEqualTo: currentUser.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
            if (snapshot.hasError) {
              debugPrint('=== Firestore Error: ${snapshot.error} ===');
              return SizedBox(height: 300, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.danger.withOpacity(0.6)),
                const SizedBox(height: 16),
                Text('Gagal memuat event', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Text('${snapshot.error}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
              ])));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return SizedBox(height: 400, child: _buildEmptyState());
            docs.sort((a, b) {
              final aD = a.data() as Map<String, dynamic>; final bD = b.data() as Map<String, dynamic>;
              final aT = aD['createdAt'] as Timestamp?; final bT = bD['createdAt'] as Timestamp?;
              if (aT == null && bT == null) return 0; if (aT == null) return 1; if (bT == null) return -1;
              return bT.compareTo(aT);
            });
            final activeDocs = docs.where((d) { final data = d.data() as Map<String, dynamic>; return data['status'] != 'Completed'; }).toList();
            if (activeDocs.isEmpty) return SizedBox(height: 400, child: _buildEmptyState());
            return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: activeDocs.length,
              itemBuilder: (c, i) { final id = activeDocs[i].id; final data = activeDocs[i].data() as Map<String, dynamic>; return _buildEventCard(c, id, data, i); });
          },
        )),
      ]),
    );
  }

  void _navigateToDetail(BuildContext c, String id, Map<String, dynamic> data) => Navigator.push(c, MaterialPageRoute(builder: (c) => EventDetailScreen(eventId: id, eventData: data)));

  Widget _buildEventCard(BuildContext context, String docId, Map<String, dynamic> data, int index) {
    final name = data['name'] ?? ''; final location = data['location'] ?? '';
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final totalAmount = (data['totalAmount'] ?? 0).toDouble();
    final status = data['status'] ?? 'Active';
    final paidCount = (data['paidCount'] ?? 0).toInt();
    final totalParticipants = (data['totalParticipants'] ?? 1).toInt();
    final paymentStatus = data['paymentStatus'] ?? 'Unpaid';
    final progress = totalParticipants > 0 ? paidCount / totalParticipants : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 400 + (index * 100)), curve: Curves.easeOutCubic,
      builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
      child: GestureDetector(onTap: () => _navigateToDetail(context, docId, data),
        child: Container(margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
          child: Column(children: [
            // Green accent top bar
            Container(height: 4, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)))),
            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.location_on, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4),
                    Text(location, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))]),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: status == 'Active' ? AppGradients.primary : null, color: status != 'Active' ? AppColors.textHint : null, borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 8),
              Row(children: [Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary), const SizedBox(width: 4),
                Text('${date.day} ${_getMonthName(date.month)} ${date.year}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))]),
              const SizedBox(height: 14),
              // Progress
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Pembayaran', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textBody)),
                Text('${(progress * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
              const SizedBox(height: 8),
              Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: AppColors.primarySofter, borderRadius: BorderRadius.circular(3)),
                child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress,
                  child: Container(decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(3))))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('$paidCount/$totalParticipants Paid', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                Row(children: [
                  Text('+$totalParticipants', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(gradient: AppGradients.button, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.button),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.visibility_rounded, size: 14, color: Colors.white), const SizedBox(width: 4),
                      Text('Detail', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 2), Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white.withOpacity(0.8))])),
                ]),
              ]),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total: Rp ${_formatRupiah(totalAmount)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: paymentStatus == 'Paid' ? AppColors.primarySoft : const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(20)),
                  child: Text(paymentStatus == 'Paid' ? 'Bayar' : 'Belum Bayar', style: GoogleFonts.poppins(
                    color: paymentStatus == 'Paid' ? AppColors.primaryDark : AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
            ])),
          ]),
        )),
    );
  }

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      child: Icon(Icons.event_note, size: 40, color: AppColors.primary.withOpacity(0.5))),
    const SizedBox(height: 16),
    Text('Belum ada event', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    const SizedBox(height: 8),
    Text('Buat event pertama Anda sekarang', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
  ]));

  String _formatRupiah(double a) { if (a >= 1000000) return '${(a / 1000000).toStringAsFixed(a % 1000000 == 0 ? 0 : 1)}jt'; if (a >= 1000) return '${(a / 1000).toStringAsFixed(a % 1000 == 0 ? 0 : 1)}k'; return a.toStringAsFixed(0); }
  String _getMonthName(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][m - 1];
}
