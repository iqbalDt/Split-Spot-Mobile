import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  // FAQ data
  final List<Map<String, String>> _faqItems = const [
    {
      'question': 'How do I create a new event?',
      'answer':
          'Tap the green "+" button at the bottom of the screen. Fill in the event details like name, location, and date. Then add items and participants to start splitting the bill.',
    },
    {
      'question': 'How does bill splitting work?',
      'answer':
          'After creating an event and adding items, you assign each item to the participants who consumed it. SplitSpot will automatically calculate how much each person owes based on their share of the items.',
    },
    {
      'question': 'How do I track payments?',
      'answer':
          'In the event detail screen, you can see each participant\'s payment status. Mark payments as "Paid" when someone has settled their share. You\'ll get a notification when everyone has paid.',
    },
    {
      'question': 'Can I invite participants to an event?',
      'answer':
          'Yes! When creating an event, you can add participants by entering their names. In the future, we\'ll support sending invite links directly to other SplitSpot users.',
    },
    {
      'question': 'How do I edit or delete an event?',
      'answer':
          'Open the event from your Home screen and tap on the event card. From the event detail view, you can modify event details or remove the event entirely.',
    },
    {
      'question': 'Is my data secure?',
      'answer':
          'Yes! SplitSpot uses Firebase for secure authentication and data storage. Your personal information is encrypted and protected. You can manage your privacy settings in Profile → Privacy & Security.',
    },
    {
      'question': 'How do I change my password?',
      'answer':
          'Go to Profile → Privacy & Security → Change Password. You\'ll need to enter your current password and then set a new one. Note: This option is only available for email/password accounts.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Help & Support',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Find answers to common questions or contact our support team.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // FAQ Section
            _buildSectionHeader('Frequently Asked Questions'),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ExpansionPanelList.radio(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  dividerColor: Colors.grey[200],
                  children: _faqItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return ExpansionPanelRadio(
                      value: index,
                      canTapOnHeader: true,
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Q${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            item['question']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      body: Padding(
                        padding:
                            EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['answer']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Contact Us
            _buildSectionHeader('Contact Us'),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildContactTile(
                    icon: Icons.email_rounded,
                    iconColor: Color(0xFF2196F3),
                    title: 'Email Support',
                    subtitle: 'support@splitspot.app',
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'support@splitspot.app',
                        queryParameters: {
                          'subject': 'SplitSpot Support Request',
                        },
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildContactTile(
                    icon: Icons.chat_bubble_rounded,
                    iconColor: Color(0xFF4CAF50),
                    title: 'WhatsApp',
                    subtitle: '+62 812-0000-0000',
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://wa.me/6281200000000?text=Hi,%20I%20need%20help%20with%20SplitSpot');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // About & Legal
            _buildSectionHeader('About'),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: Color(0xFF607D8B),
                    title: 'App Version',
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildActionTile(
                    icon: Icons.star_rounded,
                    iconColor: Color(0xFFFF9800),
                    title: 'Rate SplitSpot',
                    subtitle: 'Love the app? Leave us a review!',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.construction_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Play Store link coming soon!'),
                            ],
                          ),
                          backgroundColor: Color(0xFF607D8B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          margin: EdgeInsets.all(16),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildActionTile(
                    icon: Icons.description_rounded,
                    iconColor: Color(0xFF795548),
                    title: 'Terms of Service',
                    subtitle: 'Read our terms and conditions',
                    onTap: () {
                      _showTextDialog(context, 'Terms of Service', _termsOfService);
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _buildActionTile(
                    icon: Icons.privacy_tip_rounded,
                    iconColor: Color(0xFF009688),
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () {
                      _showTextDialog(context, 'Privacy Policy', _privacyPolicy);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Made with ❤️ by SplitSpot Team',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '© 2026 SplitSpot. All rights reserved.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
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

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showTextDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title, style: TextStyle(fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  static const String _termsOfService = '''
Terms of Service - SplitSpot

Last updated: May 2026

1. Acceptance of Terms
By using SplitSpot, you agree to these Terms of Service. If you disagree, please do not use the app.

2. Description of Service
SplitSpot is a bill-splitting application that helps groups of people divide expenses fairly. The app provides tools for creating events, adding items, assigning participants, and tracking payments.

3. User Accounts
- You must provide accurate information during registration
- You are responsible for maintaining the security of your account
- You must be at least 13 years old to use this service

4. User Conduct
You agree not to:
- Use the service for any illegal purpose
- Attempt to gain unauthorized access to other accounts
- Interfere with or disrupt the service

5. Payment Tracking
SplitSpot is a tracking tool only. We do not process actual financial transactions. Users are responsible for settling payments among themselves.

6. Data and Privacy
Your data is handled according to our Privacy Policy. We use Firebase for secure data storage and authentication.

7. Limitation of Liability
SplitSpot is provided "as is" without warranties. We are not liable for any damages arising from the use of this service.

8. Changes to Terms
We may update these terms from time to time. Continued use of the app constitutes acceptance of the updated terms.

9. Contact
For questions about these terms, contact support@splitspot.app.
''';

  static const String _privacyPolicy = '''
Privacy Policy - SplitSpot

Last updated: May 2026

1. Information We Collect
- Account information (name, email address)
- Profile information (phone number, bio, profile photo)
- Event and expense data you create
- Usage data and analytics (if you opt in)

2. How We Use Your Information
- To provide and maintain the service
- To manage your account
- To send notifications about your events
- To improve our service (with your consent)

3. Data Storage
Your data is stored securely using Google Firebase services. Data is encrypted in transit and at rest.

4. Data Sharing
We do not sell your personal information. We only share data with:
- Firebase (authentication and database)
- Cloudinary (profile photo storage)

5. Your Rights
You have the right to:
- Access your personal data
- Update or correct your data
- Delete your account and data
- Opt out of promotional communications

6. Profile Photos
Profile photos are uploaded to Cloudinary, a third-party image hosting service. By uploading a photo, you agree to Cloudinary's terms of service.

7. Security
We implement appropriate security measures to protect your data. However, no method of transmission over the Internet is 100% secure.

8. Children's Privacy
SplitSpot is not intended for children under 13. We do not knowingly collect data from children under 13.

9. Changes to This Policy
We may update this policy from time to time. We will notify you of any significant changes.

10. Contact
For privacy-related inquiries, contact support@splitspot.app.
''';
}
