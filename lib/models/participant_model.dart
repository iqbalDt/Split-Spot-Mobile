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
  String? orderedBy;

  MenuItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.includeTax = false,
    this.orderedBy,
  });

  int get totalPrice => price * quantity;
  int get priceWithTax {
    if (includeTax) {
      return (totalPrice * 1.11).toInt();
    }
    return totalPrice;
  }
}
