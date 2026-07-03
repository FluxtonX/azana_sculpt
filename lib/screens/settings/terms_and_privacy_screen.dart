import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Privacy',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("A’ZANA SCULPT Terms & Conditions"),
            _buildText("Your transformation begins with commitment."),
            const SizedBox(height: 20),
            
            _buildSection("1. Introduction", 
              "By accessing or using the A’zana Sculpt app and services, you agree to these Terms and Conditions. These terms ensure clarity, commitment, and a high standard of service for all clients."),
            
            _buildSection("2. Eligibility", 
              "You must be 18 years or older and medically fit to participate. By using this service, you confirm that you take full responsibility for your health and readiness."),
            
            _buildSection("3. Payments & No Refund Policy", 
              "All payments are final. Due to the digital nature of the programme and immediate access to coaching systems, plans, and resources, no refunds, cancellations, or transfers are permitted once payment has been made."),
            
            _buildSection("4. Programme Commitment", 
              "This is a commitment-based coaching programme. Results are achieved through consistency, discipline, and adherence to the structure provided. A’zana Sculpt does not guarantee results."),
            
            _buildSection("5. Coaching Access", 
              "Access to the app and coaching services is granted after payment and may be revoked if terms are violated."),
            
            _buildSection("6. Intellectual Property", 
              "All materials, plans, and content are owned by A’zana Sculpt and are for personal use only. They must not be copied, shared, or redistributed."),
            
            _buildSection("7. Limitation of Liability", 
              "A’zana Sculpt is not liable for any injury, loss, or damages arising from participation in the programme. Clients agree to use all guidance at their own risk."),

            const Divider(height: 40),
            
            _buildHeader("Privacy Policy"),
            
            _buildSection("1. Information We Collect", 
              "We collect personal information such as name, email address, phone number, and app usage data to provide and improve our services."),
            
            _buildSection("2. How We Use Your Data", 
              "Your data is used to deliver coaching services, communicate with you, improve your experience, and manage your account."),
            
            _buildSection("3. Data Protection", 
              "We take reasonable measures to protect your personal data from unauthorized access, misuse, or disclosure."),
            
            _buildSection("4. Sharing of Information", 
              "Your personal data will not be sold or shared with third parties except where necessary to deliver our services or comply with legal obligations."),
            
            _buildSection("5. Your Rights", 
              "You have the right to request access, correction, or deletion of your personal data at any time."),
            
            _buildSection("6. Contact", 
              "For any questions regarding this policy, please contact A’zana Sculpt support."),

            const SizedBox(height: 30),
            _buildHeader("Commitment Creates Results"),
            _buildText("By continuing to use A’zana Sculpt, you acknowledge and accept these terms."),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFC58F8F),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.black87,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
