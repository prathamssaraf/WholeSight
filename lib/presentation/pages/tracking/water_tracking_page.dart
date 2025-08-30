import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/services/tracking/water_tracking_service.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/core/utils/logger.dart';

class WaterTrackingPage extends StatefulWidget {
  const WaterTrackingPage({super.key});

  @override
  State<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends State<WaterTrackingPage> {
  final WaterTrackingService _waterService = WaterTrackingService();
  bool _isLoading = true;
  bool _isNfcScanning = false;
  bool _isNfcAvailable = false;
  bool _isAddingWater = false;
  String? _userId;

  // Quick add amounts in ml
  final List<double> _quickAmounts = [150, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    _initializeWaterTracking();
    _checkNfcAvailability();
  }

  Future<void> _initializeWaterTracking() async {
    try {
      final user = await getIt<AuthService>().getCurrentUser();
      if (user != null) {
        _userId = user.id;
        await _waterService.initialize(user.id);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error initializing water tracking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (mounted) {
        setState(() {
          _isNfcAvailable = isAvailable;
        });
      }
    } catch (e) {
      AppLogger.error('Error checking NFC availability: $e');
    }
  }

  Future<void> _addWaterIntake(double amountMl, String source) async {
    if (_userId == null || _isAddingWater) return;

    setState(() {
      _isAddingWater = true;
    });

    try {
      await _waterService.addWaterIntake(
        userId: _userId!,
        amountMl: amountMl,
        source: source,
      );

      if (mounted) {
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${amountMl.toInt()}ml'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error adding water intake: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding water'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingWater = false;
        });
      }
    }
  }

  Future<void> _startNfcScan() async {
    if (!_isNfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC not available')),
      );
      return;
    }

    setState(() {
      _isNfcScanning = true;
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Check if this is our water bottle sticker
            final ndef = Ndef.from(tag);
            if (ndef != null && ndef.cachedMessage != null) {
              final message = ndef.cachedMessage!;
              for (final record in message.records) {
                final payload = String.fromCharCodes(record.payload);
                
                // Check if it's our water bottle tag
                if (payload.contains('water_bottle_150ml')) {
                  await NfcManager.instance.stopSession();
                  
                  if (mounted) {
                    setState(() {
                      _isNfcScanning = false;
                    });
                  }
                  
                  // Add water intake after stopping NFC session
                  await _addWaterIntake(150.0, 'nfc');
                  return;
                }
              }
            }
            
            // If no valid water bottle tag found
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tag not configured'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            
          } catch (e) {
            AppLogger.error('Error processing NFC tag: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('NFC read error'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      AppLogger.error('Error starting NFC session: $e');
      if (mounted) {
        setState(() {
          _isNfcScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC scan error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _stopNfcScan() {
    NfcManager.instance.stopSession();
    setState(() {
      _isNfcScanning = false;
    });
  }

  void _showCustomAmountDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                hintText: 'Enter amount in milliliters',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isAddingWater ? null : () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _addWaterIntake(amount, 'manual');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveIntakeDialog() {
    if (_waterService.todayIntakes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No water intake to remove today')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Water Intake'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select an intake to remove:'),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _waterService.todayIntakes.length,
                itemBuilder: (context, index) {
                  final intake = _waterService.todayIntakes.reversed.toList()[index];
                  return ListTile(
                    title: Text('${intake.amount.toInt()}ml'),
                    subtitle: Text('${intake.timestamp.hour}:${intake.timestamp.minute.toString().padLeft(2, '0')} - ${intake.source}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: AppColors.error),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _waterService.removeWaterIntake(_userId!, intake.id);
                        setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed ${intake.amount.toInt()}ml'),
                            backgroundColor: AppColors.warning,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Water Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracking'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _showRemoveIntakeDialog();
              } else if (value == 'settings') {
                Navigator.pushNamed(context, '/water-settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline),
                    SizedBox(width: 8),
                    Text('Remove Intake'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWaterProgressCard(),
            const SizedBox(height: 24),
            _buildNfcScanSection(),
            const SizedBox(height: 24),
            _buildQuickAddSection(),
            const SizedBox(height: 24),
            _buildTodayIntakesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterProgressCard() {
    final progressPercentage = _waterService.progressPercentage;
    final consumed = _waterService.totalWaterTodayInLiters;
    final target = _waterService.waterTargetInLiters;
    final remaining = _waterService.remainingWaterTodayInLiters;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: progressPercentage,
                    strokeWidth: 12,
                    backgroundColor: AppColors.secondary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage >= 1.0 ? AppColors.success : AppColors.secondary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 40,
                      color: AppColors.secondary,
                    ),
                    Text(
                      '${consumed.toStringAsFixed(1)}L',
                      style: AppTextStyles.headline6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of ${target.toStringAsFixed(1)}L',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProgressStat(
                  'Progress',
                  '${(progressPercentage * 100).toInt()}%',
                  Icons.trending_up,
                ),
                _buildProgressStat(
                  'Remaining',
                  '${remaining.toStringAsFixed(1)}L',
                  Icons.water_drop_outlined,
                ),
                _buildProgressStat(
                  'Goal',
                  progressPercentage >= 1.0 ? 'Achieved!' : 'In Progress',
                  progressPercentage >= 1.0 ? Icons.check_circle : Icons.access_time,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildNfcScanSection() {
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
                Icon(Icons.nfc, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'NFC Water Bottle',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tap your NFC-enabled water bottle to automatically add 150ml',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_isNfcAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NFC not available',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isNfcScanning)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    Text(
                      'Tap phone to NFC sticker',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isAddingWater || _isNfcScanning) ? null : _startNfcScan,
                      icon: const Icon(Icons.nfc),
                      label: const Text('Scan NFC Sticker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_isNfcScanning) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _stopNfcScan,
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/nfc-setup'),
              icon: const Icon(Icons.settings),
              label: const Text('Setup NFC Sticker'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Add',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to quickly add common water amounts',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                return ElevatedButton(
                  onPressed: _isAddingWater ? null : () => _addWaterIntake(amount, 'quick_add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    foregroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('${amount.toInt()}ml'),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isAddingWater ? null : _showCustomAmountDialog,
                icon: const Icon(Icons.add),
                label: const Text('Custom Amount'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayIntakesList() {
    final intakes = _waterService.todayIntakes.reversed.toList();
    
    if (intakes.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 48,
                color: AppColors.textMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'No water intake recorded today',
                style: AppTextStyles.subtitle2.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your hydration!',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Intake',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intakes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final intake = intakes[index];
                final time = '${intake.timestamp.hour}:${intake.timestamp.minute.toString().padLeft(2, '0')}';
                
                IconData sourceIcon;
                Color sourceColor;
                String sourceText;
                
                switch (intake.source) {
                  case 'nfc':
                    sourceIcon = Icons.nfc;
                    sourceColor = AppColors.primary;
                    sourceText = 'NFC';
                    break;
                  case 'quick_add':
                    sourceIcon = Icons.touch_app;
                    sourceColor = AppColors.secondary;
                    sourceText = 'Quick Add';
                    break;
                  default:
                    sourceIcon = Icons.edit;
                    sourceColor = AppColors.textMedium;
                    sourceText = 'Manual';
                }
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sourceColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(sourceIcon, color: sourceColor, size: 20),
                  ),
                  title: Text('${intake.amount.toInt()}ml'),
                  subtitle: Text('$time • $sourceText'),
                  trailing: Text(
                    time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}