import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class RekeningScreen extends StatefulWidget {
  @override
  State<RekeningScreen> createState() => _RekeningScreenState();
}

class _RekeningScreenState extends State<RekeningScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _popularOptions = [
    {'name': 'BCA', 'icon': Icons.account_balance, 'type': 'bank'},
    {'name': 'Mandiri', 'icon': Icons.account_balance, 'type': 'bank'},
    {'name': 'BNI', 'icon': Icons.account_balance, 'type': 'bank'},
    {'name': 'BRI', 'icon': Icons.account_balance, 'type': 'bank'},
    {'name': 'GoPay', 'icon': Icons.account_balance_wallet, 'type': 'ewallet'},
    {'name': 'OVO', 'icon': Icons.account_balance_wallet, 'type': 'ewallet'},
    {'name': 'DANA', 'icon': Icons.account_balance_wallet, 'type': 'ewallet'},
    {'name': 'ShopeePay', 'icon': Icons.account_balance_wallet, 'type': 'ewallet'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _bankNameController.text = data['bankName']?.toString() ?? '';
        _bankAccountController.text = data['bankAccount']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error loading rekening: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    if (_currentUser == null) return;
    if (_bankNameController.text.trim().isEmpty || _bankAccountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon lengkapi semua kolom'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'bankName': _bankNameController.text.trim(),
        'bankAccount': _bankAccountController.text.trim(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Data rekening berhasil disimpan!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Rekening & E-Wallet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textDark),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terima Pembayaran',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Data ini akan ditampilkan ke anggota patungan agar mereka mudah membayar.',
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textBody),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  Text(
                    'Pilih Bank / E-Wallet Cepat',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _popularOptions.map((opt) {
                      final isSelected = _bankNameController.text.trim().toLowerCase() == opt['name'].toString().toLowerCase();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _bankNameController.text = opt['name'];
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))] : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt['icon'] as IconData, 
                                size: 16, 
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                opt['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),

                  // Form
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Bank / E-Wallet',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _bankNameController,
                          style: GoogleFonts.poppins(color: AppColors.textDark),
                          decoration: AppDecorations.input(
                            hintText: 'Atau ketik nama bank/e-wallet',
                            prefixIcon: Icon(Icons.account_balance, color: AppColors.textHint),
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        Text(
                          'Nomor Rekening / No. HP',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _bankAccountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: AppColors.textDark),
                          decoration: AppDecorations.input(
                            hintText: 'Contoh: 1234567890',
                            prefixIcon: Icon(Icons.numbers, color: AppColors.textHint),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: _isSaving ? null : _saveData,
                      isLoading: _isSaving,
                      child: Text(
                        'Simpan Data',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }
}
