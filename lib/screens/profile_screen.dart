import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'rekening_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  @override
  void initState() { super.initState(); _currentUser = FirebaseAuth.instance.currentUser; }
  void _refreshUser() { _currentUser?.reload().then((_) { if (mounted) setState(() { _currentUser = FirebaseAuth.instance.currentUser; }); }); }

  Widget _buildAvatar(String? url) {
    if (url != null && url.isNotEmpty) {
      return Container(width: 104, height: 104,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.primary,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, spreadRadius: 2)]),
        padding: const EdgeInsets.all(3),
        child: CircleAvatar(radius: 49, backgroundColor: AppColors.scaffoldBg, backgroundImage: NetworkImage(url), onBackgroundImageError: (_, __) {}));
    }
    return Container(width: 104, height: 104,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.primary,
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 20, spreadRadius: 2)]),
      child: const Icon(Icons.person, size: 56, color: Colors.white));
  }

  Future<void> _handleLogout() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(children: [const Icon(Icons.logout_rounded, color: AppColors.danger, size: 24), const SizedBox(width: 10), Text('Logout', style: GoogleFonts.poppins(fontSize: 18))]),
      content: Text('Are you sure you want to log out of your account?', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBody)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(c, true),
          style: TextButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Logout')),
      ],
    ));
    if (ok != true) return;
    try { await FirebaseAuth.instance.signOut(); if (mounted) Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => LoginScreen()), (r) => false);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out: $e'), backgroundColor: AppColors.danger)); }
  }


  @override
  Widget build(BuildContext context) {
    final uid = _currentUser?.uid;
    return Scaffold(backgroundColor: AppColors.scaffoldBg,
      body: uid == null ? Center(child: Text('Not logged in', style: GoogleFonts.poppins(color: AppColors.textSecondary)))
        : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (c, s) {
            Map<String, dynamic>? fd;
            if (s.hasData && s.data!.exists) fd = s.data!.data() as Map<String, dynamic>?;
            final dn = fd?['displayName'] ?? _currentUser?.displayName ?? 'User Name';
            final em = _currentUser?.email ?? 'No email';
            final ph = fd?['phone']?.toString() ?? '';
            final bio = fd?['bio']?.toString() ?? '';
            final url = fd?['photoURL']?.toString() ?? _currentUser?.photoURL ?? '';

            return CustomScrollView(slivers: [
              SliverAppBar(floating: true, pinned: false, snap: true, expandedHeight: 60, backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0,
                flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text('Profile', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark)))),
              SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
                const SizedBox(height: 16),
                // Header card
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(gradient: AppGradients.primarySoft, borderRadius: BorderRadius.circular(22)),
                  child: Column(children: [
                    _buildAvatar(url.isNotEmpty ? url : null),
                    const SizedBox(height: 16),
                    Text(dn, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text(em, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBody)),
                    if (ph.isNotEmpty) ...[const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.phone, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4),
                      Text(ph, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary))])],
                    if (bio.isNotEmpty) ...[const SizedBox(height: 10),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                        child: Text(bio, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textBody, fontStyle: FontStyle.italic), textAlign: TextAlign.center)))],
                  ]),
                ),
                const SizedBox(height: 24),
                // Menu
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  child: Column(children: [
                    _menuItem(Icons.person_outline, 'Edit Profile', () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen())); if (r == true) _refreshUser(); }),
                    _div(),
                    _menuItem(Icons.account_balance_wallet_outlined, 'Rekening & E-Wallet', () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (c) => RekeningScreen())); if (r == true) _refreshUser(); }),
                    _div(),
                    _menuItem(Icons.notifications_none, 'Notification Settings', () => Navigator.push(context, MaterialPageRoute(builder: (c) => NotificationSettingsScreen()))),
                    _div(),
                    _menuItem(Icons.security, 'Privacy & Security', () => Navigator.push(context, MaterialPageRoute(builder: (c) => PrivacySecurityScreen()))),
                    _div(),
                    _menuItem(Icons.help_outline, 'Help & Support', () => Navigator.push(context, MaterialPageRoute(builder: (c) => HelpSupportScreen()))),
                  ]),
                ),
                const SizedBox(height: 20),
                // Logout
                SizedBox(width: double.infinity, child: Container(
                  decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.danger.withOpacity(0.2))),
                  child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(14), onTap: _handleLogout,
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: Text('Logout', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.danger)))))))),
                const SizedBox(height: 40),
              ]))),
            ]);
          }),
    );
  }

  Widget _div() => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: AppColors.divider);
  Widget _menuItem(IconData ic, String t, VoidCallback tap) => InkWell(onTap: tap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
        child: Icon(ic, color: AppColors.primary, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Text(t, style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500))),
      Icon(Icons.chevron_right, color: AppColors.textHint),
    ])));
}
