import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  // Default notification settings
  Map<String, bool> _settings = {
    'paymentReminders': true,
    'dailySummary': true,
    'monthlyRecap': true,
    'splitCompleted': true,
    'promotionalUpdates': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('notificationSettings')) {
        final saved = doc.data()!['notificationSettings'] as Map<String, dynamic>;
        setState(() {
          _settings = {
            'paymentReminders': saved['paymentReminders'] ?? true,
            'dailySummary': saved['dailySummary'] ?? true,
            'monthlyRecap': saved['monthlyRecap'] ?? true,
            'splitCompleted': saved['splitCompleted'] ?? true,
            'promotionalUpdates': saved['promotionalUpdates'] ?? false,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() {
      _settings[key] = value;
    });

    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
        'notificationSettings': _settings,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Manage how you receive notifications and updates from SplitSpot.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Activity Notifications
                  _buildSectionHeader('Activity Notifications'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.payment_rounded,
                      iconColor: AppColors.warning,
                      title: 'Payment Reminders',
                      subtitle: 'Get notified when someone hasn\'t paid their share',
                      settingKey: 'paymentReminders',
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.today_rounded,
                      iconColor: AppColors.info,
                      title: 'Daily Summary',
                      subtitle: 'Get a daily recap of your active splits',
                      settingKey: 'dailySummary',
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.pie_chart_rounded,
                      iconColor: const Color(0xFF9C27B0),
                      title: 'Monthly Recap',
                      subtitle: 'Get a monthly overview of your total splits and collections',
                      settingKey: 'monthlyRecap',
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      title: 'Split Completed',
                      subtitle: 'When all participants have completed payments',
                      settingKey: 'splitCompleted',
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // Other Notifications
                  _buildSectionHeader('Other Updates'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.campaign_rounded,
                      iconColor: AppColors.textSecondary,
                      title: 'Promotional Updates',
                      subtitle: 'News, tips, and feature updates from SplitSpot',
                      settingKey: 'promotionalUpdates',
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: AppColors.divider, indent: 64);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String settingKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: _settings[settingKey] ?? false,
              onChanged: (val) => _updateSetting(settingKey, val),
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primarySoft,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
