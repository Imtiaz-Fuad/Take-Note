import 'dart:convert';
import 'package:http/http.dart' as http;

class BdappsService {
  static const String _baseUrl = 'https://www.bdappsdigitalapps.com/NADB26088';

  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    return _post('$_baseUrl/send_otp.php', {'user_mobile': mobile});
  }

  Future<Map<String, dynamic>> verifyOtp(String otp, String referenceNo) async {
    return _post('$_baseUrl/verify_otp.php', {
      'Otp': otp,
      'referenceNo': referenceNo,
    });
  }

  Future<Map<String, dynamic>> checkSubscription(String mobile) async {
    return _post('$_baseUrl/check_subscription.php', {'user_mobile': mobile});
  }

  Future<Map<String, dynamic>> unsubscribe(String mobile) async {
    return _post('$_baseUrl/unsubscribe.php', {'user_mobile': mobile});
  }

  Future<Map<String, dynamic>> _post(String url, Map<String, String> fields) async {
    try {
      final response = await http
          .post(Uri.parse(url), body: fields)
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'error': 'Unexpected response shape'};
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }
}