import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _validateAndLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool isValid = true;

    if (emailController.text.isEmpty) {
      _emailError = 'Email tidak boleh kosong';
      isValid = false;
    } else if (!_isValidEmail(emailController.text)) {
      _emailError = 'Format email tidak valid';
      isValid = false;
    }

    if (passwordController.text.isEmpty) {
      _passwordError = 'Password tidak boleh kosong';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        // Sign out unverified user
        await FirebaseAuth.instance.signOut();

        setState(() {
          _isLoading = false;
        });

        // Show verification needed dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Flexible(child: Text('Email Belum Diverifikasi', style: TextStyle(fontSize: 18))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda perlu memverifikasi email terlebih dahulu sebelum bisa login.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Cek inbox dan folder Spam/Junk di email Anda.',
                            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Tutup', style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    // Re-sign in temporarily to resend verification
                    try {
                      final tempCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      await tempCredential.user?.sendEmailVerification();
                      await FirebaseAuth.instance.signOut();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('Email verifikasi telah dikirim ulang!')),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengirim ulang email verifikasi'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Kirim Ulang Email'),
                ),
              ],
            ),
          );
        }
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'User tidak ditemukan';
          break;
        case 'wrong-password':
          message = 'Password salah';
          break;
        case 'invalid-email':
          message = 'Email tidak valid';
          break;
        case 'invalid-credential':
          message = 'Email atau password salah';
          break;
        default:
          message = 'Login gagal: ${e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // ── Forgot Password ──────────────────────────────────────────────
  void _showForgotPasswordSheet() {
    final TextEditingController resetEmailController = TextEditingController();
    String? resetEmailError;
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Icon & Title
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Kami akan mengirim link reset ke email Anda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Email input
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Masukkan email terdaftar',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: resetEmailError != null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: resetEmailError != null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: resetEmailError != null
                                  ? Colors.red
                                  : Colors.green,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: resetEmailError != null
                              ? Icon(Icons.error_outline, color: Colors.red)
                              : null,
                        ),
                      ),
                      if (resetEmailError != null) ...[
                        SizedBox(height: 8),
                        Text(
                          resetEmailError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                      SizedBox(height: 24),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSending
                              ? null
                              : () async {
                                  // Validate email
                                  final email =
                                      resetEmailController.text.trim();
                                  if (email.isEmpty) {
                                    setModalState(() {
                                      resetEmailError =
                                          'Email tidak boleh kosong';
                                    });
                                    return;
                                  }
                                  if (!_isValidEmail(email)) {
                                    setModalState(() {
                                      resetEmailError =
                                          'Format email tidak valid';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    resetEmailError = null;
                                    isSending = true;
                                  });

                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);

                                    Navigator.pop(context);

                                    // Show success dialog with detailed instructions
                                    if (mounted) {
                                      showDialog(
                                        context: this.context,
                                        builder: (dialogContext) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 28),
                                              SizedBox(width: 10),
                                              Flexible(child: Text('Email Terkirim!', style: TextStyle(fontSize: 18))),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Link reset password telah dikirim ke:',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFE8F5E9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.email, color: Colors.green, size: 18),
                                                    SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        email,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.green[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Silakan buka email Anda dan klik link untuk mengatur ulang password.',
                                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                              ),
                                              SizedBox(height: 10),
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.orange[200]!),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.tips_and_updates, color: Colors.orange[700], size: 18),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Tips:',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.orange[800],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      '• Cek folder Spam/Junk jika tidak ada di inbox\n• Email dikirim dari noreply@split-spot-4934d.firebaseapp.com\n• Link berlaku selama 1 jam',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.orange[800],
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dialogContext),
                                              style: TextButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text('Mengerti'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    String message;
                                    switch (e.code) {
                                      case 'user-not-found':
                                        message =
                                            'Email tidak terdaftar';
                                        break;
                                      case 'invalid-email':
                                        message = 'Format email tidak valid';
                                        break;
                                      default:
                                        message =
                                            'Gagal mengirim email reset: ${e.code}';
                                    }
                                    setModalState(() {
                                      resetEmailError = message;
                                      isSending = false;
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      resetEmailError =
                                          'Terjadi kesalahan: $e';
                                      isSending = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.grey[400],
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isSending
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Kirim Link Reset',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // ── Web: use signInWithPopup (works in Chrome/Edge) ──
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        // ── Native (Android/iOS): use google_sign_in package ──
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser == null) {
          // User cancelled the sign-in
          setState(() {
            _isGoogleLoading = false;
          });
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');

      String errorMessage = 'Gagal login dengan Google';
      if (e.toString().contains('popup-closed-by-user') ||
          e.toString().contains('cancelled')) {
        // User closed the popup — don't show error
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(errorMessage),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }

    setState(() {
      _isGoogleLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              // App Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: 24),

              Text(
                'SplitSpot',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'Manage shared expenses effortlessly.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // EMAIL
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.red : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _emailError != null
                          ? Icon(Icons.error_outline, color: Colors.red)
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_emailError != null) ...[
                    SizedBox(height: 8),
                    Text(
                      _emailError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),

              // PASSWORD
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey[600],
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordError != null ? Colors.red : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _passwordError != null ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_passwordError != null) ...[
                    SizedBox(height: 8),
                    Text(
                      _passwordError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordSheet,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 28),

              // ── Styled Divider ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey[300]!,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[300]!,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 28),

              // ── Google Sign-In Button ──────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: _isGoogleLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[600]!),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google "G" logo using colored text
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: 28),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}