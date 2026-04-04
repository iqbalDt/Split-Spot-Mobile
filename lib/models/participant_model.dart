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
  bool includeTax;
  double taxPercent;
  List<String> orderedBy;

  MenuItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.includeTax = false,
    this.taxPercent = 0.0,
    this.orderedBy = const [],
  });

  int get totalPrice => price * quantity;
  
  /// Get price with tax (for display purposes only)
  /// 
  /// NOTE: For bill calculations, tax is applied at the TOTAL level using BillCalculator,
  /// not at the item level. This getter is only for UI display.
  int get priceWithTax {
    if (includeTax && taxPercent > 0) {
      // Dynamic tax calculation: total * (1 + taxPercent/100)
      final taxMultiplier = 1 + (taxPercent / 100);
      return (totalPrice * taxMultiplier).toInt();
    }
    return totalPrice;
  }

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
