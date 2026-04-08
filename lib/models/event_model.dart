class Event {
  final String id;
  final String name;
  final String location;
  final DateTime date;
  final String status; // Active, Completed
  final int paidCount;
  final int totalParticipants;
  final String imageUrl;
  final double totalAmount;
  final String paymentStatus; // Paid, Unpaid, Belum Bayar
  bool isTaxEnabled;
  double taxPercent;

  Event({
    required this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.status,
    required this.paidCount,
    required this.totalParticipants,
    required this.imageUrl,
    required this.totalAmount,
    required this.paymentStatus,
    this.isTaxEnabled = false,
    this.taxPercent = 0.0,
  });
}
