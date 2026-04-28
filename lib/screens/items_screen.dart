import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'result_screen.dart';
import '../models/participant_model.dart';

class ItemsScreen extends StatefulWidget {
  final String? eventName;
  final String? location;
  final DateTime? date;
  final String? googleMapsLink;
  final List<Participant>? participants;
  final bool isTaxEnabled;
  final double taxPercent;

  const ItemsScreen({
    super.key,
    this.eventName,
    this.location,
    this.date,
    this.googleMapsLink,
    this.participants,
    this.isTaxEnabled = false,
    this.taxPercent = 0.0,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final List<MenuItem> items = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  late final TextEditingController taxController = TextEditingController(
    text: widget.taxPercent > 0 ? widget.taxPercent.toString() : '',
  );
  List<String> selectedParticipants = [];
  int currentQuantity = 1;
  late bool isTaxEnabled = widget.isTaxEnabled;
  late double customTaxPercent = widget.taxPercent;

  int totalMenuPrice = 0;

  void _updateTotal() {
    int total = 0;
    for (var item in items) {
      // Only sum base price (no tax) for subtotal display
      total += item.totalPrice;
    }
    setState(() {
      totalMenuPrice = total;
    });
  }

  /// Parse and validate tax percentage input
  /// Returns true if valid, false otherwise
  bool _validateAndUpdateTax(String value) {
    if (value.isEmpty) {
      setState(() {
        customTaxPercent = 0.0;
      });
      return true;
    }

    try {
      final taxValue = double.parse(value);
      if (taxValue < 0 || taxValue > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pajak harus antara 0-100%'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1500),
          ),
        );
        return false;
      }
      setState(() {
        customTaxPercent = taxValue;
      });
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan angka yang valid'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  /// Show dialog to select multiple participants
  void _showParticipantSelector() {
    if (widget.participants == null || widget.participants!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tambahkan peserta terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, dialogSetState) {
            return AlertDialog(
              title: Text('Pilih Pemesan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.participants!.map((participant) {
                    final isSelected =
                        selectedParticipants.contains(participant.name);
                    return CheckboxListTile(
                      title: Text(participant.name),
                      subtitle: Text(
                        participant.phoneNumber,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: isSelected,
                      activeColor: Colors.green,
                      onChanged: (isChecked) {
                        // Update both the dialog UI and the parent state
                        dialogSetState(() {
                          if (isChecked == true) {
                            if (!selectedParticipants
                                .contains(participant.name)) {
                              selectedParticipants.add(participant.name);
                            }
                          } else {
                            selectedParticipants.remove(participant.name);
                          }
                        });
                        // Also update the parent widget state
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Selesai',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah Menu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    items.clear();
                    nameController.clear();
                    priceController.clear();
                    selectedParticipants.clear();
                    currentQuantity = 1;
                    _updateTotal();
                  });
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 4,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                ],
              ),
              // Step indicator
              Text(
                'Step 3 dari 4',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 8),

              // Total Harga Menu
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Harga Menu',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Rp ${totalMenuPrice.toString()}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Nama Menu
              Text(
                'Nama Menu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Pizza Large',
                  prefixIcon: Icon(Icons.restaurant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Harga dan Jumlah
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga (Rp)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            hintText: '0',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 12, right: 8),
                              child: Text(
                                'Rp',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (currentQuantity > 1) {
                                        currentQuantity--;
                                      }
                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                      '−',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '$currentQuantity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentQuantity++;
                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                      '+',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Tax/Service Configuration
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isTaxEnabled ? Colors.green[300]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isTaxEnabled ? Colors.green[50] : Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: isTaxEnabled ? Colors.green : Colors.grey,
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pajak / Service',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Masukkan persentase pajak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isTaxEnabled,
                          onChanged: (value) {
                            setState(() {
                              isTaxEnabled = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                    if (isTaxEnabled) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: taxController,
                              keyboardType: TextInputType.number,
                              onChanged: _validateAndUpdateTax,
                              decoration: InputDecoration(
                                hintText: 'Contoh: 11',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                suffixText: '%',
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${customTaxPercent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Pilih Pemesan
              GestureDetector(
                onTap: _showParticipantSelector,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.green[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_alt_outlined, color: Colors.green),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Pemesan',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                selectedParticipants.isEmpty
                                    ? 'Siapa yang memesan ini?'
                                    : '${selectedParticipants.length} peserta dipilih',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.chevron_right, color: Colors.green),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Tombol Simpan Menu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Isi nama dan harga menu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (selectedParticipants.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pilih setidaknya 1 pemesan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final priceText = priceController.text.replaceAll('.', '');
                    final newItem = MenuItem(
                      name: nameController.text,
                      price: int.parse(priceText),
                      quantity: currentQuantity,
                      orderedBy: List<String>.from(selectedParticipants),
                    );

                    setState(() {
                      items.add(newItem);
                      nameController.clear();
                      priceController.clear();
                      selectedParticipants.clear();
                      currentQuantity = 1;
                      _updateTotal();
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu "${newItem.name}" ditambahkan'),
                        backgroundColor: Colors.green,
                        duration: Duration(milliseconds: 1500),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '✓ Simpan Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Daftar Menu
              if (items.isNotEmpty) ...[
                Text(
                  'Menu Terpilih',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.name} (x${item.quantity})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Rp ${(item.price * item.quantity).toString()}',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      items.removeAt(index);
                                      _updateTotal();
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Display participants
                            if (item.orderedBy.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dipesan oleh:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      children: item.orderedBy
                                          .map(
                                            (participant) => Chip(
                                              label: Text(
                                                participant,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              backgroundColor:
                                                  Colors.green[200],
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                'Tidak ada pemesan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                // Tombol Lanjut ke Result
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(
                            eventName: widget.eventName,
                            location: widget.location,
                            date: widget.date,
                            googleMapsLink: widget.googleMapsLink,
                            participants: widget.participants,
                            items: items,
                            isTaxEnabled: isTaxEnabled,
                            taxPercent: customTaxPercent,
                          ),
                        ),
                      ).then((value) {
                        if (value != null) {
                          Navigator.pop(context, value);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    taxController.dispose();
    super.dispose();
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < numericOnly.length; i++) {
      if (i > 0 && (numericOnly.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(numericOnly[i]);
    }

    final formattedString = buffer.toString();
    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}