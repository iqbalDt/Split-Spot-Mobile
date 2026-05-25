import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'activity_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'create_event_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>()];
  late List<Widget> _screens;
  final List<_NavItem> _navItems = [_NavItem(Icons.home_rounded, 'Home'), _NavItem(Icons.history_rounded, 'Activity'), _NavItem(Icons.add, 'Create'), _NavItem(Icons.notifications_rounded, 'Notif'), _NavItem(Icons.person_rounded, 'Profile')];

  @override
  void initState() {
    super.initState();
    _screens = [_nav(0, HomeScreen()), _nav(1, ActivityScreen()), _nav(2, NotificationScreen()), _nav(3, ProfileScreen())];
    _animCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }
  Widget _nav(int i, Widget s) => Navigator(key: _navigatorKeys[i], onGenerateRoute: (st) => MaterialPageRoute(builder: (c) => s));
  void _onCreate() { Navigator.push(context, MaterialPageRoute(builder: (c) => CreateEventScreen())).then((_) => setState(() {})); }
  void _onTab(int i) {
    if (i == 2) { _onCreate(); return; }
    int si = i > 2 ? i - 1 : i;
    if (_selectedIndex == si) { _navigatorKeys[si].currentState?.popUntil((r) => r.isFirst); }
    else { setState(() { _selectedIndex = si; _animCtrl.reset(); _animCtrl.forward(); }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) { if (didPop) return; if (_navigatorKeys[_selectedIndex].currentState?.canPop() ?? false) { _navigatorKeys[_selectedIndex].currentState?.pop(); } else { Navigator.of(context).maybePop(); } },
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))]),
        child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: List.generate(_navItems.length, (i) => Expanded(child: i == 2 ? _buildCreateBtn() : _buildNavItem(i)))))),
      ),
    );
  }

  Widget _buildCreateBtn() {
    return GestureDetector(onTap: () => _onTab(2), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Transform.translate(offset: const Offset(0, -16), child: Container(width: 54, height: 54,
        decoration: BoxDecoration(gradient: AppGradients.button, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4), spreadRadius: 1)]),
        child: const Icon(Icons.add, color: Colors.white, size: 30))),
      Transform.translate(offset: const Offset(0, -12), child: Text('Create', style: GoogleFonts.poppins(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w700))),
    ]));
  }

  Widget _buildNavItem(int i) {
    int si = i > 2 ? i - 1 : i;
    final sel = i != 2 && _selectedIndex == si;
    final item = _navItems[i];
    return GestureDetector(onTap: () => _onTab(i), child: Container(color: Colors.transparent, child: Stack(alignment: Alignment.center, children: [
      if (sel) ScaleTransition(scale: _scaleAnim, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle))),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          Icon(item.icon, color: sel ? AppColors.primary : AppColors.textHint, size: 24),
          if (i == 3) _buildBadge(),
        ]),
        const SizedBox(height: 2),
        Text(item.label, style: GoogleFonts.poppins(color: sel ? AppColors.primary : AppColors.textHint, fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
      ]),
    ])));
  }

  Widget _buildBadge() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').where('createdBy', isEqualTo: uid).snapshots(),
      builder: (c, s) {
        if (!s.hasData) return const SizedBox.shrink();
        int n = 0;
        for (final d in s.data!.docs) { final data = d.data() as Map<String, dynamic>; if (data['status'] == 'Completed') continue; for (final p in (data['participants'] as List?) ?? []) { if (p is Map<String, dynamic> && p['isPaid'] != true) n++; } }
        if (n == 0) return const SizedBox.shrink();
        return Positioned(right: -6, top: -4, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
          child: Center(child: Text(n > 99 ? '99+' : '$n', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))));
      },
    );
  }
}

class _NavItem { final IconData icon; final String label; _NavItem(this.icon, this.label); }