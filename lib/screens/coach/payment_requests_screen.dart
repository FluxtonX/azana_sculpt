import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentRequestsScreen extends StatelessWidget {
  const PaymentRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coachEmail = AuthService().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Payment Verifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().getPendingPaymentRequestsStream(coachEmail.toLowerCase()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    final String email = request['email'] ?? 'No Email';
    final String transactionId = request['transactionId'] ?? 'No ID';
    final String uid = request['uid'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Pending Verification',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Text(
            'TRANSACTION ID / REFERENCE',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: SelectableText(
              transactionId,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAction(context, uid, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.outfit(
                      color: Colors.redAccent, 
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction(context, uid, 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.outfit(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  void _handleAction(BuildContext context, String uid, String status) async {
    try {
      await DatabaseService().updatePaymentRequestStatus(uid: uid, status: status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status == 'approved' ? 'Approved' : 'Rejected'} successfully!'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
