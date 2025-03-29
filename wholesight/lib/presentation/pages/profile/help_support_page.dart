import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Help center header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find answers or contact our support team',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for help',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FAQ section
            Text(
              'Frequently Asked Questions',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context: context,
              question: 'How do I track my meals?',
              answer:
                  'You can track your meals by going to the Food Log page and tapping the "+" button. '
                  'From there, you can search for foods, scan barcodes, or use image recognition to log your meals. '
                  'You can also create custom meals and recipes for easy logging.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context: context,
              question: 'How does the nutrition analysis work?',
              answer:
                  'Our comprehensive nutrition analysis uses data from your food logs to provide insights '
                  'into your nutrition intake. We analyze your macronutrients (proteins, carbs, fats) as well as '
                  'vitamins and minerals to give you a complete picture of your nutrition status. The analysis '
                  'is compared against your personal goals and dietary preferences.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context: context,
              question: 'How do I set up my nutrition goals?',
              answer:
                  'You can set up and adjust your nutrition goals by going to Profile > Goals. '
                  'There, you can set targets for calories, macronutrients, and specific nutrients. '
                  'The app will automatically recommend goals based on your profile, but you can customize them '
                  'to fit your specific needs.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context: context,
              question: 'Is my data private and secure?',
              answer:
                  'Yes, your data privacy and security are our top priorities. All your personal data '
                  'is encrypted and stored securely. We do not share your personal information with third parties '
                  'without your explicit consent. You can review and adjust your privacy settings in the '
                  'Profile > Privacy section.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context: context,
              question: 'How do I connect with a nutrition professional?',
              answer:
                  'WholeSight allows you to connect with registered dietitians and nutrition coaches. '
                  'Go to the Dashboard and look for the "Connect with Professional" option. You can browse '
                  'available professionals, view their credentials, and schedule consultations directly '
                  'through the app.',
            ),

            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to full FAQ page
                },
                child: const Text(
                  'View All FAQs',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact options
            Text(
              'Contact Support',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'Get help via email (response within 24 hours)',
                    onTap: () {
                      // TODO: Implement email support
                    },
                  ),
                  const Divider(height: 1),
                  _buildContactItem(
                    icon: Icons.chat_outlined,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team (7am-9pm)',
                    onTap: () {
                      // TODO: Implement live chat
                    },
                  ),
                  const Divider(height: 1),
                  _buildContactItem(
                    icon: Icons.forum_outlined,
                    title: 'Community Forums',
                    subtitle: 'Get answers from the WholeSight community',
                    onTap: () {
                      // TODO: Implement community forums navigation
                    },
                  ),
                  const Divider(height: 1),
                  _buildContactItem(
                    icon: Icons.call_outlined,
                    title: 'Phone Support',
                    subtitle: 'Talk to a support specialist (Premium users)',
                    onTap: () {
                      // TODO: Implement phone support
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick help buttons
            Text(
              'Quick Help',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpButton(
                    context: context,
                    icon: Icons.start_outlined,
                    title: 'Getting Started',
                    onTap: () {
                      // TODO: Navigate to getting started guide
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickHelpButton(
                    context: context,
                    icon: Icons.restaurant_menu,
                    title: 'Food Logging',
                    onTap: () {
                      // TODO: Navigate to food logging guide
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpButton(
                    context: context,
                    icon: Icons.analytics_outlined,
                    title: 'Analytics',
                    onTap: () {
                      // TODO: Navigate to analytics guide
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickHelpButton(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      // TODO: Navigate to settings guide
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Feedback section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              color: AppColors.secondary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.feedback_outlined,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Send Feedback',
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us improve WholeSight by sharing your thoughts and suggestions.',
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Navigate to feedback form
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: AppColors.secondary),
                        ),
                        child: const Text(
                          'Share Feedback',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Helper method to build FAQ expandable items
  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: ExpansionTile(
        title: Text(
          question,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build contact option items
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.body1,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMedium,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }

  // Helper method to build quick help buttons
  Widget _buildQuickHelpButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
