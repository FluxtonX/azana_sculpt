import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static const String _publishableKey =
      "pk_test_51TE5heFzACYiAnySrMuXXr7mSWFpGibLIZlVkTPkGBGo0DQRLfVxDnbZYEvXpUrLP0vFfxt03wpctIDMcRQX3PKr00GbVvfFf7";



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

  // Implementation using Firebase Cloud Functions
  Future<Map<String, dynamic>?> _createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createStripePaymentIntent');
      final results = await callable.call(<String, dynamic>{
        'amount': amount,
        'currency': currency,
      });

      return Map<String, dynamic>.from(results.data as Map);
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Firebase Functions Error: ${error.code} - ${error.message}');
      throw Exception('Failed to create PaymentIntent: ${error.message}');
    } catch (err) {
      debugPrint('Error charging user: ${err.toString()}');
      rethrow; // Rethrow to handle it in the UI
    }
  }
}
