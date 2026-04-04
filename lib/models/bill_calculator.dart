import 'participant_model.dart';

/// Validation result for bill calculation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<int> invalidItemIndices;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.invalidItemIndices = const [],
  });

  @override
  String toString() => isValid 
      ? 'Valid' 
      : 'Invalid: ${errors.join(", ")}';
}

/// Utility class for bill calculations with item-based splitting
class BillCalculator {
  /// Calculate bill split per participant WITHOUT tax
  /// 
  /// This performs item-based splitting without tax.
  /// Tax will be applied separately at the total level.
  /// 
  /// For each item, the base price (quantity × price) is divided only 
  /// among participants who ordered it.
  /// 
  /// Returns a Map where:
  ///   - key: participant name
  ///   - value: subtotal amount (BEFORE TAX)
  /// 
  /// To get final amounts with tax, use calculateBillPerParticipantWithTax()
  static Map<String, double> calculateBillPerParticipant(
    List<MenuItem> items,
  ) {
    final Map<String, double> participantBills = {};

    // Process each item WITHOUT tax
    for (var item in items) {
      // Skip items with no participants
      if (item.orderedBy.isEmpty) {
        continue;
      }

      // Use totalPrice (no tax), divided by participants
      final basePrice = item.totalPrice.toDouble();
      final splitAmount = basePrice / item.orderedBy.length;

      // Add split amount to each participant who ordered this item
      for (var participantName in item.orderedBy) {
        participantBills[participantName] =
            (participantBills[participantName] ?? 0) + splitAmount;
      }
    }

    return participantBills;
  }

  /// Calculate total bill amount from all items (WITHOUT tax)
  /// 
  /// Returns: sum of (item.price * item.quantity) for all items
  static double calculateTotalAmount(List<MenuItem> items) {
    double total = 0;
    for (var item in items) {
      total += item.totalPrice;
    }
    return total;
  }

  /// Get individual participant bill by name
  /// Returns 0 if participant not found
  static double getParticipantBill(
    Map<String, double> bills,
    String participantName,
  ) {
    return bills[participantName] ?? 0;
  }

  /// Get total from all participant bills (verification)
  static double getTotalFromBills(Map<String, double> bills) {
    return bills.values.fold(0, (sum, amount) => sum + amount);
  }

