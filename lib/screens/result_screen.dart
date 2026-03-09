import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';
import 'payment_status_screen.dart';

class ResultScreen extends StatelessWidget {
  final String? eventName;
  final String? location;
  final DateTime? date;
  final String? googleMapsLink;
  final List<Participant>? participants;
  final List<MenuItem>? items;

  ResultScreen({
    this.eventName,
    this.location,
    this.date,
    this.googleMapsLink,
    this.participants,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    double totalAmount = 0;
    if (items != null) {
      for (var item in items!) {
        totalAmount += item.priceWithTax;
      }
    }

    double splitAmount = participants != null && participants!.isNotEmpty
        ? totalAmount / participants!.length
        : 0;

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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
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
                        eventName ?? 'Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(location ?? 'Lokasi tidak diketahui',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            date != null
                                ? '${date!.day}/${date!.month}/${date!.year}'
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
              if (items != null && items!.isNotEmpty) ...[
                Text(
                  'Item-item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                ...items!.map((item) => Padding(
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
                                'x${item.quantity}${item.includeTax ? ' (+11% tax)' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Rp ${item.priceWithTax}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    )),
                Divider(height: 20),
              ],

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rp ${totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Participants and split
              Text(
                'Peserta (${participants?.length ?? 0})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              if (participants != null)
                ...participants!.map((participant) => Padding(
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                              'Rp ${splitAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              SizedBox(height: 32),

              // Split per orang
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
                      'Bayar per orang',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rp ${splitAmount.toStringAsFixed(0)}',
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
                  onPressed: () {
                    // Create event
                    final newEvent = Event(
                      id: DateTime.now().toString(),
                      name: eventName ?? 'Event',
                      location: location ?? 'Lokasi',
                      date: date ?? DateTime.now(),
                      status: 'Active',
                      paidCount: 0,
                      totalParticipants: participants?.length ?? 0,
                      imageUrl: 'assets/event.jpg',
                      totalAmount: totalAmount,
                      paymentStatus: 'Unpaid',
                    );

                    // Generate reference number
                    final refNumber = 'INV-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}${DateTime.now().hour.toString().padLeft(2, '0')}${DateTime.now().second.toString().padLeft(2, '0')}';
                    
                    // Navigate to payment status screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentStatusScreen(
                          event: newEvent,
                          paidBy: participants?.isNotEmpty == true
                              ? participants!.first.name
                              : 'Pembayar',
                          refNumber: refNumber,
                        ),
                      ),
                    ).then((value) {
                      // After payment, return to home with event data
                      if (value == null) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        Navigator.pop(context, newEvent);
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
                  child: Text(
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