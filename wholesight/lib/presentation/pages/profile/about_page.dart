import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/presentation/widgets/common/app_logo.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // App version information
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '103';
  static const String _releaseDate = 'March 15, 2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'About',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo and name
            const SizedBox(height: 24),
            const AppLogo(size: 100),
            const SizedBox(height: 16),
            Text(
              'WholeSight',
              style: AppTextStyles.headline5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Comprehensive Nutrition Analysis',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version $_appVersion (Build $_buildNumber)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            Text(
              'Released on $_releaseDate',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),

            const SizedBox(height: 32),

            // App description
            _buildSection(
              title: 'Our Mission',
              content: 'WholeSight is dedicated to providing a comprehensive '
                  'view of your nutritional health through cutting-edge '
                  'technology and nutritional science. We strive to empower '
                  'users with actionable insights about their diet and health, '
                  'making nutrition tracking more accessible and personalized '
                  'than ever before.',
            ),

            const SizedBox(height: 24),

            // Features
            _buildSection(
              title: 'Key Features',
              content: '',
              extraWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    icon: Icons.analytics_outlined,
                    title: 'Comprehensive Analysis',
                    description:
                        'Get detailed insights into your macro and micronutrient intake.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'AI-Powered Food Recognition',
                    description:
                        'Identify foods and portion sizes from photos using advanced AI.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.trending_up_outlined,
                    title: 'Personalized Recommendations',
                    description:
                        'Receive food suggestions tailored to your nutritional needs and goals.',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.track_changes_outlined,
                    title: 'Progress Tracking',
                    description:
                        'Monitor your nutritional improvements over time with visual reports.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Team info
            _buildSection(
              title: 'Our Team',
              content:
                  'WholeSight was created by a passionate team of nutrition '
                  'scientists, data analysts, and software engineers. We are dedicated '
                  'to advancing nutritional health through technology and making accurate '
                  'nutrition analysis accessible to everyone.',
            ),

            const SizedBox(height: 24),

            // Credits and acknowledgments
            _buildSection(
              title: 'Credits & Acknowledgments',
              content:
                  'Our nutrition database is powered by the USDA Food Data Central '
                  'and supplemented with our proprietary database of global foods.\n\n'
                  'Special thanks to our nutrition science advisors and beta testers '
                  'for their invaluable feedback and contributions.',
            ),

            const SizedBox(height: 24),

            // Contact information
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactInfoItem(
                      icon: Icons.email_outlined,
                      text: 'support@wholesight.com',
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfoItem(
                      icon: Icons.language_outlined,
                      text: 'www.wholesight.com',
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfoItem(
                      icon: Icons.location_on_outlined,
                      text: '123 Nutrition Ave, Health Valley, CA 94043',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Social media links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    // TODO: Open Facebook page
                  },
                ),
                const SizedBox(width: 24),
                _buildSocialButton(
                  icon: Icons.alternate_email,
                  color: const Color(0xFF1DA1F2),
                  onTap: () {
                    // TODO: Open Twitter page
                  },
                ),
                const SizedBox(width: 24),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  color: const Color(0xFFE4405F),
                  onTap: () {
                    // TODO: Open Instagram page
                  },
                ),
                const SizedBox(width: 24),
                _buildSocialButton(
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFFFF0000),
                  onTap: () {
                    // TODO: Open YouTube channel
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Legal links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: Open privacy policy
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: AppColors.textMedium, fontSize: 12),
                  ),
                ),
                const Text(
                  ' | ',
                  style: TextStyle(color: AppColors.textMedium),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Open terms of service
                  },
                  child: const Text(
                    'Terms of Service',
                    style: TextStyle(color: AppColors.textMedium, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Copyright
            Text(
              '© 2025 WholeSight. All rights reserved.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper method to build a section with title and content
  Widget _buildSection({
    required String title,
    required String content,
    Widget? extraWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.green.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        if (extraWidget != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: extraWidget,
          ),
      ],
    );
  }

  // Helper method to build a feature item
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build contact information items
  Widget _buildContactInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body2,
          ),
        ),
      ],
    );
  }

  // Helper method to build social media buttons
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}
