import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'participants_screen.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> with SingleTickerProviderStateMixin {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController googleMapsController = TextEditingController();
  DateTime? selectedDate;
  late AnimationController _animCtrl;

  @override
  void initState() { super.initState(); _animCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this)..forward(); }
  @override
  void dispose() { _animCtrl.dispose(); eventNameController.dispose(); locationController.dispose(); dateController.dispose(); googleMapsController.dispose(); super.dispose(); }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text("Buat Event Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: AppColors.textDark)),
        backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pop(context))),
      body: FadeTransition(opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut)),
        child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Progress
          Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: AppColors.primarySofter, borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.25,
              child: Container(decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(3))))),
          const SizedBox(height: 16),
          Text('Step 1 dari 4', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),

          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.event, color: Colors.white, size: 18)),
                const SizedBox(width: 12),
                Text('Detail Event', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ]),
              const SizedBox(height: 20),
              _label('Nama Event'),
              TextField(controller: eventNameController, style: GoogleFonts.poppins(color: AppColors.textDark),
                decoration: AppDecorations.input(hintText: 'Nama Event', prefixIcon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20))),
              const SizedBox(height: 20),
              _label('Nama Tempat'),
              TextField(controller: locationController, style: GoogleFonts.poppins(color: AppColors.textDark),
                decoration: AppDecorations.input(hintText: 'Contoh: Starbucks GI', prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 20))),
              const SizedBox(height: 20),
              _label('Link Google Maps (Opsional)'),
              TextField(controller: googleMapsController, style: GoogleFonts.poppins(color: AppColors.textDark),
                decoration: AppDecorations.input(hintText: 'Tempel link di sini', prefixIcon: Icon(Icons.map_outlined, color: AppColors.textSecondary, size: 20),
                  suffixIcon: GestureDetector(onTap: () => googleMapsController.clear(), child: Icon(Icons.clear, color: AppColors.textHint, size: 18)))),
              const SizedBox(height: 20),
              _label('Tanggal'),
              GestureDetector(onTap: () => _selectDate(context),
                child: AbsorbPointer(child: TextField(controller: dateController, style: GoogleFonts.poppins(color: AppColors.textDark),
                  decoration: AppDecorations.input(hintText: 'mm/dd/yyyy', prefixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20))))),
            ]),
          ),
          const SizedBox(height: 32),
          GradientButton(
            onPressed: () {
              if (eventNameController.text.isEmpty || locationController.text.isEmpty || dateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mohon isi semua field yang diperlukan', style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (c) => ParticipantsScreen(
                  eventName: eventNameController.text, location: locationController.text,
                  date: selectedDate, googleMapsLink: googleMapsController.text,
                ))).then((v) { if (v != null) Navigator.pop(context, v); });
              }
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Lanjut', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8), const Icon(Icons.arrow_forward, color: Colors.white),
            ]),
          ),
        ])))),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030),
      builder: (c, ch) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: Colors.white)), child: ch!));
    if (picked != null && picked != selectedDate) setState(() { selectedDate = picked; dateController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}"; });
  }
}