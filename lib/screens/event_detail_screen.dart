import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _eventData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _eventData = Map<String, dynamic>.from(widget.eventData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Toggle payment status for a participant
  Future<void> _togglePaymentStatus(
    int participantIndex, {
    bool closeSheet = false,
  }) async {
    final participants = List<Map<String, dynamic>>.from(
      (_eventData['participants'] as List?)?.map(
            (p) => p is Map<String, dynamic>
                ? Map<String, dynamic>.from(p)
                : {'name': p.toString(), 'isPaid': false},
          ) ??
          [],
    );

    if (participantIndex >= participants.length) return;

    final currentStatus = participants[participantIndex]['isPaid'] ?? false;
    participants[participantIndex]['isPaid'] = !currentStatus;

    // Count paid participants
    int paidCount = participants.where((p) => p['isPaid'] == true).length;
    int totalParticipants = participants.length;

    // Determine overall payment status
    String paymentStatus = paidCount == totalParticipants ? 'Paid' : 'Unpaid';

    // Auto-complete event when all participants have paid
    String status = _eventData['status'] ?? 'Active';
    if (paidCount == totalParticipants) {
      status = 'Completed';
    } else if (status == 'Completed') {
      // Revert back if someone un-pays
      status = 'Active';
    }

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update({
            'participants': participants,
            'paidCount': paidCount,
            'paymentStatus': paymentStatus,
            'status': status,
          });

      setState(() {
        _eventData['participants'] = participants;
        _eventData['paidCount'] = paidCount;
        _eventData['paymentStatus'] = paymentStatus;
        _eventData['status'] = status;
      });

      if (mounted && closeSheet) {
        Navigator.pop(context);
      }

      if (mounted && paidCount == totalParticipants) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Semua peserta sudah bayar! Event selesai 🎉'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF388E3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate Xendit QRIS
  Future<String?> _generateXenditQRIS(
    double amount,
    String participantName,
  ) async {
    // TODO: Ganti dengan Secret Key Xendit Anda (Test/Live)
    // Ingat: Jangan simpan Secret Key langsung di aplikasi untuk Production!
    const String xenditSecretKey =
        'xnd_development_zpVl3pSPbIc2SPTW5Uc114lKW4Ms3YzJdCz8cUi0pkjYAMsDXo5kGovaZl9sqY';

    // Auth header
    final String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$xenditSecretKey:'));

    try {
      final response = await http.post(
        Uri.parse('https://api.xendit.co/qr_codes'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
          'api-version': '2022-07-31',
        },
        body: jsonEncode({
          'reference_id':
              '${widget.eventId}-${DateTime.now().millisecondsSinceEpoch}',
          'type': 'DYNAMIC',
          'currency': 'IDR',
          'amount': amount.toInt(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['qr_string'];
      } else {
        debugPrint('Xendit Error: ${response.body}');
        return 'ERROR: ${response.body}';
      }
    } catch (e) {
      debugPrint('Xendit Exception: $e');
      return 'ERROR: $e';
    }
  }

  // Show QRIS dialog for payment with toggle
  void _showQrisDialog(
    BuildContext context,
    String participantName,
    double amount,
    int participantIndex,
  ) {
    final isPaid =
        (_eventData['participants'] as List?)?.elementAt(participantIndex)
            is Map
        ? ((_eventData['participants'] as List).elementAt(participantIndex)
                  as Map)['isPaid'] ??
              false
        : false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool toggleValue = isPaid;
        bool isUpdating = false;
        String? qrisString;
        String? errorMessage;
        bool isLoadingQris = true;
        bool hasQrisError = false;
        String? bankName;
        String? bankAccount;
        bool isLoadingBank = true;

        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            // Fetch once
            if (isLoadingQris && qrisString == null && !hasQrisError) {
              _generateXenditQRIS(amount, participantName).then((result) {
                if (builderContext.mounted) {
                  setSheetState(() {
                    if (result != null && !result.startsWith('ERROR:')) {
                      qrisString = result;
                    } else {
                      hasQrisError = true;
                      errorMessage = result?.replaceFirst('ERROR: ', '');
                    }
                    isLoadingQris = false;
                  });
                }
              });

              // Fetch creator's bank info
              final userId = _eventData['userId'] ?? FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                FirebaseFirestore.instance.collection('users').doc(userId).get().then((doc) {
                  if (builderContext.mounted) {
                    setSheetState(() {
                      if (doc.exists) {
                        bankName = doc.data()?['bankName']?.toString();
                        bankAccount = doc.data()?['bankAccount']?.toString();
                      }
                      isLoadingBank = false;
                    });
                  }
                }).catchError((_) {
                  if (builderContext.mounted) {
                    setSheetState(() => isLoadingBank = false);
                  }
                });
              } else {
                isLoadingBank = false;
              }
            }
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'Pembayaran QRIS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    participantName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatNumber(amount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // QRIS box
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoadingQris
                          ? const CircularProgressIndicator(
                              color: Color(0xFF388E3C),
                            )
                          : (qrisString != null
                                ? QrImageView(
                                    data: qrisString!,
                                    version: QrVersions.auto,
                                    size: 180.0,
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 32,
                                          color: Colors.red[300],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Gagal memuat QRIS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          errorMessage ?? 'Unknown error',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red[400],
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  )),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bank info box
                  if (isLoadingBank)
                    const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF388E3C)),
                      ),
                    )
                  else if (bankName != null && bankName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFF388E3C),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '$bankName : ${bankAccount ?? '-'}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Divider with "atau" text
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau bayar tunai?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Payment toggle card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: toggleValue
                          ? const Color(0xFF388E3C).withOpacity(0.08)
                          : Colors.orange.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: toggleValue
                            ? const Color(0xFF388E3C).withOpacity(0.3)
                            : Colors.orange.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: toggleValue
                                ? const Color(0xFF388E3C).withOpacity(0.15)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            toggleValue
                                ? Icons.check_circle_rounded
                                : Icons.payment_rounded,
                            color: toggleValue
                                ? const Color(0xFF388E3C)
                                : Colors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                toggleValue ? 'Sudah Lunas! ✓' : 'Sudah bayar?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: toggleValue
                                      ? const Color(0xFF388E3C)
                                      : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                toggleValue
                                    ? 'Pembayaran telah dikonfirmasi'
                                    : 'Geser untuk konfirmasi pembayaran',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        isUpdating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF388E3C),
                                ),
                              )
                            : Transform.scale(
                                scale: 1.1,
                                child: Switch(
                                  value: toggleValue,
                                  onChanged: (value) async {
                                    setSheetState(() {
                                      isUpdating = true;
                                    });
                                    await _togglePaymentStatus(
                                      participantIndex,
                                      closeSheet: false,
                                    );
                                    setSheetState(() {
                                      toggleValue = !toggleValue;
                                      isUpdating = false;
                                    });
                                    // Auto-close after a brief delay if turned on
                                    if (toggleValue && mounted) {
                                      await Future.delayed(
                                        const Duration(milliseconds: 600),
                                      );
                                      if (mounted &&
                                          Navigator.of(sheetContext).canPop()) {
                                        Navigator.pop(sheetContext);
                                      }
                                    }
                                  },
                                  activeColor: const Color(0xFF388E3C),
                                  activeTrackColor: const Color(0xFF66BB6A),
                                  inactiveThumbColor: Colors.grey[400],
                                  inactiveTrackColor: Colors.grey[300],
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _eventData['name'] ?? 'Event';
    final location = _eventData['location'] ?? '';
    final googleMapsLink = _eventData['googleMapsLink'] ?? '';
    final date = (_eventData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final totalAmount = (_eventData['totalAmount'] ?? 0).toDouble();
    final subtotal = (_eventData['subtotal'] ?? totalAmount).toDouble();
    final status = _eventData['status'] ?? 'Active';
    final isTaxEnabled = _eventData['isTaxEnabled'] ?? false;
    final taxPercent = (_eventData['taxPercent'] ?? 0).toDouble();
    final paymentStatus = _eventData['paymentStatus'] ?? 'Unpaid';

    // Parse participants
    final rawParticipants = _eventData['participants'] as List? ?? [];
    final participants = rawParticipants.map((p) {
      if (p is Map<String, dynamic>) {
        return Map<String, dynamic>.from(p);
      }
      return {
        'name': p.toString(),
        'phone': '',
        'amount': 0.0,
        'isPaid': false,
      };
    }).toList();

    // Parse items
    final rawItems = _eventData['items'] as List? ?? [];
    final items = rawItems.map((item) {
      if (item is Map<String, dynamic>) {
        return Map<String, dynamic>.from(item);
      }
      return <String, dynamic>{};
    }).toList();

    int paidCount = participants.where((p) => p['isPaid'] == true).length;
    int totalParticipants = participants.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF388E3C),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'Active'
                                ? Colors.white.withOpacity(0.25)
                                : Colors.grey.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status == 'Active' ? '● Aktif' : '● Selesai',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Event name
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Location & date row
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: GestureDetector(
                                onTap: googleMapsLink.isNotEmpty
                                    ? () async {
                                        try {
                                          var link = googleMapsLink.trim();
                                          if (!link.startsWith('http://') &&
                                              !link.startsWith('https://')) {
                                            link = 'https://' + link;
                                          }
                                          final Uri url = Uri.parse(link);
                                          bool launched = false;
                                          // Try external browser first
                                          try {
                                            launched = await launchUrl(
                                              url,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } catch (_) {}
                                          // Fallback to platform default (opens in-app browser)
                                          if (!launched) {
                                            launched = await launchUrl(
                                              url,
                                              mode: LaunchMode.platformDefault,
                                            );
                                          }
                                          if (!launched && mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Tidak dapat membuka link',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Link tidak valid atau tidak didukung',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    decoration: googleMapsLink.isNotEmpty
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                    decorationColor: Colors.white.withOpacity(
                                      0.9,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${date.day} ${_getMonthName(date.month)} ${date.year}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Total amount
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Tagihan',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rp ${_formatNumber(totalAmount)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (isTaxEnabled && taxPercent > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Pajak ${taxPercent.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Payment Progress Card
                _buildPaymentProgressCard(
                  paidCount,
                  totalParticipants,
                  paymentStatus,
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF388E3C),
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF388E3C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people, size: 18),
                            const SizedBox(width: 6),
                            Text('Peserta (${participants.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant_menu, size: 18),
                            const SizedBox(width: 6),
                            Text('Menu (${items.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Peserta
                _buildParticipantsTab(participants, totalAmount),
                // Tab 2: Menu
                _buildItemsTab(
                  items,
                  subtotal,
                  isTaxEnabled,
                  taxPercent,
                  totalAmount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressCard(
    int paidCount,
    int totalParticipants,
    String paymentStatus,
  ) {
    double progress = totalParticipants > 0 ? paidCount / totalParticipants : 0;
    bool allPaid = paymentStatus == 'Paid';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: allPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      allPaid
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      color: allPaid ? Colors.green : Colors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        allPaid ? 'Semua sudah bayar ✓' : 'Menunggu pembayaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: allPaid ? Colors.green : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: allPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$paidCount / $totalParticipants',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: allPaid ? Colors.green : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animated progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allPaid ? Colors.green : const Color(0xFF66BB6A),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% selesai',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(
    List<Map<String, dynamic>> participants,
    double totalAmount,
  ) {
    if (participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada data peserta',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        final String participantName = participant['name'] ?? 'Unknown';
        final String phone = participant['phone'] ?? '';
        final double amount = (participant['amount'] ?? 0).toDouble();
        final bool isPaid = participant['isPaid'] ?? false;
        final bool isAdmin = participant['isAdmin'] ?? false;

        // Generate avatar color from name
        final avatarColor = isAdmin ? const Color(0xFF388E3C) : _getAvatarColor(participantName);
        final initials = _getInitials(participantName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPaid
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.15),
              width: isPaid ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [avatarColor, avatarColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name & phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              participantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                          if (!isAdmin) ...[
                            const SizedBox(width: 4),
                            Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            amount > 0 ? 'Rp ${_formatNumber(amount)}' : 'Rp -',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isPaid
                                  ? Colors.green
                                  : const Color(0xFF388E3C),
                            ),
                          ),
                          // Payment toggle + QRIS
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // QRIS button (only for unpaid NON-admin)
                              if (!isPaid && !isAdmin)
                                GestureDetector(
                                  onTap: () => _showQrisDialog(
                                    context,
                                    participantName,
                                    amount,
                                    index,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF42A5F5),
                                          Color(0xFF1E88E5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF1E88E5,
                                          ).withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              // Payment status badge
                              GestureDetector(
                                onTap: isAdmin ? null : () => _togglePaymentStatus(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? const Color(0xFF388E3C)
                                        : (isPaid
                                            ? Colors.green
                                            : Colors.orange.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isAdmin
                                          ? const Color(0xFF388E3C)
                                          : (isPaid
                                              ? Colors.green
                                              : Colors.orange.withOpacity(0.4)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAdmin
                                            ? Icons.shield_rounded
                                            : (isPaid
                                                ? Icons.check_circle
                                                : Icons.schedule),
                                        size: 14,
                                        color: isAdmin || isPaid
                                            ? Colors.white
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isAdmin ? 'Admin' : (isPaid ? 'Lunas' : 'Belum'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isAdmin || isPaid
                                              ? Colors.white
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsTab(
    List<Map<String, dynamic>> items,
    double subtotal,
    bool isTaxEnabled,
    double taxPercent,
    double totalAmount,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Tidak ada data menu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data menu tersedia untuk event baru',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Items list
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final itemName = item['name'] ?? 'Item';
          final price = (item['price'] ?? 0).toInt();
          final quantity = (item['quantity'] ?? 1).toInt();
          final orderedBy = List<String>.from(item['orderedBy'] ?? []);
          final totalPrice = price * quantity;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item number badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF388E3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF388E3C),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatNumber(price.toDouble())} × $quantity',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rp ${_formatNumber(totalPrice.toDouble())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                          if (orderedBy.isNotEmpty)
                            Text(
                              '÷ ${orderedBy.length} orang',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (orderedBy.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF388E3C).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dipesan oleh:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: orderedBy.map((name) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _getAvatarColor(
                                    name,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getAvatarColor(
                                      name,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: _getAvatarColor(name),
                                      child: Text(
                                        _getInitials(name),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _getAvatarColor(
                                          name,
                                        ).withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        // Summary card
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow('Subtotal', 'Rp ${_formatNumber(subtotal)}'),
              if (isTaxEnabled && taxPercent > 0) ...[
                const SizedBox(height: 10),
                _buildSummaryRow(
                  'Pajak (${taxPercent.toStringAsFixed(0)}%)',
                  'Rp ${_formatNumber(totalAmount - subtotal)}',
                  color: Colors.orange[700],
                ),
              ],
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${_formatNumber(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.grey[600],
            fontWeight: color != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF00BCD4),
      const Color(0xFFE91E63),
      const Color(0xFF607D8B),
      const Color(0xFF795548),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]}.',
          );
    }
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}
