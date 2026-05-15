import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }


  void _showChangePasswordSheet() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    String? errorMessage;
    bool isSaving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    // Check if user signed in with password provider
    final hasPasswordProvider = _currentUser?.providerData
            .any((info) => info.providerId == 'password') ??
        false;

    if (!hasPasswordProvider) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Password change is not available for Google Sign-In accounts.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.lock_rounded,
                              color: Color(0xFF4CAF50), size: 24),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Current Password
                    TextField(
                      controller: currentPassController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: Colors.grey[500]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setModalState(
                                () => obscureCurrent = !obscureCurrent);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFF4CAF50), width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 14),

                    // New Password
                    TextField(
                      controller: newPassController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: Colors.grey[500]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setModalState(() => obscureNew = !obscureNew);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFF4CAF50), width: 2),
                        ),
                        helperText: 'Minimum 8 characters',
                      ),
                    ),
                    SizedBox(height: 14),

                    // Confirm New Password
                    TextField(
                      controller: confirmPassController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_outline,
                            color: Colors.grey[500]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setModalState(
                                () => obscureConfirm = !obscureConfirm);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xFF4CAF50), width: 2),
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                // Validate
                                if (currentPassController.text.isEmpty ||
                                    newPassController.text.isEmpty ||
                                    confirmPassController.text.isEmpty) {
                                  setModalState(() {
                                    errorMessage =
                                        'All fields are required';
                                  });
                                  return;
                                }
                                if (newPassController.text.length < 8) {
                                  setModalState(() {
                                    errorMessage =
                                        'New password must be at least 8 characters';
                                  });
                                  return;
                                }
                                if (newPassController.text !=
                                    confirmPassController.text) {
                                  setModalState(() {
                                    errorMessage =
                                        'New passwords do not match';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  errorMessage = null;
                                  isSaving = true;
                                });

                                try {
                                  // Re-authenticate
                                  final credential =
                                      EmailAuthProvider.credential(
                                    email: _currentUser!.email!,
                                    password:
                                        currentPassController.text,
                                  );
                                  await _currentUser!
                                      .reauthenticateWithCredential(
                                          credential);

                                  // Update password
                                  await _currentUser!.updatePassword(
                                      newPassController.text);

                                  Navigator.pop(context);

                                  if (mounted) {
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.white,
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                                'Password changed successfully!'),
                                          ],
                                        ),
                                        backgroundColor:
                                            Color(0xFF4CAF50),
                                        behavior:
                                            SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        margin: EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  String msg;
                                  switch (e.code) {
                                    case 'wrong-password':
                                      msg =
                                          'Current password is incorrect';
                                      break;
                                    case 'weak-password':
                                      msg =
                                          'New password is too weak';
                                      break;
                                    default:
                                      msg = 'Error: ${e.message}';
                                  }
                                  setModalState(() {
                                    errorMessage = msg;
                                    isSaving = false;
                                  });
                                } catch (e) {
                                  setModalState(() {
                                    errorMessage =
                                        'An error occurred: $e';
                                    isSaving = false;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Delete Account',
                style: TextStyle(fontSize: 18, color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dangerous_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'This action is irreversible:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• All your data will be permanently deleted\n• Your events and payment history will be lost\n• You cannot recover this account',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700],
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
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // Delete Firestore data
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUser!.uid)
                    .delete();

                // Delete Firebase Auth account
                await _currentUser!.delete();

                if (mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (e.code == 'requires-recent-login') {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Please log out and log back in before deleting your account.'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get login info
    String loginProvider = 'Email/Password';
    if (_currentUser != null) {
      for (var info in _currentUser!.providerData) {
        if (info.providerId == 'google.com') {
          loginProvider = 'Google';
          break;
        }
      }
    }

    final creationTime = _currentUser?.metadata.creationTime;
    final lastSignIn = _currentUser?.metadata.lastSignInTime;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Section
                  _buildSectionHeader('Security'),
                  SizedBox(height: 8),
                  _buildCard([
                    _buildActionTile(
                      icon: Icons.lock_rounded,
                      iconColor: Color(0xFF4CAF50),
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: _showChangePasswordSheet,
                    ),
                  ]),
                  SizedBox(height: 24),

                  SizedBox(height: 24),

                  // Login Activity
                  _buildSectionHeader('Login Activity'),
                  SizedBox(height: 8),
                  _buildCard([
                    _buildInfoTile(
                      icon: Icons.login_rounded,
                      iconColor: Color(0xFF607D8B),
                      title: 'Login Provider',
                      value: loginProvider,
                    ),
                    Divider(height: 1, color: Colors.grey[200], indent: 56),
                    _buildInfoTile(
                      icon: Icons.calendar_today_rounded,
                      iconColor: Color(0xFF607D8B),
                      title: 'Account Created',
                      value: creationTime != null
                          ? _formatDate(creationTime)
                          : 'Unknown',
                    ),
                    Divider(height: 1, color: Colors.grey[200], indent: 56),
                    _buildInfoTile(
                      icon: Icons.access_time_rounded,
                      iconColor: Color(0xFF607D8B),
                      title: 'Last Sign In',
                      value: lastSignIn != null
                          ? _formatDate(lastSignIn)
                          : 'Unknown',
                    ),
                  ]),
                  SizedBox(height: 24),

                  // Danger Zone
                  _buildSectionHeader('Danger Zone'),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: _buildActionTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.red,
                      title: 'Delete Account',
                      subtitle:
                          'Permanently delete your account and all data',
                      onTap: _showDeleteAccountDialog,
                      titleColor: Colors.red,
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey[700],
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
