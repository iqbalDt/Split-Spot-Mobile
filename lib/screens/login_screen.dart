import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); emailController.dispose(); passwordController.dispose(); super.dispose(); }

  bool _isValidEmail(String email) => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  Future<void> _validateAndLogin() async {
    setState(() { _emailError = null; _passwordError = null; });
    bool isValid = true;
    if (emailController.text.isEmpty) { _emailError = 'Email tidak boleh kosong'; isValid = false; }
    else if (!_isValidEmail(emailController.text)) { _emailError = 'Format email tidak valid'; isValid = false; }
    if (passwordController.text.isEmpty) { _passwordError = 'Password tidak boleh kosong'; isValid = false; }
    if (!isValid) { setState(() {}); return; }
    setState(() { _isLoading = true; });
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() { _isLoading = false; });
        if (mounted) {
          showDialog(context: context, builder: (dc) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28), const SizedBox(width: 10), Flexible(child: Text('Email Belum Diverifikasi', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)))]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Anda perlu memverifikasi email terlebih dahulu sebelum bisa login.', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBody)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: AppColors.warning, size: 18), const SizedBox(width: 8),
                  Flexible(child: Text('Cek inbox dan folder Spam/Junk di email Anda.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[800])))])),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dc), child: Text('Tutup', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dc);
                  try {
                    final t = await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
                    await t.user?.sendEmailVerification(); await FirebaseAuth.instance.signOut();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 20), const SizedBox(width: 8), const Expanded(child: Text('Email verifikasi telah dikirim ulang!'))]),
                      backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
                  } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Gagal mengirim ulang email verifikasi'), backgroundColor: AppColors.danger)); }
                },
                style: TextButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Kirim Ulang Email'),
              ),
            ],
          ));
        }
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) { case 'user-not-found': msg = 'User tidak ditemukan'; break; case 'wrong-password': msg = 'Password salah'; break; case 'invalid-email': msg = 'Email tidak valid'; break; case 'invalid-credential': msg = 'Email atau password salah'; break; default: msg = 'Login gagal: ${e.code}'; }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e'), backgroundColor: AppColors.danger)); }
    setState(() { _isLoading = false; });
  }

  void _showForgotPasswordSheet() {
    final rc = TextEditingController(); String? err; bool sending = false;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setS) {
        return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))]),
          child: Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reset Password', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text('Kami akan mengirim link reset ke email Anda', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              ])),
            ]),
            const SizedBox(height: 24),
            Text('Email', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(controller: rc, keyboardType: TextInputType.emailAddress, autofocus: true, style: GoogleFonts.poppins(color: AppColors.textDark),
              decoration: AppDecorations.input(hintText: 'Masukkan email terdaftar', hasError: err != null, prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary))),
            if (err != null) ...[const SizedBox(height: 8), Text(err!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.danger))],
            const SizedBox(height: 24),
            GradientButton(
              onPressed: sending ? null : () async {
                final email = rc.text.trim();
                if (email.isEmpty) { setS(() => err = 'Email tidak boleh kosong'); return; }
                if (!_isValidEmail(email)) { setS(() => err = 'Format email tidak valid'); return; }
                setS(() { err = null; sending = true; });
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(ctx);
                  if (mounted) showDialog(context: this.context, builder: (dc) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    title: Row(children: [Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28), const SizedBox(width: 10), Flexible(child: Text('Email Terkirim!', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)))]),
                    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Link reset password telah dikirim ke:', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBody)),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [Icon(Icons.email, color: AppColors.primary, size: 18), const SizedBox(width: 8), Flexible(child: Text(email, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primaryDark)))])),
                      const SizedBox(height: 16),
                      Text('Silakan buka email Anda dan klik link untuk mengatur ulang password.', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Icon(Icons.tips_and_updates, color: Colors.orange[700], size: 18), const SizedBox(width: 8), Text('Tips:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange[800]))]),
                          const SizedBox(height: 6),
                          Text('• Cek folder Spam/Junk jika tidak ada di inbox\n• Email dikirim dari noreply@split-spot-4934d.firebaseapp.com\n• Link berlaku selama 1 jam',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange[800], height: 1.4)),
                        ])),
                    ]),
                    actions: [TextButton(onPressed: () => Navigator.pop(dc), style: TextButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Mengerti'))],
                  ));
                } on FirebaseAuthException catch (e) {
                  String m; switch (e.code) { case 'user-not-found': m = 'Email tidak terdaftar'; break; case 'invalid-email': m = 'Format email tidak valid'; break; default: m = 'Gagal mengirim email reset: ${e.code}'; }
                  setS(() { err = m; sending = false; });
                } catch (e) { setS(() { err = 'Terjadi kesalahan: $e'; sending = false; }); }
              },
              isLoading: sending,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.send_rounded, color: Colors.white, size: 20), const SizedBox(width: 8), Text('Kirim Link Reset', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white))]),
            ),
          ])),
        ));
      });
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isGoogleLoading = true; });
    try {
      UserCredential uc;
      if (kIsWeb) {
        final gp = GoogleAuthProvider(); gp.addScope('email'); gp.addScope('profile');
        uc = await FirebaseAuth.instance.signInWithPopup(gp);
      } else {
        final gu = await GoogleSignIn().signIn();
        if (gu == null) { setState(() { _isGoogleLoading = false; }); return; }
        final ga = await gu.authentication;
        uc = await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(accessToken: ga.accessToken, idToken: ga.idToken));
      }
      if (uc.user != null) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (e.toString().contains('popup-closed-by-user') || e.toString().contains('cancelled')) { setState(() { _isGoogleLoading = false; }); return; }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.error_outline, color: Colors.white, size: 20), const SizedBox(width: 8), const Expanded(child: Text('Gagal login dengan Google'))]),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    }
    setState(() { _isGoogleLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // Top decorative gradient
        Positioned(top: -100, right: -80, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.0)])))),
        Positioned(top: 40, left: -60, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppColors.primaryLight.withOpacity(0.1), AppColors.primaryLight.withOpacity(0.0)])))),
        SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim,
          child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40), child: Column(children: [
            const SizedBox(height: 20),
            // App Icon
            Container(width: 70, height: 70,
              decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))]),
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 36)),
            const SizedBox(height: 24),
            Text('SplitSpot', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            Text('Manage shared expenses effortlessly.', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 44),
            Align(alignment: Alignment.centerLeft, child: Text('Welcome Back', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark))),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text('Masuk ke akun Anda untuk melanjutkan', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary))),
            const SizedBox(height: 28),
            // EMAIL
            _buildField('Email', emailController, 'Enter your email address', Icons.email_outlined, _emailError, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 16),
            // PASSWORD
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Password', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 8),
              TextField(controller: passwordController, obscureText: _obscurePassword, style: GoogleFonts.poppins(color: AppColors.textDark),
                decoration: AppDecorations.input(hintText: 'Enter your password', hasError: _passwordError != null,
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  suffixIcon: GestureDetector(onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary)))),
              if (_passwordError != null) ...[const SizedBox(height: 8), Text(_passwordError!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.danger))],
            ]),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: GestureDetector(onTap: _showForgotPasswordSheet,
              child: Text('Forgot Password?', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)))),
            const SizedBox(height: 24),
            // LOGIN BUTTON
            GradientButton(onPressed: _isLoading ? null : _validateAndLogin, isLoading: _isLoading,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Log in', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 8), const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ])),
            const SizedBox(height: 28),
            // DIVIDER
            Row(children: [
              Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, AppColors.border])))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Or continue with', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500))),
              Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.border, Colors.transparent])))),
            ]),
            const SizedBox(height: 28),
            // GOOGLE BUTTON
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: _isGoogleLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), backgroundColor: Colors.white),
              child: _isGoogleLoading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary), strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 24, height: 24, decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(6)),
                      child: Center(child: Text('G', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF4285F4))))),
                    const SizedBox(width: 12),
                    Text('Continue with Google', style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
            )),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Belum punya akun? ', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RegisterScreen())),
                child: Text('Daftar', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary))),
            ]),
          ]))),
        ))),
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon, String? error, {TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: keyboard, style: GoogleFonts.poppins(color: AppColors.textDark),
        decoration: AppDecorations.input(hintText: hint, hasError: error != null,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: error != null ? const Icon(Icons.error_outline, color: AppColors.danger) : null)),
      if (error != null) ...[const SizedBox(height: 8), Text(error, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.danger))],
    ]);
  }
}