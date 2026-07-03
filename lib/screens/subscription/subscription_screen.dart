import 'package:azana_sculpt/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/stripe_service.dart';
import '../../services/database_service.dart';
import '../settings/terms_and_privacy_screen.dart';
import 'dart:async';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isProcessing = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    _listenForEliteStatus();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.98,
      upperBound: 1.02,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _pulseController.dispose();
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
    final transactionController = TextEditingController();
    String? selectedCoachEmail;
    final user = FirebaseAuth.instance.currentUser;
    emailController.text = user?.email ?? '';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Your Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<UserModel>>(
                  stream: DatabaseService().getCoachesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Error loading coaches',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final coaches = snapshot.data!;
                    return Autocomplete<UserModel>(
                      displayStringForOption: (option) =>
                          option.fullName ?? option.email,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<UserModel>.empty();
                        }
                        return coaches.where((coach) {
                          final name = (coach.fullName ?? '').toLowerCase();
                          final search = textEditingValue.text.toLowerCase();
                          return name.contains(search);
                        });
                      },
                      onSelected: (UserModel selection) {
                        setDialogState(() {
                          selectedCoachEmail = selection.email;
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onSubmitted: (value) => onFieldSubmitted(),
                              decoration: InputDecoration(
                                labelText: 'Coach Name',
                                hintText: 'Type to search coach...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: const Icon(Icons.search, size: 20),
                              ),
                            );
                          },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: transactionController,
                  decoration: InputDecoration(
                    labelText: 'Transaction ID / Reference',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCoachEmail == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a Coach')),
                  );
                  return;
                }
                if (transactionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter transaction ID'),
                    ),
                  );
                  return;
                }

                if (user != null) {
                  try {
                    await DatabaseService().submitPaymentRequest(
                      uid: user.uid,
                      email: emailController.text.trim(),
                      coachEmail: selectedCoachEmail!,
                      transactionId: transactionController.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Request sent to Coach! Waiting for approval.',
                          ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Submit Request',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    // Using Stripe to handle the payment
    // Amount is 500 (in pounds, so 50000 pence for Stripe)
    final error = await StripeService.instance.makePayment(
      amount: '50000',
      currency: 'GBP',
    );

    if (error == null) {
      // Update the user's subscription status in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await DatabaseService().updateUserEliteStatus(user.uid, true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Welcome to Pro.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } else if (error == 'cancelled') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: user != null
              ? DatabaseService().getUserPaymentRequestStream(user.uid)
              : null,
          builder: (context, snapshot) {
            final paymentRequest = snapshot.data;
            final isPending =
                paymentRequest != null && paymentRequest['status'] == 'pending';

            if (isPending) {
              return _buildPendingUI(paymentRequest);
            }

            return _buildMainUI();
          },
        ),
      ),
    );
  }

  Widget _buildPendingUI(Map<String, dynamic> request) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC58F8F).withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC58F8F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_empty_rounded,
                      color: Color(0xFFC58F8F),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verification Pending',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your payment request is being reviewed by the coach. This usually takes 24-48 hours.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF2E1E1)),
                    ),
                    child: Column(
                      children: [
                        _buildRequestDetail(
                          'Coach Email',
                          request['coachEmail'] ?? 'N/A',
                        ),
                        const Divider(height: 24),
                        _buildRequestDetail(
                          'Reference',
                          request['transactionId'] ?? 'N/A',
                        ),
                        const Divider(height: 24),
                        _buildRequestDetail(
                          'Status',
                          'PENDING',
                          isStatus: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: Text(
                'Sign Out',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFC58F8F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetail(
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isStatus ? const Color(0xFFC58F8F) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMainUI() {
    return SingleChildScrollView(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFF2E1E1)),
            ),
            child: Text(
              '12 Weeks Plan',
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1:1 12 weeks programme',
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
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            '/12 weeks',
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

                    ScaleTransition(
                      scale: _pulseController,
                      child: SizedBox(
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('button_content'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Join Programme',
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
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Programme Features:',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow(
                      'Structured Splits',
                      'Choose between a 4 or 5-day gym-based training split.',
                      true,
                    ),
                    _buildFeatureRow(
                      'Tracking Tools',
                      'Log your weights, reps, and sets to ensure progressive overload.',
                      true,
                    ),
                    _buildFeatureRow(
                      'Video Tutorials',
                      'In-app video demonstrations for every exercise to ensure proper form.',
                      true,
                    ),
                    _buildFeatureRow(
                      'Nutrition Guidance',
                      'Custom meal planning and tracking.',
                      true,
                    ),
                    _buildFeatureRow(
                      'Check-ins',
                      'Weekly self-guided assessments and mental reflection tools.',
                      true,
                    ),
                    _buildFeatureRow(
                      'Community',
                      'A private members-only community section for accountability.',
                      true,
                    ),
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
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAndPrivacyScreen(),
                          ),
                        ),
                        child: Text(
                          'Terms & Conditions and Privacy Policy',
                          style: GoogleFonts.outfit(
                            color: Colors.black45,
                            fontSize: 12,
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

  Widget _buildFeatureRow(String title, String description, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
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
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.black87 : Colors.black38,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isEnabled ? Colors.black87 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
