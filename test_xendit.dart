import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String xenditSecretKey = 'xnd_development_zpVl3pSPbIc2SPTW5Uc114lKW4Ms3YzJdCz8cUi0pkjYAMsDXo5kGovaZl9sqY';
  final String basicAuth = 'Basic ' + base64Encode(utf8.encode('$xenditSecretKey:'));

  try {
    final response = await http.post(
      Uri.parse('https://api.xendit.co/qr_codes'),
      headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
        'api-version': '2022-07-31',
      },
      body: jsonEncode({
        'reference_id': 'test-12345',
        'type': 'DYNAMIC',
        'currency': 'IDR',
        'amount': 10000,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
