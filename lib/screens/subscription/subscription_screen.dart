import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/stripe_service.dart';
import '../../services/database_service.dart';
import 'dart:async';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isProcessing = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenForEliteStatus();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenForEliteStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data()?['isElite'] == true) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        }
      });
    }
  }

  Future<void> _showManualPaymentDialog() async {
    final emailController = TextEditingController();
    final coachEmailController = TextEditingController();
    final transactionController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    emailController.text = user?.email ?? '';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Manual Verification',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Submit your payment details. The specified coach will verify and approve your access.',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Your Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: coachEmailController,
                decoration: InputDecoration(
                  labelText: 'Coach Email Address',
                  hintText: 'Enter the email of your coach',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: transactionController,
                decoration: InputDecoration(
                  labelText: 'Transaction ID / Reference',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (coachEmailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter Coach Email')),
                );
                return;
              }
              if (transactionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter transaction ID')),
                );
                return;
              }
              
              if (user != null) {
                try {
                  await DatabaseService().submitPaymentRequest(
                    uid: user.uid,
                    email: emailController.text.trim(),
                    coachEmail: coachEmailController.text.trim().toLowerCase(),
                    transactionId: transactionController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request sent to Coach! Waiting for approval.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send request: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC58F8F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    // Using Stripe to handle the payment
    // Amount is 500 (in pounds, so 50000 pence for Stripe)
    final success = await StripeService.instance.makePayment(
      amount: '50000',
      currency: 'GBP',
    );

    if (success) {
      // Update the user's subscription status in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseService().updateUserEliteStatus(user.uid, true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Welcome to Pro.')),
        );
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or failed.')),
        );
      }
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Choose Your Plan',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select the perfect plan to reach your\nfitness goals',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFF2E1E1)),
                ),
                child: Text(
                  'Monthly',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC58F8F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Main Card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFC58F8F).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC58F8F).withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFC58F8F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pro',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Most popular choice',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '£500',
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                left: 4,
                              ),
                              child: Text(
                                '/month',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stats boxes
                        Row(
                          children: [
                            _buildStatBox('Videos', '200+ Videos'),
                            const SizedBox(width: 12),
                            _buildStatBox('Workouts', '100+ Workouts'),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _handlePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC58F8F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get Pro',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Features
                        _buildFeatureRow('Everything in Basic', true),
                        _buildFeatureRow('200+ instructional videos', true),
                        _buildFeatureRow('Advanced progress analytics', true),
                        _buildFeatureRow('Personalized meal plans', true),
                        _buildFeatureRow('Custom workout builder', true),
                        _buildFeatureRow('Monthly group coaching', true),
                        _buildFeatureRow('1-on-1 coaching sessions', true),
                        _buildFeatureRow('Exclusive masterclasses', true),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: _showManualPaymentDialog,
                            child: Text(
                              'I have already paid',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFC58F8F),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Most Popular Badge
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC58F8F),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Most Popular',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFC58F8F).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC58F8F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFFC58F8F).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: isEnabled
                  ? const Color(0xFFC58F8F)
                  : Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            feature,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isEnabled ? Colors.black87 : Colors.black38,
              fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
