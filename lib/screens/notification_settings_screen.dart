import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    'eventInvites': true,
    'eventUpdates': true,
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
            'eventInvites': saved['eventInvites'] ?? true,
            'eventUpdates': saved['eventUpdates'] ?? true,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_rounded,
                            color: Color(0xFF4CAF50), size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manage how you receive notifications from SplitSpot.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Activity Notifications
                  _buildSectionHeader('Activity Notifications'),
                  SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.payment_rounded,
                      iconColor: Color(0xFFFF9800),
                      title: 'Payment Reminders',
                      subtitle: 'Get notified when someone hasn\'t paid their share',
                      settingKey: 'paymentReminders',
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.group_add_rounded,
                      iconColor: Color(0xFF2196F3),
                      title: 'New Event Invites',
                      subtitle: 'When you\'re added to a new event or group',
                      settingKey: 'eventInvites',
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.update_rounded,
                      iconColor: Color(0xFF9C27B0),
                      title: 'Event Updates',
                      subtitle: 'Changes to events you\'re participating in',
                      settingKey: 'eventUpdates',
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.check_circle_rounded,
                      iconColor: Color(0xFF4CAF50),
                      title: 'Split Completed',
                      subtitle: 'When all participants have completed payments',
                      settingKey: 'splitCompleted',
                    ),
                  ]),
                  SizedBox(height: 24),

                  // Other Notifications
                  _buildSectionHeader('Other'),
                  SizedBox(height: 8),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.campaign_rounded,
                      iconColor: Colors.grey[600]!,
                      title: 'Promotional Updates',
                      subtitle: 'News, tips, and feature updates from SplitSpot',
                      settingKey: 'promotionalUpdates',
                    ),
                  ]),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200], indent: 56);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String settingKey,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings[settingKey] ?? false,
            onChanged: (val) => _updateSetting(settingKey, val),
            activeColor: Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}
