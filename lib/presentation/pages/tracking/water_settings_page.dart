import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/services/tracking/water_tracking_service.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/core/utils/logger.dart';

class WaterSettingsPage extends StatefulWidget {
  const WaterSettingsPage({super.key});

  @override
  State<WaterSettingsPage> createState() => _WaterSettingsPageState();
}

class _WaterSettingsPageState extends State<WaterSettingsPage> {
  final WaterTrackingService _waterService = WaterTrackingService();
  final TextEditingController _targetController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = await getIt<AuthService>().getCurrentUser();
      if (user != null) {
        _userId = user.id;
        await _waterService.initialize(user.id);
        
        // Set current target in the text field (convert from ml to liters)
        _targetController.text = _waterService.waterTargetInLiters.toStringAsFixed(1);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error initializing water settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWaterTarget() async {
    if (_userId == null) return;

    final targetText = _targetController.text.trim();
    if (targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid water target')),
      );
      return;
    }

    final targetLiters = double.tryParse(targetText);
    if (targetLiters == null || targetLiters <= 0 || targetLiters > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a water target between 0.1L and 10L')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert liters to milliliters
      final targetMl = targetLiters * 1000;
      await _waterService.updateWaterTarget(_userId!, targetMl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Water target updated to ${targetLiters}L'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Go back to the previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('Error saving water target: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating water target'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Water Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Settings'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWaterTargetCard(),
            const SizedBox(height: 24),
            _buildTipsCard(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterTargetCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: AppColors.secondary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Water Target',
                  style: AppTextStyles.headline6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Set your daily water intake goal in liters',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 20),
            
            // Water target input field
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Water Target (L)',
                hintText: 'e.g., 2.5',
                prefixIcon: Icon(Icons.water_drop_outlined, color: AppColors.secondary),
                suffixText: 'L',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.secondary, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick target buttons
            Text(
              'Quick Set:',
              style: AppTextStyles.subtitle2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: [
                _buildQuickTargetButton('1.5L', 1.5),
                _buildQuickTargetButton('2.0L', 2.0),
                _buildQuickTargetButton('2.5L', 2.5),
                _buildQuickTargetButton('3.0L', 3.0),
                _buildQuickTargetButton('3.5L', 3.5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTargetButton(String label, double liters) {
    return OutlinedButton(
      onPressed: () {
        _targetController.text = liters.toStringAsFixed(1);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: BorderSide(color: AppColors.secondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Hydration Tips',
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildTipItem('The general recommendation is 8 glasses (2L) of water per day'),
            _buildTipItem('Athletes or active individuals may need 2.5-3.5L per day'),
            _buildTipItem('Hot weather or illness may increase your water needs'),
            _buildTipItem('Listen to your body and adjust your target as needed'),
            _buildTipItem('Spread your water intake throughout the day'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.secondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveWaterTarget,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Water Target',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}