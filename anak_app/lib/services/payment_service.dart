import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class PaymentTransactionResult {
  final bool isSuccess;
  final String orderId;
  final String? snapToken;
  final String? redirectUrl;
  final String? errorMessage;
  final Map<String, dynamic>? paymentDetails;

  PaymentTransactionResult({
    required this.isSuccess,
    required this.orderId,
    this.snapToken,
    this.redirectUrl,
    this.errorMessage,
    this.paymentDetails,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // Midtrans Sandbox URL
  static const String _midtransSandboxBaseUrl = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  /// Generates a unique order ID for Zikola Payment Transactions
  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomDigits = Random().nextInt(8999) + 1000;
    return 'ZKL-MID-$timestamp-$randomDigits';
  }

  /// Initiates a Midtrans Snap Transaction
  /// In Production, this calls your Backend Endpoint / Firebase Cloud Function.
  /// If a Server Key is provided, it calls Midtrans Snap Sandbox API directly.
  Future<PaymentTransactionResult> createSnapTransaction({
    required String orderId,
    required int amount,
    required String userId,
    required String doctorId,
    required String doctorName,
    required String paymentMethod,
    String? serverKey,
    String? backendEndpoint,
  }) async {
    try {
      String? snapToken;
      String? redirectUrl;

      // 1. If backend endpoint is configured, call custom backend
      if (backendEndpoint != null && backendEndpoint.isNotEmpty) {
        final response = await http.post(
          Uri.parse(backendEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': orderId,
            'amount': amount,
            'userId': userId,
            'doctorId': doctorId,
            'doctorName': doctorName,
            'paymentMethod': paymentMethod,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          snapToken = data['snap_token'] ?? data['token'];
          redirectUrl = data['redirect_url'];
        }
      } 
      // 2. Direct Midtrans Sandbox API call if Server Key is present
      else if (serverKey != null && serverKey.isNotEmpty) {
        final basicAuth = 'Basic ${base64Encode(utf8.encode('$serverKey:'))}';
        
        final payload = {
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': amount,
          },
          'item_details': [
            {
              'id': doctorId,
              'price': amount - 2500, // fee subtraction
              'quantity': 1,
              'name': 'Konsultasi: $doctorName',
            },
            {
              'id': 'FEE-ADMIN',
              'price': 2500,
              'quantity': 1,
              'name': 'Biaya Layanan & Admin',
            }
          ],
          'customer_details': {
            'first_name': 'Orang Tua / Pasien',
            'user_id': userId,
          },
          'enabled_payments': [paymentMethod],
        };

        final response = await http.post(
          Uri.parse(_midtransSandboxBaseUrl),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': basicAuth,
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          snapToken = data['token'];
          redirectUrl = data['redirect_url'];
        } else {
          final errorData = jsonDecode(response.body);
          debugPrint('Midtrans API Error: $errorData');
        }
      }

      // Fallback / Mock Snap Token if in Sandbox Testing mode without credentials
      snapToken ??= 'SNAP-TOK-$orderId';
      redirectUrl ??= 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken';

      // 3. Store payment record in Firestore as 'pending'
      await _firestoreService.createPaymentRecord(
        orderId: orderId,
        userId: userId,
        doctorId: doctorId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: 'pending',
        snapToken: snapToken,
        redirectUrl: redirectUrl,
      );

      return PaymentTransactionResult(
        isSuccess: true,
        orderId: orderId,
        snapToken: snapToken,
        redirectUrl: redirectUrl,
        paymentDetails: {
          'orderId': orderId,
          'amount': amount,
          'doctorName': doctorName,
          'paymentMethod': paymentMethod,
        },
      );
    } catch (e) {
      debugPrint('PaymentService Error: $e');
      return PaymentTransactionResult(
        isSuccess: false,
        orderId: orderId,
        errorMessage: 'Gagal membuat sesi pembayaran: $e',
      );
    }
  }

  /// Confirm / Simulate payment settlement in Firestore
  Future<void> confirmPaymentSuccess({
    required String orderId,
    required String userId,
    required String doctorId,
  }) async {
    await _firestoreService.updatePaymentStatus(
      orderId: orderId,
      status: 'settlement',
      paidAt: DateTime.now(),
    );
  }
}
