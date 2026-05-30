import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000/api', // emulator
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getCurrentPlan() async {
    final token = await _token();

    final res = await _dio.get(
      '/plan/current',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return res.data;
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String plan,
    required String billingCycle,
    required String paymentMethod,
  }) async {
    final token = await _token();

    final res = await _dio.post(
      '/payment/initiate',
      data: {
        'plan': plan,
        'billing_cycle': billingCycle,
        'payment_method': paymentMethod,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return res.data;
  }

  Future<Map<String, dynamic>> confirmPayment({
    required int subscriptionId,
    required String transactionId,
  }) async {
    final token = await _token();

    final res = await _dio.post(
      '/payment/confirm',
      data: {
        'subscription_id': subscriptionId,
        'transaction_id': transactionId,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return res.data;
  }
}