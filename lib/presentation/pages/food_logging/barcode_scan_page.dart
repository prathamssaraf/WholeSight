import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_event.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_state.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/presentation/pages/food_logging/food_log_page.dart';

class BarcodeScanPage extends StatefulWidget {
  final String? mealId;
  final MealType? mealType;
  final DateTime? selectedDate;

  const BarcodeScanPage({
    super.key,
    this.mealId,
    this.mealType,
    this.selectedDate,
  });

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  bool _isScanning = false;
  Map<String, dynamic>? _scannedProduct;
  double _selectedServings = 1.0;
  String _selectedServingUnit = '100g';
  final List<String> _commonServingUnits = [
    '100g', '1 serving', '1 piece', '1 cup', '1 tablespoon', '1 teaspoon'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<FoodLoggingBloc, FoodLoggingState>(
      listener: (context, state) {
        if (state is FoodItemAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Food added to meal successfully!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context);
        } else if (state is FoodLoggingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Barcode Scanner'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _scannedProduct == null
            ? _buildScannerInterface()
            : _buildProductDetails(),
      ),
    );
  }

  Widget _buildScannerInterface() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: AppColors.primary,
          ),
          SizedBox(height: 32),
          Text(
            'Scan Product Barcode',
            style: AppTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Point your camera at the barcode on the product packaging',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isScanning
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Scanning...'),
                      ],
                    )
                  : Text(
                      'Start Scanning',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final product = _scannedProduct!;
    final originalCalories = (product['calories'] as num).toDouble();
    final originalProtein = (product['protein'] as num).toDouble();
    final originalCarbs = (product['carbs'] as num).toDouble();
    final originalFat = (product['fat'] as num).toDouble();

    // Calculate nutrition values based on selected servings
    final scaledCalories = originalCalories * _selectedServings;
    final scaledProtein = originalProtein * _selectedServings;
    final scaledCarbs = originalCarbs * _selectedServings;
    final scaledFat = originalFat * _selectedServings;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: AppTextStyles.headline3,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Per ${product['servingSize']}',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Serving Size Selection
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serving Size',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Serving amount slider
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount: ${_selectedServings.toStringAsFixed(1)}'),
                            Slider(
                              value: _selectedServings,
                              min: 0.1,
                              max: 10.0,
                              divisions: 99,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setState(() {
                                  _selectedServings = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Quick serving buttons
                  Wrap(
                    spacing: 8,
                    children: [0.5, 1.0, 1.5, 2.0, 3.0].map((servings) {
                      final isSelected = _selectedServings == servings;
                      return FilterChip(
                        label: Text('${servings.toStringAsFixed(1)}x'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedServings = servings;
                          });
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Serving unit dropdown
                  Row(
                    children: [
                      Text('Unit: '),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedServingUnit,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedServingUnit = newValue!;
                            });
                          },
                          items: _commonServingUnits.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Nutrition Information Card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Information',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Calories
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Calories',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        Text(
                          '${scaledCalories.toInt()}',
                          style: AppTextStyles.headline2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Macronutrients
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutrientCard('Protein', '${scaledProtein.toStringAsFixed(1)}g', Colors.blue),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildNutrientCard('Carbs', '${scaledCarbs.toStringAsFixed(1)}g', Colors.orange),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildNutrientCard('Fat', '${scaledFat.toStringAsFixed(1)}g', Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _scannedProduct = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: Text(
                    'Scan Again',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Add to Meal',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
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

  Widget _buildNutrientCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.subtitle2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "Cancel",
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        final productData = await _getProductFromBarcode(barcodeScanRes);
        if (productData != null) {
          setState(() {
            _scannedProduct = productData;
          });
        } else {
          _showProductNotFoundDialog();
        }
      }
    } catch (e) {
      _showErrorDialog('Error scanning barcode: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getProductFromBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          return {
            'name': product['product_name'] ?? 'Unknown Product',
            'barcode': barcode,
            'calories': (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
            'servingSize': product['serving_size'] ?? '100g',
            'protein': (nutriments['proteins_100g'] ?? 0).toDouble(),
            'carbs': (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
            'fat': (nutriments['fat_100g'] ?? 0).toDouble(),
            'brand': product['brands'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _addToMeal() async {
    if (_scannedProduct == null) return;

    final product = _scannedProduct!;
    final authService = getIt<AuthService>();
    final currentUser = await authService.getCurrentUser();
    
    if (currentUser == null) {
      _showErrorDialog('Please log in to add food to meals');
      return;
    }

    // Create FoodEntity from scanned product
    final foodEntity = FoodEntity(
      id: 'scanned_${product['barcode']}',
      name: product['name'],
      description: product['brand'] ?? '',
      servingSize: 100.0, // Base serving size is 100g from Open Food Facts
      servingUnit: 'g',
      calories: (product['calories'] as num).toDouble(),
      macronutrients: {
        'protein': (product['protein'] as num).toDouble(),
        'carbs': (product['carbs'] as num).toDouble(),
        'fat': (product['fat'] as num).toDouble(),
      },
      micronutrients: {},
      allergens: [],
      categories: [],
      barcode: product['barcode'],
      brand: product['brand'],
      isVerified: false,
      isUserCreated: false,
      createdAt: DateTime.now(),
    );

    // Create FoodItem with custom serving size
    final foodItem = FoodItem(
      name: product['name'],
      quantity: '${FoodLogUtils.formatServingQuantity(_selectedServings)} $_selectedServingUnit',
      calories: ((product['calories'] as num).toDouble() * _selectedServings).toInt(),
      protein: (product['protein'] as num).toDouble() * _selectedServings,
      carbs: (product['carbs'] as num).toDouble() * _selectedServings,
      fat: (product['fat'] as num).toDouble() * _selectedServings,
    );

    // Add to meal
    if (widget.mealId != null) {
      context.read<FoodLoggingBloc>().add(
        AddFoodToMealEvent(
          mealId: widget.mealId!,
          foodItem: foodItem,
          userId: currentUser.id,
          date: widget.selectedDate ?? DateTime.now(),
        ),
      );
    }
  }

  void _showProductNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Not Found'),
        content: Text('The scanned product could not be found in the database. Please try scanning again or add the product manually.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}