  /// Validate items to ensure no division by zero errors
  /// 
  /// Checks:
  /// - No items in list (returns invalid)
  /// - Items with empty orderedBy list (records as invalid)
  /// 
  /// Returns ValidationResult containing:
  /// - isValid: true if all items have at least 1 participant
  /// - errors: list of error messages
  /// - invalidItemIndices: indices of items without participants
  static ValidationResult validateItems(List<MenuItem> items) {
    final errors = <String>[];
    final invalidIndices = <int>[];

    // Check if items list is empty
    if (items.isEmpty) {
      errors.add('No items added');
      return ValidationResult(
        isValid: false,
        errors: errors,
        invalidItemIndices: invalidIndices,
      );
    }

    // Check each item for valid participants
    for (int i = 0; i < items.length; i++) {
      if (items[i].orderedBy.isEmpty) {
        invalidIndices.add(i);
        errors.add(
          'Item "${items[i].name}" has no participants assigned',
        );
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      invalidItemIndices: invalidIndices,
    );
  }

  /// Calculate bill split with validation
  /// 
  /// Returns null if validation fails, otherwise returns participant bills
  /// This prevents division by zero and ensures all items are properly assigned
  static Map<String, double>? calculateBillPerParticipantSafe(
    List<MenuItem> items,
  ) {
    final validation = validateItems(items);
    if (!validation.isValid) {
      return null;
    }
    return calculateBillPerParticipant(items);
  }

  /// Calculate subtotal from all items (price * quantity, without tax)
  /// 
  /// Returns the sum of (item.price * item.quantity) for all items
  static double calculateSubtotal(List<MenuItem> items) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.totalPrice.toDouble();
    }
    return subtotal;
  }

  /// Calculate total amount with tax applied
  /// 
  /// Parameters:
  /// - subtotal: base amount before tax
  /// - taxPercent: tax percentage (e.g., 11 for 11%)
  /// 
  /// Returns: subtotal + (subtotal * taxPercent / 100)
  static double calculateTotalWithTax(
    double subtotal,
    double taxPercent,
  ) {
    if (taxPercent <= 0) {
      return subtotal;
    }
    final taxAmount = subtotal * (taxPercent / 100);
    return subtotal + taxAmount;
  }

  /// Distribute tax proportionally to participant bills
  /// 
  /// Takes the participant split amounts and applies tax proportionally
  /// based on each participant's share of the subtotal.
  /// 
  /// Parameters:
  /// - bills: Map of participant -> amount (from calculateBillPerParticipant)
  /// - subtotal: total before tax
  /// - taxPercent: tax percentage (e.g., 11 for 11%)
  /// 
  /// Returns: Updated map with tax distributed proportionally
  static Map<String, double> applyTaxToParticipantBills(
    Map<String, double> bills,
    double subtotal,
    double taxPercent,
  ) {
    if (subtotal == 0 || taxPercent <= 0 || bills.isEmpty) {
      return bills;
    }

    final totalBefore = getTotalFromBills(bills);
    if (totalBefore == 0) {
      return bills;
    }

    // Calculate total tax to apply
    final totalWithTax = calculateTotalWithTax(subtotal, taxPercent);
    final taxAmount = totalWithTax - subtotal;

    // Distribute tax proportionally based on each participant's share
    final updatedBills = <String, double>{};
    for (final entry in bills.entries) {
      final participantAmount = entry.value;
      // Calculate this participant's share of tax
      final participantTaxShare =
          (participantAmount / subtotal) * taxAmount;
      updatedBills[entry.key] = participantAmount + participantTaxShare;
    }

    return updatedBills;
  }

  /// Calculate complete bill with item-based splitting and total-level tax
  /// 
  /// This method:
  /// 1. Validates items
  /// 2. Calculates per-participant split (based on base prices, no tax)
  /// 3. Calculates total tax on the subtotal
  /// 4. Distributes tax proportionally to each participant
  /// 
  /// Parameters:
  /// - items: List of items with participants and quantities
  /// - taxPercent: Tax percentage to apply to the total (e.g., 11 for 11%)
  /// 
  /// Returns: Map of participant -> final amount (with tax), or null if validation fails
  /// 
  /// Tax Distribution:
  /// - Total tax = subtotal × (taxPercent / 100)
  /// - Per participant tax = (participantSubtotal / subtotal) × totalTax
  /// - Final = participantSubtotal + participantTax
  static Map<String, double>? calculateBillWithTotalTax(
    List<MenuItem> items,
    double taxPercent,
  ) {
    // Validate items
    final validation = validateItems(items);
    if (!validation.isValid) {
      return null;
    }

    // Calculate base split (without tax)
    final baseBills = calculateBillPerParticipant(items);
    if (baseBills.isEmpty) {
      return null;
    }

    // Apply tax if needed
    if (taxPercent > 0) {
      final subtotal = calculateSubtotal(items);
      if (subtotal > 0) {
        return applyTaxToParticipantBills(baseBills, subtotal, taxPercent);
      }
    }

    return baseBills;
  }

  /// Legacy method - replaced by calculateBillWithTotalTax()
  /// Kept for backward compatibility
  @Deprecated('Use calculateBillWithTotalTax() instead')
  static Map<String, double>? calculateBillPerParticipantWithTaxSafe(
    List<MenuItem> items,
  ) {
    // Validate items
    final validation = validateItems(items);
    if (!validation.isValid) {
      return null;
    }

    // Calculate bill split (without tax)
    return calculateBillPerParticipant(items);
  }

  /// Verify that all items have tax enabled with proper tax percentages
  /// 
  /// Useful for debugging to ensure tax is being applied
  /// 
  /// Returns: List of items that don't have tax properly configured
  static List<MenuItem> getItemsWithoutProperTax(List<MenuItem> items) {
    return items
        .where((item) => item.includeTax && item.taxPercent <= 0)
        .toList();
  }}