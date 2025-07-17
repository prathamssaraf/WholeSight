import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whole_sight/services/ai/image_recognition_service.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/presentation/pages/food_logging/food_log_page.dart';

class ImageRecognitionPage extends StatefulWidget {
  final String userId;
  final String mealId;
  final MealType mealType;
  final DateTime date;

  const ImageRecognitionPage({
    Key? key,
    required this.userId,
    required this.mealId,
    required this.mealType,
    required this.date,
  }) : super(key: key);

  @override
  State<ImageRecognitionPage> createState() => _ImageRecognitionPageState();
}

class _ImageRecognitionPageState extends State<ImageRecognitionPage> {
  final ImagePicker _picker = ImagePicker();
  final ImageRecognitionService _imageRecognitionService =
      ImageRecognitionServiceImpl();

  File? _selectedImage;
  bool _isAnalyzing = false;
  List<FoodEntity>? _recognizedFoods;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check camera permission
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      await Permission.camera.request();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _recognizedFoods = null;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing camera: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _recognizedFoods = null;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing gallery: $e';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _recognizedFoods = null;
      _errorMessage = '';
    });

    try {
      // Using the existing ImageRecognitionService
      final results = await _imageRecognitionService
          .recognizeFoodFromImage(_selectedImage!);

      setState(() {
        _isAnalyzing = false;
        _recognizedFoods = results;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Failed to analyze image: $e';
      });
    }
  }

  void _addFoodToMeal(FoodEntity food) {
    // Convert the rich FoodEntity model to the simpler FoodItem model
    final foodItem = FoodItem(
      name: food.name,
      quantity: '${FoodLogUtils.formatServingQuantity(food.servingSize)} ${food.servingUnit}',
      calories: food.calories.toInt(),
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
    );

    // Add to meal through the bloc
    context.read<FoodLoggingBloc>().add(
          AddFoodToMealEvent(
            mealId: widget.mealId,
            foodItem: foodItem,
            userId: widget.userId,
            date: widget.date,
          ),
        );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} added to meal'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Recognition'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image selection area
              _buildImageSection(),

              const SizedBox(height: 24),

              // Image analysis options
              if (_selectedImage != null &&
                  !_isAnalyzing &&
                  _recognizedFoods == null)
                ElevatedButton.icon(
                  onPressed: _analyzeImage,
                  icon: const Icon(Icons.search),
                  label: const Text('Analyze Food'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),

              // Loading indicator
              if (_isAnalyzing)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing your food...',
                        style: AppTextStyles.subtitle1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our AI is identifying foods and their nutritional content',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),

              // Results section
              if (_recognizedFoods != null) _buildResultsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Image',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Image preview or placeholder
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No image selected',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Image capture buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_recognizedFoods == null || _recognizedFoods!.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'No foods recognized',
              style: AppTextStyles.subtitle1,
            ),
            const SizedBox(height: 8),
            Text(
              'Try taking a clearer photo or from a different angle',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recognized Foods',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _analyzeImage,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recognizedFoods!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final food = _recognizedFoods![index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(food.categories),
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    food.name,
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${food.servingSize} ${food.servingUnit}'),
                      if (food.description.isNotEmpty &&
                          food.description.length < 50)
                        Text(
                          food.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMedium,
                          ),
                        ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildNutrientChip('${food.calories.toInt()} cal',
                                AppColors.primary),
                            _buildNutrientChip('${food.protein.toInt()}g P',
                                AppColors.protein),
                            _buildNutrientChip(
                                '${food.carbs.toInt()}g C', AppColors.carbs),
                            _buildNutrientChip(
                                '${food.fat.toInt()}g F', AppColors.fats),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    onPressed: () => _addFoodToMeal(food),
                    tooltip: 'Add to meal',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(List<String> categories) {
    if (categories.isEmpty) return Icons.restaurant;

    final category = categories.first.toLowerCase();

    if (category.contains('fruit')) return Icons.apple;
    if (category.contains('vegetable')) return Icons.eco;
    if (category.contains('meat') || category.contains('protein'))
      return Icons.egg_alt;
    if (category.contains('dairy')) return Icons.coffee;
    if (category.contains('grain') || category.contains('bread'))
      return Icons.bakery_dining;
    if (category.contains('dessert') || category.contains('sweet'))
      return Icons.cake;
    if (category.contains('beverage') || category.contains('drink'))
      return Icons.local_drink;

    return Icons.restaurant;
  }

  Widget _buildNutrientChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
