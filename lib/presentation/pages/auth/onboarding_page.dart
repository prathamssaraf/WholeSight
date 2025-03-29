import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
//import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
//import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/pages/auth/login_page.dart';
import 'package:whole_sight/presentation/pages/auth/signup_page.dart';
import 'package:whole_sight/presentation/widgets/common/app_logo.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Welcome to WholeSight',
      description: 'Your AI-Enhanced Nutrition & Health Assistant',
      image: 'assets/images/onboarding_1.svg',
    ),
    OnboardingItem(
      title: 'Smart Food Logging',
      description:
          'Log your meals through photos, voice, or text with AI assistance',
      image: 'assets/images/onboarding_2.svg',
    ),
    OnboardingItem(
      title: 'Personalized Insights',
      description:
          'Get tailored nutrition recommendations based on your goals and preferences',
      image: 'assets/images/onboarding_3.svg',
    ),
    OnboardingItem(
      title: 'Your Health Journey',
      description:
          'Track your progress and celebrate achievements on your path to better health',
      image: 'assets/images/onboarding_4.svg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Logo
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: AppLogo(size: 80),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingItemWidget(item: _onboardingItems[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingItems.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _goToPreviousPage,
                          child: Text(
                            'Back',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        )
                      : const SizedBox(width: 80),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _currentPage < _onboardingItems.length - 1
                        ? _goToNextPage
                        : _goToSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      minimumSize: const Size(150, 50),
                    ),
                    child: Text(
                      _currentPage < _onboardingItems.length - 1
                          ? 'Next'
                          : 'Get Started',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sign in option
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      'Sign In',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      width: _currentPage == index ? 16.0 : 8.0,
      height: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color:
            _currentPage == index ? AppColors.primary : AppColors.dividerLight,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String image;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingItemWidget extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Change from max to min
        children: [
          Flexible(
            child: item.image.endsWith('.svg')
                ? SvgPicture.asset(
                    item.image,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    item.image,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(height: 16), // Add spacing
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8), // Add spacing
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 3, // Limit text lines if needed
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
