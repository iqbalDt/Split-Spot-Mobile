import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this)..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _textSlide = Tween<double>(begin: 24.0, end: 0.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)));
    _logoCtrl.forward();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  void dispose() { _logoCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        )),
        child: Center(
          child: AnimatedBuilder(animation: _logoCtrl, builder: (context, _) {
            return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Pulsing glow
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)),
                child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 40, spreadRadius: 10),
                ])),
              ),
              // Logo
              Transform.translate(offset: const Offset(0, -110), child: Opacity(opacity: _logoFade.value,
                child: Transform.scale(scale: _logoScale.value, child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))]),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 44),
                )),
              )),
              // Title
              Transform.translate(offset: Offset(0, -90 + _textSlide.value), child: Opacity(opacity: _logoFade.value,
                child: Text('SplitSpot', style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primaryDark)))),
              Transform.translate(offset: Offset(0, -85 + _textSlide.value), child: Opacity(opacity: _logoFade.value,
                child: Text('Split bills, not friendships', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 0.3)))),
              const SizedBox(height: 30),
              Transform.translate(offset: const Offset(0, -60), child: Opacity(opacity: _logoFade.value,
                child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.primary.withOpacity(0.5), strokeWidth: 2.5)))),
            ]);
          }),
        ),
      ),
    );
  }
}
