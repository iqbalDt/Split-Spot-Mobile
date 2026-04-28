import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Email validation regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _validateAndRegister() async {
    setState(() {
      _fullNameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;

    // Full name validation
    if (fullNameController.text.isEmpty) {
      setState(() {
        _fullNameError = 'Nama lengkap tidak boleh kosong';
      });
      isValid = false;
    }

    // Email validation
    if (emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Email tidak boleh kosong';
      });
      isValid = false;
    } else if (!_isValidEmail(emailController.text)) {
      setState(() {
        _emailError = 'Format email tidak valid';
      });
      isValid = false;
    }

    // Password validation
    if (passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Password tidak boleh kosong';
      });
      isValid = false;
    } else if (passwordController.text.length < 8) {
      setState(() {
        _passwordError = 'Password minimal 8 karakter';
      });
      isValid = false;
    }

    // Confirm password validation
    if (confirmPasswordController.text.isEmpty) {
      setState(() {
        _confirmPasswordError = 'Konfirmasi password tidak boleh kosong';
      });
      isValid = false;
    } else if (confirmPasswordController.text != passwordController.text) {
      setState(() {
        _confirmPasswordError = 'Password tidak cocok';
      });
      isValid = false;
    }

    if (isValid) {
      // Show loading state
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Send email verification
        await userCredential.user?.sendEmailVerification();

        // Update display name
        await userCredential.user?.updateDisplayName(fullNameController.text.trim());

        // Sign out so user must verify email first
        await FirebaseAuth.instance.signOut();

        // Show success dialog with verification instructions
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('Verifikasi Email'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akun berhasil dibuat! Link verifikasi telah dikirim ke:',
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
                            emailController.text.trim(),
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
                    'Silakan periksa inbox email Anda dan klik link verifikasi sebelum login.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
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
                            'Jika tidak menemukan email, cek folder Spam/Junk.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Mengerti, ke Login'),
                ),
              ],
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;

        switch (e.code) {
          case 'email-already-in-use':
            message = 'Email sudah terdaftar';
            break;
          case 'weak-password':
            message = 'Password terlalu lemah';
            break;
          case 'invalid-email':
            message = 'Email tidak valid';
            break;
          default:
            message = 'Pendaftaran gagal';
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
            content: Text('Terjadi error'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Icon
              Center(
                child: Container(
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
              ),
              SizedBox(height: 24),

              // Title
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),

              // Subtitle
              Text(
                'Join SplitSpot to handle expenses easily',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),

              // Full Name field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Full Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _fullNameError != null ? Colors.red : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _fullNameError != null ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _fullNameError != null
                          ? Icon(Icons.error_outline, color: Colors.red)
                          : null,
                    ),
                  ),
                  if (_fullNameError != null) ...[
                    SizedBox(height: 8),
                    Text(
                      _fullNameError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),

              // Email field
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
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.green),
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

              // Password field
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
                      hintText: 'Create a password',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.green),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.green,
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
                  ] else ...[
                    SizedBox(height: 8),
                    Text(
                      'Minimal 8 karakter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),

              // Confirm Password field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.green),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        child: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.green,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null ? Colors.red : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_confirmPasswordError != null) ...[
                    SizedBox(height: 8),
                    Text(
                      _confirmPasswordError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 28),

              // Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndRegister,
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
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),

              // Login link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
