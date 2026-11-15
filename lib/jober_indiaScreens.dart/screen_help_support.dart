import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<bool> _expanded = List<bool>.filled(11, false);

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I create an account?',
      'answer':
          'Select your required role and enter your details. Verify your mobile number using the OTP and complete your profile.'
    },
    {
      'question': 'How do I find a service or professional?',
      'answer':
          'Go to the Home screen, select the service you need, and choose your preferred search distance. Citizen India will show available professionals within the selected area.'
    },
    {
      'question': 'How does the distance search work?',
      'answer':
          'You can select the distance you want to search within. Professionals and businesses available within that distance can then be displayed.'
    },
    {
      'question': 'How do I contact a professional or business?',
      'answer':
          'Open the required professional or business profile and use the available contact or messaging option to communicate with them.'
    },
    {
      'question': 'How do I make a booking?',
      'answer':
          'Open the service or professional profile, select the available booking option, choose the required details, and confirm your booking.'
    },
    {
      'question': 'Where can I see my bookings?',
      'answer':
          'Tap the Bookings option at the bottom of the Home screen to view your current and previous bookings.'
    },
    {
      'question': 'Where can I see my messages?',
      'answer':
          'Tap Messages at the bottom of the Home screen. Your conversations with professionals and businesses will appear there.'
    },
    {
      'question': 'How do I turn Live Location on or off?',
      'answer':
          'Use the Live Location button on the Home screen. Your location permission must be enabled for Live Location to work.'
    },
    {
      'question': 'I did not receive my OTP. What should I do?',
      'answer':
          'Check that your mobile number is correct and that your phone has network connectivity. Wait for the resend option and request another OTP if necessary.'
    },
    {
      'question': 'How do I change my profile information?',
      'answer':
          'Open your Profile from the menu or profile button and select the appropriate edit option to update your information.'
    },
    {
      'question': 'How do I report a problem or user?',
      'answer':
          'Open Help & Support and select Report a Problem or Report a User. Provide the required details so that our support team can review the issue.'
    },
  ];

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportProblemDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Report a Problem',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the problem...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your problem has been submitted.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showReportUserDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Report a User',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us what happened...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your report has been submitted.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF078A18),
            Color(0xFF0B9F1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'How can we help you?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 7),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Find answers, contact support, or report a problem.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(alpha: 0.07),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF078A18),
            size: 26,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 17,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqCard(int index) {
    final faq = _faqs[index];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _expanded[index],
          onExpansionChanged: (value) {
            setState(() {
              _expanded[index] = value;
            });
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Color(0xFFFF9800),
              size: 21,
            ),
          ),
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq['answer']!,
                style: const TextStyle(
                  color: Colors.black87,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          _buildTopHeader(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                top: 5,
                bottom: 30,
              ),
              children: [
                _buildSectionTitle('Contact Support'),

                _buildSupportCard(
                  icon: Icons.phone,
                  title: 'Call Support',
                  subtitle: 'Speak directly with our support team',
                  onTap: () {
                    _showComingSoon('Call Support');
                  },
                ),

                _buildSupportCard(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'Send us your question by email',
                  onTap: () {
                    _showComingSoon('Email Support');
                  },
                ),

                _buildSupportCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Contact Us',
                  subtitle: 'Send a message to Citizen India support',
                  onTap: () {
                    _showComingSoon('Contact Us');
                  },
                ),

                _buildSectionTitle('Report'),

                _buildSupportCard(
                  icon: Icons.report_problem_outlined,
                  title: 'Report a Problem',
                  subtitle: 'Tell us if something is not working',
                  onTap: _showReportProblemDialog,
                ),

                _buildSupportCard(
                  icon: Icons.person_off_outlined,
                  title: 'Report a User',
                  subtitle: 'Report suspicious or inappropriate activity',
                  onTap: _showReportUserDialog,
                ),

                _buildSectionTitle('Frequently Asked Questions'),

                ...List.generate(
                  _faqs.length,
                  (index) => _buildFaqCard(index),
                ),

                const SizedBox(height: 15),

                Center(
                  child: Column(
                    children: const [
                      Icon(
                        Icons.support_agent,
                        size: 42,
                        color: Color(0xFF078A18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'People Bridge Support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'We are here to help you.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}