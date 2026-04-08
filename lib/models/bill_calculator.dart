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

/// Utility class for bill calculations with item-based splitting and GLOBAL tax
/// 
/// CALCULATION FLOW (GLOBAL TAX MODEL):
/// 
/// Step 1: Calculate base bill (without tax)
///   - For each item: splitAmount = (item.price × item.quantity) ÷ number of participants
///   - Sum for each participant across all items they ordered
///   - Result: participantSubtotal (BEFORE TAX)
/// 
/// Step 2: Calculate tax amount ONCE at total level
///   - subtotal = sum of all items (no tax)
///   - taxAmount = subtotal × (taxPercent ÷ 100)
///   - Tax is calculated once, not per item
/// 
/// Step 3: Distribute tax proportionally
///   - For each participant: 
///     participantTax = (participantSubtotal ÷ subtotal) × taxAmount
///   - This ensures fair distribution based on each person's share
///   - Final amount = participantSubtotal + participantTax
/// 
/// KEY PRINCIPLES:
/// - NO item-level tax (removed from MenuItem model)
/// - Tax applied only once to entire bill
/// - Participants with higher bills pay more tax
/// - Clean separation: items handle pricing, tax handled globally
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

  /// Calculate subtotal from all items (price × quantity, WITHOUT tax)
  /// 
  /// This is step 2 in the global tax calculation:
  /// - Sums all item prices (no tax included)
  /// - Used as the base for one-time tax calculation
  /// - Does NOT multiply by any tax percentage
  /// 
  /// Formula: subtotal = Σ(item.price × item.quantity) for all items
  /// 
  /// Returns the sum of (item.price × item.quantity) for all items
  static double calculateSubtotal(List<MenuItem> items) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.totalPrice.toDouble();
    }
    return subtotal;
  }

  /// Calculate total amount with GLOBAL tax applied once
  /// 
  /// This calculates the total tax amount to distribute.
  /// Tax is applied ONCE to the entire bill, not per item.
  /// 
  /// Formula: totalWithTax = subtotal + (subtotal × taxPercent / 100)
  /// 
  /// EXAMPLE:
  ///   subtotal = 100,000 IDR
  ///   taxPercent = 11
  ///   taxAmount = 100,000 × (11 / 100) = 11,000 IDR
  ///   totalWithTax = 100,000 + 11,000 = 111,000 IDR
  /// 
  /// Parameters:
  /// - subtotal: Base amount before tax (sum of all items, no tax)
  /// - taxPercent: Tax percentage (e.g., 11 for 11%, 0 for no tax)
  /// 
  /// Returns: SubTotal + (subtotal × taxPercent / 100), or subtotal if taxPercent ≤ 0
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

  /// Distribute global tax proportionally to participant bills
  /// 
  /// PROPORTIONAL TAX DISTRIBUTION FORMULA:
  ///   participantTax = (participantBill / subtotal) × totalTaxAmount
  /// 
  /// This ensures participants pay tax in proportion to their share of the bill.
  /// 
  /// EXAMPLE:
  ///   subtotal = 100k, tax 10% (taxAmount = 10k), taxPercent = 10
  ///   - Participant A's bill: 40k (40% of bill) → tax share = 4k → final = 44k
  ///   - Participant B's bill: 30k (30% of bill) → tax share = 3k → final = 33k
  ///   - Participant C's bill: 30k (30% of bill) → tax share = 3k → final = 33k
  ///   Total: 100k + 10k = 110k ✓
  /// 
  /// Parameters:
  /// - bills: Map of participant → subtotal (BEFORE tax)
  /// - subtotal: Total of all items (no tax)
  /// - taxPercent: Tax percentage (e.g., 11 for 11%)
  /// 
  /// Returns: Updated map with tax distributed proportionally
  /// 
  /// IMPORTANT: This is only called by calculateBillWithTotalTax()
  /// Do NOT call this directly - use calculateBillWithTotalTax() instead
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

    // Calculate total tax amount to distribute (one-time calculation)
    final totalWithTax = calculateTotalWithTax(subtotal, taxPercent);
    final taxAmount = totalWithTax - subtotal;

    // Distribute tax proportionally based on each participant's share
    // participantTax = (participantAmount / subtotal) × taxAmount
    final updatedBills = <String, double>{};
    for (final entry in bills.entries) {
      final participantAmount = entry.value;
      // Calculate this participant's proportional share of tax
      final participantTaxShare =
          (participantAmount / subtotal) * taxAmount;
      updatedBills[entry.key] = participantAmount + participantTaxShare;
    }

    return updatedBills;
  }

  /// Calculate complete bill with item-based splitting and GLOBAL total-level tax
  /// 
  /// GLOBAL TAX CALCULATION (replaces per-item tax):
  /// 
  /// Step 1: Validate items
  ///   - Ensures all items have at least 1 participant (no division by zero)
  /// 
  /// Step 2: Calculate base split WITHOUT tax
  ///   - Each item's cost is divided only among participants who ordered it
  ///   - Participants are summed across all items
  ///   - Example: Alice ordered Pizza (20k, shared with Bob), Drink (10k alone)
  ///     → Alice's base = 10k (pizza share) + 10k (drink) = 20k
  /// 
  /// Step 3: Apply tax ONCE to entire bill
  ///   - Tax amount = subtotal × (taxPercent / 100)
  ///   - Example: subtotal = 100k, tax 10% → taxAmount = 10k
  ///   - Tax is NOT recalculated per item or per participant
  /// 
  /// Step 4: Distribute tax proportionally
  ///   - Each participant pays tax based on their share of the subtotal
  ///   - participantTax = (participantBase / subtotal) × totalTax
  ///   - Final = participantBase + participantTax
  ///   - This ensures fair tax distribution
  /// 
  /// FLOW DIAGRAM:
  ///   Items → Base Bills → Total Tax (once) → Distribute Tax → Final Bills
  /// 
  /// Parameters:
  /// - items: List of menu items with participants (NO item-level tax fields)
  /// - taxPercent: Global tax percentage applied at end (0 = no tax, 11 = 11%)
  /// 
  /// Returns: 
  /// - Map of participant name → final amount (with tax included)
  /// - null if validation fails (e.g., items without participants)
  /// 
  /// IMPORTANT: Tax is applied ONCE globally, not per item.
  /// This method is the single entry point for tax calculations.
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

    // Apply tax if needed (global, one-time calculation)
    if (taxPercent > 0) {
      final subtotal = calculateSubtotal(items);
      if (subtotal > 0) {
        return applyTaxToParticipantBills(baseBills, subtotal, taxPercent);
      }
    }

    return baseBills;
  }

}