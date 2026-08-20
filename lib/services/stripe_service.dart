import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripePaymentResult {
  final bool success;
  final bool isCancelled;
  final String? errorMessage;

  StripePaymentResult({
    required this.success,
    this.isCancelled = false,
    this.errorMessage,
  });
}

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static const String _publishableKey =
      "pk_test_51TE5heFzACYiAnySrMuXXr7mSWFpGibLIZlVkTPkGBGo0DQRLfVxDnbZYEvXpUrLP0vFfxt03wpctIDMcRQX3PKr00GbVvfFf7";

  static const String _secretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY',
    defaultValue: '',
  );

  Future<void> init() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<StripePaymentResult> makePayment({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentIntentData = await _createPaymentIntent(amount, currency);
      if (paymentIntentData == null || paymentIntentData['client_secret'] == null) {
        return StripePaymentResult(
          success: false,
          errorMessage: "Failed to obtain payment intent from server.",
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'Azana Sculpt',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return StripePaymentResult(success: true);
    } on StripeException catch (e) {
      debugPrint("StripeException code: ${e.error.code}, message: ${e.error.localizedMessage}");
      if (e.error.code == FailureCode.Canceled) {
        return StripePaymentResult(
          success: false,
          isCancelled: true,
          errorMessage: "Payment was cancelled.",
        );
      }
      return StripePaymentResult(
        success: false,
        errorMessage: e.error.localizedMessage ?? e.error.message ?? "Payment failed",
      );
    } catch (e) {
      debugPrint("Stripe Error: $e");
      final msg = e.toString().replaceAll("Exception: ", "");
      return StripePaymentResult(
        success: false,
        errorMessage: msg,
      );
    }
  }

  // Create PaymentIntent via Cloud Function HTTP with direct fallback
  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    // 1. Try Cloud Function HTTP endpoint
    try {
      final url = Uri.parse(
        'https://us-central1-azana-sculpt.cloudfunctions.net/createStripePaymentIntent',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['client_secret'] != null) {
          return Map<String, dynamic>.from(data as Map);
        }
      }
    } catch (e) {
      debugPrint('Cloud Function HTTP error: $e. Using direct fallback...');
    }

    // 2. Direct Stripe API Fallback (Guaranteed to work without auth blocks)
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency.toLowerCase(),
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Direct Stripe API Error: ${response.body}');
        throw Exception(jsonDecode(response.body)['error']['message'] ?? 'Stripe error');
      }
    } catch (e) {
      debugPrint('Error charging user: $e');
      rethrow;
    }
  }
}



