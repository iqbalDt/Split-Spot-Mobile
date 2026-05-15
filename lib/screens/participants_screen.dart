import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'items_screen.dart';
import '../models/participant_model.dart';

class ParticipantsScreen extends StatefulWidget {
  final String? eventName;
  final String? location;
  final DateTime? date;
  final String? googleMapsLink;

  ParticipantsScreen({
    this.eventName,
    this.location,
    this.date,
    this.googleMapsLink,
  });

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen>
    with SingleTickerProviderStateMixin {
  final List<Participant> participants = [];
  late AnimationController _bannerAnimCtrl;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _bannerAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _bannerAnimCtrl.dispose();
    super.dispose();
  }

  bool get _hasAdminSelf => participants.any((p) => p.isAdmin && p.name.contains('(Admin)'));

  void _addSelfAsAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Anda';

    // Check if already added
    if (_hasAdminSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda sudah terdaftar sebagai Admin'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      participants.insert(
        0,
        Participant(
          name: '$displayName (Admin)',
          phoneNumber: user?.phoneNumber ?? '',
          isAdmin: true,
        ),
      );
      _bannerDismissed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Berhasil! Anda ditambahkan sebagai Admin'),
          ],
        ),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Peserta"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 0.5,
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 16),
            // Step indicator
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Step 2 dari 4',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${participants.length} Peserta Terdaftar',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kelola peserta untuk pembagian tagihan ini',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // Admin Banner
            if (!_bannerDismissed && !_hasAdminSelf) _buildAdminBanner(),

            // Daftar peserta
            Expanded(
              child: participants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada peserta',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tambahkan peserta atau jadikan diri Anda sebagai admin',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return _buildParticipantCard(participant, index);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Tombol Tambah Peserta
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showAddParticipantDialog(context, null, -1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '+ Tambah Peserta',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tombol Lanjut
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (participants.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Tambahkan minimal 1 peserta'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemsScreen(
                          eventName: widget.eventName,
                          location: widget.location,
                          date: widget.date,
                          googleMapsLink: widget.googleMapsLink,
                          participants: participants,
                        ),
                      ),
                    ).then((value) {
                      if (value != null) {
                        Navigator.pop(context, value);
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Lanjut',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Admin Banner ──────────────────────────────────────────
  Widget _buildAdminBanner() {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _bannerAnimCtrl, curve: Curves.easeOut),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF388E3C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anda yang membayar duluan?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tandai diri Anda sebagai penanggung jawab. Status Anda otomatis lunas.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: const Color(0xFF2E7D32).withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                GestureDetector(
                  onTap: () => setState(() => _bannerDismissed = true),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: const Color(0xFF388E3C).withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addSelfAsAdmin,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  'Ya, Saya Penanggungnya',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Participant Card ──────────────────────────────────────
  Widget _buildParticipantCard(Participant participant, int index) {
    final bool isAdmin = participant.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFFF1F8E9) : Colors.white,
          border: Border.all(
            color: isAdmin
                ? const Color(0xFF66BB6A).withOpacity(0.5)
                : Colors.grey[300]!,
            width: isAdmin ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isAdmin
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar with admin badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  backgroundColor: isAdmin
                      ? const Color(0xFF388E3C)
                      : Colors.green[100],
                  radius: 20,
                  child: Text(
                    participant.name[0].toUpperCase(),
                    style: TextStyle(
                      color: isAdmin ? Colors.white : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isAdmin)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 12,
                        color: Color(0xFFFF8F00),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          participant.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isAdmin
                                ? const Color(0xFF1B5E20)
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (participant.phoneNumber.isNotEmpty)
                    Text(
                      participant.phoneNumber,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Otomatis lunas • Penanggung jawab',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF388E3C).withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                onPressed: () {
                  _showAddParticipantDialog(context, participant, index);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    participants.removeAt(index);
                  });
                },
              ),
            ] else ...[
              // Admin removal with confirmation
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red[300],
                  size: 20,
                ),
                onPressed: () => _confirmRemoveAdmin(index),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRemoveAdmin(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Admin?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: const Text(
          'Yakin ingin menghapus penanggung jawab ini dari daftar peserta?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => participants.removeAt(index));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Add Participant Dialog ────────────────────────────────
  void _showAddParticipantDialog(
    BuildContext context,
    Participant? participant,
    int index,
  ) {
    final nameController = TextEditingController(text: participant?.name ?? '');
    final phoneController =
        TextEditingController(text: participant?.phoneNumber ?? '');
    bool isAdminToggle = participant?.isAdmin ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          index >= 0 ? 'Edit Peserta' : 'Tambah Anggota Baru',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nama Anggota',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Budi Santoso',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nomor HP (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '0812...',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Admin Toggle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isAdminToggle
                            ? const Color(0xFF388E3C).withOpacity(0.08)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAdminToggle
                              ? const Color(0xFF388E3C).withOpacity(0.3)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 20,
                            color: isAdminToggle
                                ? const Color(0xFF388E3C)
                                : Colors.grey[400],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tandai sebagai Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                    color: isAdminToggle
                                        ? const Color(0xFF1B5E20)
                                        : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Penanggung jawab, otomatis lunas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isAdminToggle
                                        ? const Color(0xFF388E3C)
                                            .withOpacity(0.7)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isAdminToggle,
                            onChanged: (val) {
                              setSheetState(() => isAdminToggle = val);
                            },
                            activeColor: const Color(0xFF388E3C),
                            activeTrackColor: const Color(0xFF66BB6A),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Nama tidak boleh kosong'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final newParticipant = Participant(
                            name: nameController.text,
                            phoneNumber: phoneController.text,
                            isAdmin: isAdminToggle,
                          );

                          setState(() {
                            if (index >= 0) {
                              participants[index] = newParticipant;
                            } else {
                              participants.add(newParticipant);
                            }
                          });

                          Navigator.pop(sheetCtx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}