import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static const String _publishableKey =
      "pk_test_51TE5heFzACYiAnySrMuXXr7mSWFpGibLIZlVkTPkGBGo0DQRLfVxDnbZYEvXpUrLP0vFfxt03wpctIDMcRQX3PKr00GbVvfFf7";

  // WARNING: Only use Secret Key in the app for QUICK TESTING.
  // For production, this MUST move to a backend server.
  static const String _secretKey =
      "YOUR_STRIPE_SECRET_KEY";

  Future<void> init() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<bool> makePayment({
    required String amount,
    required String currency,
  }) async {
    try {
      final paymentIntentData = await _createPaymentIntent(amount, currency);
      if (paymentIntentData == null) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'Azana Sculpt',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } catch (e) {
      debugPrint("Stripe Error: $e");
      return false;
    }
  }

  // Implementation for Direct Testing
  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Stripe API Error: ${response.body}');
        throw Exception(
          'Failed to create PaymentIntent: ${response.statusCode}',
        );
      }
    } catch (err) {
      debugPrint('Error charging user: ${err.toString()}');
      rethrow; // Rethrow to handle it in the UI
    }
  }
}
