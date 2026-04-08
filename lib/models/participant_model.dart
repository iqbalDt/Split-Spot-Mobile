class Participant {
  final String name;
  final String phoneNumber;

  Participant({
    required this.name,
    required this.phoneNumber,
  });
}

class MenuItem {
  final String name;
  final int price;
  int quantity;
  List<String> orderedBy;

  MenuItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.orderedBy = const [],
  });

  int get totalPrice => price * quantity;

  /// Calculate the split price per person (BASE price, WITHOUT tax)
  /// 
  /// Tax is applied at the total bill level, not per item.
  /// For final amounts with tax, use BillCalculator.calculateBillWithTotalTax()
  /// 
  /// Returns: totalPrice / number of participants (no tax included)
  double get splitPricePerPerson {
    if (orderedBy.isEmpty) {
      return 0.0;
    }
    // Use totalPrice only (no tax) - tax is applied at bill level
    return totalPrice / orderedBy.length;
  }

  /// Check if this item is valid for bill calculation
  /// Valid items must have at least 1 participant
  bool get isValid => orderedBy.isNotEmpty;

  /// Get validation error message if item is invalid
  /// Returns null if valid
  String? get validationError {
    if (orderedBy.isEmpty) {
      return 'Item "$name" must have at least 1 participant';
    }
    return null;
  }

  /// Add a participant to this item
  void addParticipant(String participantName) {
    if (!orderedBy.contains(participantName)) {
      orderedBy.add(participantName);
    }
  }

  /// Remove a participant from this item
  void removeParticipant(String participantName) {
    orderedBy.remove(participantName);
  }

  /// Check if a specific participant ordered this item
  bool participantOrdered(String participantName) {
    return orderedBy.contains(participantName);
  }
}
