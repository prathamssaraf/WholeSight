import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/core/utils/logger.dart';

class NfcSetupPage extends StatefulWidget {
  const NfcSetupPage({super.key});

  @override
  State<NfcSetupPage> createState() => _NfcSetupPageState();
}

class _NfcSetupPageState extends State<NfcSetupPage> {
  bool _isNfcAvailable = false;
  bool _isWriting = false;
  bool _isReading = false;
  String _currentStepDescription = '';
  int _currentStep = 0;

  final List<Map<String, dynamic>> _setupSteps = [
    {
      'title': 'Prepare NFC Sticker',
      'description': 'Get a blank NFC sticker or tag. Make sure your phone\'s NFC is enabled.',
      'icon': Icons.nfc,
    },
    {
      'title': 'Write Configuration',
      'description': 'We\'ll write water bottle configuration data to your NFC sticker.',
      'icon': Icons.edit,
    },
    {
      'title': 'Test the Sticker',
      'description': 'Test the configured sticker to ensure it works correctly.',
      'icon': Icons.check_circle,
    },
    {
      'title': 'Attach to Bottle',
      'description': 'Stick the NFC tag to your water bottle in an easily accessible location.',
      'icon': Icons.sports_bar,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      setState(() {
        _isNfcAvailable = isAvailable;
      });
    } catch (e) {
      AppLogger.error('Error checking NFC availability: $e');
    }
  }

  Future<void> _writeWaterBottleTag() async {
    if (!_isNfcAvailable) {
      _showErrorDialog('NFC is not available on this device');
      return;
    }

    setState(() {
      _isWriting = true;
      _currentStepDescription = 'Tap phone to NFC sticker';
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              throw Exception('NFC tag is not NDEF formatted');
            }

            if (!ndef.isWritable) {
              throw Exception('NFC tag is not writable');
            }

            // Create NDEF message for water bottle
            final message = NdefMessage([
              NdefRecord.createText('water_bottle_150ml'),
              NdefRecord.createText('WholeSight Water Tracker'),
            ]);

            await ndef.write(message);
            await NfcManager.instance.stopSession();

            if (mounted) {
              setState(() {
                _isWriting = false;
                _currentStep = 2; // Move to test step
                _currentStepDescription = '';
              });

              _showSuccessDialog(
                'NFC Sticker Configured!',
                'Your water bottle sticker has been successfully configured. You can now test it.',
              );
            }
          } catch (e) {
            AppLogger.error('Error writing NFC tag: $e');
            await NfcManager.instance.stopSession();
            
            if (mounted) {
              setState(() {
                _isWriting = false;
                _currentStepDescription = '';
              });
              
              _showErrorDialog('Failed to write tag');
            }
          }
        },
      );
    } catch (e) {
      AppLogger.error('Error starting NFC write session: $e');
      setState(() {
        _isWriting = false;
        _currentStepDescription = '';
      });
      _showErrorDialog('NFC session failed');
    }
  }

  Future<void> _testWaterBottleTag() async {
    if (!_isNfcAvailable) {
      _showErrorDialog('NFC is not available on this device');
      return;
    }

    setState(() {
      _isReading = true;
      _currentStepDescription = 'Tap phone to sticker';
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef?.cachedMessage != null) {
              bool isWaterBottleTag = false;
              
              for (final record in ndef!.cachedMessage!.records) {
                final payload = String.fromCharCodes(record.payload);
                if (payload.contains('water_bottle_150ml')) {
                  isWaterBottleTag = true;
                  break;
                }
              }

              await NfcManager.instance.stopSession();

              if (mounted) {
                setState(() {
                  _isReading = false;
                  _currentStepDescription = '';
                });

                if (isWaterBottleTag) {
                  setState(() {
                    _currentStep = 3; // Move to final step
                  });
                  
                  _showSuccessDialog(
                    'Test Successful!',
                    'Your NFC sticker is working correctly. You can now attach it to your water bottle.',
                  );
                } else {
                  _showErrorDialog('Tag not configured for water tracking');
                }
              }
            } else {
              throw Exception('No NDEF message found on tag');
            }
          } catch (e) {
            AppLogger.error('Error reading NFC tag: $e');
            await NfcManager.instance.stopSession();
            
            if (mounted) {
              setState(() {
                _isReading = false;
                _currentStepDescription = '';
              });
              
              _showErrorDialog('Failed to read tag');
            }
          }
        },
      );
    } catch (e) {
      AppLogger.error('Error starting NFC read session: $e');
      setState(() {
        _isReading = false;
        _currentStepDescription = '';
      });
      _showErrorDialog('NFC session failed');
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelOperation() {
    NfcManager.instance.stopSession();
    setState(() {
      _isWriting = false;
      _isReading = false;
      _currentStepDescription = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup NFC Sticker'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: !_isNfcAvailable
          ? _buildNfcNotAvailable()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 24),
                  _buildSetupSteps(),
                  const SizedBox(height: 24),
                  _buildTipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildNfcNotAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc_outlined,
              size: 80,
              color: AppColors.textMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'NFC Not Available',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NFC is not available on this device. You can still use the manual water tracking features.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.nfc,
              size: 60,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Setup Your Water Bottle NFC Sticker',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Configure an NFC sticker to automatically track 150ml of water intake when you tap it with your phone.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSteps() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Steps',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Steps
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _setupSteps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final step = _setupSteps[index];
                final isCurrentStep = index == _currentStep;
                final isCompleted = index < _currentStep;
                final isActive = index <= _currentStep;

                return _buildStepItem(
                  stepNumber: index + 1,
                  title: step['title'],
                  description: step['description'],
                  icon: step['icon'],
                  isActive: isActive,
                  isCompleted: isCompleted,
                  isCurrentStep: isCurrentStep,
                );
              },
            ),
            
            if (_currentStepDescription.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentStepDescription,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
    required bool isCurrentStep,
  }) {
    Color stepColor;
    if (isCompleted) {
      stepColor = AppColors.success;
    } else if (isCurrentStep) {
      stepColor = AppColors.primary;
    } else if (isActive) {
      stepColor = AppColors.secondary;
    } else {
      stepColor = AppColors.textMedium;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: stepColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: stepColor, size: 16)
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: stepColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: stepColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stepColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: isActive ? AppColors.textDark : AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _currentStep = 1),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Setup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    } else if (_currentStep == 1) {
      return Row(
        children: [
          if (_isWriting)
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOperation,
                child: const Text('Cancel'),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _writeWaterBottleTag,
                icon: const Icon(Icons.nfc),
                label: const Text('Write to NFC Sticker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      );
    } else if (_currentStep == 2) {
      return Row(
        children: [
          if (_isReading)
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOperation,
                child: const Text('Cancel'),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _testWaterBottleTag,
                icon: const Icon(Icons.check_circle),
                label: const Text('Test NFC Sticker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check_circle),
          label: const Text('Setup Complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }
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
                  'Tips for Best Results',
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildTipItem('Use NFC stickers specifically designed for smartphones'),
            _buildTipItem('Place the sticker on a flat, clean surface of your water bottle'),
            _buildTipItem('Avoid placing near metal parts which may interfere with NFC'),
            _buildTipItem('Test the sticker periodically to ensure it\'s still working'),
            _buildTipItem('Keep backup stickers in case one gets damaged'),
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
            color: AppColors.success,
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
}