import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import '../models/event_model.dart';
import '../models/participant_model.dart';
import '../models/bill_calculator.dart';
//import 'payment_status_screen.dart';
import 'dashboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final String? eventName;
  final String? location;
  final DateTime? date;
  final String? googleMapsLink;
  final List<Participant>? participants;
  final List<MenuItem>? items;
  final bool isTaxEnabled;
  final double taxPercent;

  const ResultScreen({
    super.key,
    this.eventName,
    this.location,
    this.date,
    this.googleMapsLink,
    this.participants,
    this.items,
    this.isTaxEnabled = false,
    this.taxPercent = 0.0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    // ===== GLOBAL TAX CALCULATION FLOW =====
    // This section calculates the bill using global tax (not item-level)

    // STEP 1: Calculate subtotal (sum of all items, NO tax)
    double subtotal = 0;
    if (widget.items != null) {
      for (var item in widget.items!) {
        subtotal += item.totalPrice;
      }
    }

    // STEP 2: Get global tax settings from event level (not from items)
    // isTaxEnabled and taxPercent are set once at event creation
    double taxPercent = widget.isTaxEnabled ? widget.taxPercent : 0.0;

    // STEP 3: Calculate total amount with global tax applied ONCE
    // Formula: totalAmount = subtotal + (subtotal × taxPercent / 100)
    // Tax is NOT recalculated per item
    double totalAmount = subtotal;
    if (taxPercent > 0) {
      totalAmount = BillCalculator.calculateTotalWithTax(subtotal, taxPercent);
    }

    // STEP 4: Calculate participant bills with proportional tax distribution
    // Uses BillCalculator.calculateBillWithTotalTax() which:
    //   a) Calculates base split (items ÷ participants)
    //   b) Calculates total tax (subtotal × taxPercent / 100)
    //   c) Distributes tax proportionally to each participant
    Map<String, double>? participantBills;
    String? validationError;

    if (widget.items != null && widget.items!.isNotEmpty) {
      participantBills = BillCalculator.calculateBillWithTotalTax(
        widget.items!,
        taxPercent,
      );
      if (participantBills == null) {
        final validation = BillCalculator.validateItems(widget.items!);
        validationError = validation.errors.join('\n');
      }
    }
    // ===== END CALCULATION FLOW =====

    return Scaffold(
      appBar: AppBar(
        title: Text("Hasil Split"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                    value: 1.0,
                    minHeight: 4,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Step 4 dari 4',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              SizedBox(height: 16),
              // Event info card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.eventName ?? 'Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            widget.location ?? 'Lokasi tidak diketahui',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            widget.date != null
                                ? '${widget.date!.day}/${widget.date!.month}/${widget.date!.year}'
                                : 'Tanggal tidak diketahui',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Items section
              if (widget.items != null && widget.items!.isNotEmpty) ...[
                Text(
                  'Item-item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                ...widget.items!.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${item.totalPrice}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 20),
              ],

              // Total breakdown with tax details
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtotal row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Rp ${subtotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    // Tax row (if applicable)
                    if (taxPercent > 0) ...[
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pajak (${taxPercent.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Rp ${(totalAmount - subtotal).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Divider
                    SizedBox(height: 12),
                    Container(height: 1, color: Colors.grey[300]),
                    // Grand total row
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Rp ${totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Participants and split
              Text(
                'Peserta (${widget.participants?.length ?? 0})',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              if (validationError != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Validation Error:\n$validationError',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              else if (widget.participants != null)
                ...widget.participants!.map((participant) {
                  final participantAmount =
                      participantBills?[participant.name] ?? 0.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                participant.name,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (participant.phoneNumber.isNotEmpty)
                                Text(
                                  participant.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'Rp ${participantAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              SizedBox(height: 32),

              // Split per orang (average)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata per orang',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      participantBills != null && participantBills.isNotEmpty
                          ? 'Rp ${(BillCalculator.getTotalFromBills(participantBills) / widget.participants!.length).toStringAsFixed(0)}'
                          : 'Rp 0',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Tombol Simpan Event
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() {
                            _isSaving = true;
                          });

                          try {
                            final userId =
                                FirebaseAuth.instance.currentUser!.uid;

                            // Build detailed participant data with bill amounts
                            final participantDetails =
                                widget.participants?.map((p) {
                                  final amount =
                                      participantBills?[p.name] ?? 0.0;
                                  return {
                                    'name': p.name,
                                    'phone': p.phoneNumber,
                                    'amount': amount,
                                    'isPaid': false,
                                  };
                                }).toList() ??
                                [];

                            // Build detailed items data
                            final itemDetails =
                                widget.items?.map((item) {
                                  return {
                                    'name': item.name,
                                    'price': item.price,
                                    'quantity': item.quantity,
                                    'orderedBy': item.orderedBy,
                                  };
                                }).toList() ??
                                [];

                            // Save to Firestore with full details
                            await FirebaseFirestore.instance
                                .collection('events')
                                .add({
                                  'name': widget.eventName ?? 'Event',
                                  'location': widget.location ?? 'Lokasi',
                                  'date': widget.date != null
                                      ? Timestamp.fromDate(widget.date!)
                                      : Timestamp.now(),
                                  'createdBy': userId,
                                  'participants': participantDetails,
                                  'items': itemDetails,
                                  'totalAmount': totalAmount,
                                  'subtotal': subtotal,
                                  'isTaxEnabled': widget.isTaxEnabled,
                                  'taxPercent': widget.isTaxEnabled
                                      ? widget.taxPercent
                                      : 0.0,
                                  'status': 'Active',
                                  'paidCount': 0,
                                  'totalParticipants':
                                      widget.participants?.length ?? 0,
                                  'paymentStatus': 'Unpaid',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => DashboardScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal menyimpan event: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan Event',
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
      ),
    );
  }
}
