import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true, _obscureConfirmPassword = true, _isLoading = false;
  String? _fullNameError, _emailError, _passwordError, _confirmPasswordError;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); fullNameController.dispose(); emailController.dispose(); passwordController.dispose(); confirmPasswordController.dispose(); super.dispose(); }

  bool _isValidEmail(String e) => RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(e);

  Future<void> _validateAndRegister() async {
    setState(() { _fullNameError = null; _emailError = null; _passwordError = null; _confirmPasswordError = null; });
    bool ok = true;
    if (fullNameController.text.isEmpty) { _fullNameError = 'Nama lengkap tidak boleh kosong'; ok = false; }
    if (emailController.text.isEmpty) { _emailError = 'Email tidak boleh kosong'; ok = false; } else if (!_isValidEmail(emailController.text)) { _emailError = 'Format email tidak valid'; ok = false; }
    if (passwordController.text.isEmpty) { _passwordError = 'Password tidak boleh kosong'; ok = false; } else if (passwordController.text.length < 8) { _passwordError = 'Password minimal 8 karakter'; ok = false; }
    if (confirmPasswordController.text.isEmpty) { _confirmPasswordError = 'Konfirmasi password tidak boleh kosong'; ok = false; } else if (confirmPasswordController.text != passwordController.text) { _confirmPasswordError = 'Password tidak cocok'; ok = false; }
    if (!ok) { setState(() {}); return; }
    setState(() { _isLoading = true; });
    try {
      final uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      await uc.user?.sendEmailVerification();
      await uc.user?.updateDisplayName(fullNameController.text.trim());
      await FirebaseAuth.instance.signOut();
      if (mounted) showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(children: [Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28), const SizedBox(width: 10), Text('Verifikasi Email', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Akun berhasil dibuat! Link verifikasi telah dikirim ke:', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBody)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [Icon(Icons.email, color: AppColors.primary, size: 18), const SizedBox(width: 8), Flexible(child: Text(emailController.text.trim(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primaryDark)))])),
          const SizedBox(height: 16),
          Text('Silakan periksa inbox email Anda dan klik link verifikasi sebelum login.', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: Colors.orange[700], size: 18), const SizedBox(width: 8),
              Flexible(child: Text('Jika tidak menemukan email, cek folder Spam/Junk.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[800])))])),
        ]),
        actions: [TextButton(onPressed: () { Navigator.pop(c); Navigator.pushReplacement(c, MaterialPageRoute(builder: (c) => LoginScreen())); },
          style: TextButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Mengerti, ke Login'))],
      ));
    } on FirebaseAuthException catch (e) {
      String m; switch (e.code) { case 'email-already-in-use': m = 'Email sudah terdaftar'; break; case 'weak-password': m = 'Password terlalu lemah'; break; case 'invalid-email': m = 'Email tidak valid'; break; default: m = 'Pendaftaran gagal'; }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Terjadi error'), backgroundColor: AppColors.danger)); }
    finally { setState(() { _isLoading = false; }); }
  }

  Widget _f(String label, TextEditingController c, String hint, IconData icon, String? err, {bool obs = false, VoidCallback? toggle, String? helper, TextInputType? kb}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 8),
      TextField(controller: c, obscureText: obs, keyboardType: kb, style: GoogleFonts.poppins(color: AppColors.textDark),
        decoration: AppDecorations.input(hintText: hint, hasError: err != null, prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: toggle != null ? GestureDetector(onTap: toggle, child: Icon(obs ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary)) : (err != null ? const Icon(Icons.error_outline, color: AppColors.danger) : null))),
      if (err != null) ...[const SizedBox(height: 8), Text(err, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.danger))]
      else if (helper != null) ...[const SizedBox(height: 8), Text(helper, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint))],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pop(context))),
      body: Stack(children: [
        Positioned(top: -60, right: -40, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.06), Colors.transparent])))),
        FadeTransition(opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut)),
          child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 60, height: 60, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]),
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 32))),
            const SizedBox(height: 24),
            Text('Create Account', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text('Join SplitSpot to handle expenses easily', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _f('Full Name', fullNameController, 'Enter your full name', Icons.person_outline, _fullNameError),
            const SizedBox(height: 16),
            _f('Email', emailController, 'Enter your email address', Icons.email_outlined, _emailError, kb: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _f('Password', passwordController, 'Create a password', Icons.lock_outline, _passwordError, obs: _obscurePassword, toggle: () => setState(() => _obscurePassword = !_obscurePassword), helper: 'Minimal 8 karakter'),
            const SizedBox(height: 16),
            _f('Confirm Password', confirmPasswordController, 'Confirm your password', Icons.lock_outline, _confirmPasswordError, obs: _obscureConfirmPassword, toggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
            const SizedBox(height: 28),
            GradientButton(onPressed: _isLoading ? null : _validateAndRegister, isLoading: _isLoading,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Register', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)), const SizedBox(width: 8), const Icon(Icons.arrow_forward, color: Colors.white)])),
            const SizedBox(height: 20),
            Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Sudah punya akun? ', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
              GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => LoginScreen())),
                child: Text('Login', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary))),
            ])),
            const SizedBox(height: 40),
          ])))),
      ]),
    );
  }
}
