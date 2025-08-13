import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:intl/intl.dart';

class DataExportService {
  final FoodRepository foodRepository;

  DataExportService({required this.foodRepository});

  Future<String> exportUserDataToCsv({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get user's meal data for the date range
      final meals = await _getMealsInDateRange(userId, startDate, endDate);
      
      // Convert to CSV format
      final csvData = _convertMealsToCsv(meals, startDate, endDate);
      
      // Save to temporary file
      final file = await _saveCsvToFile(csvData, userId, startDate, endDate);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<void> shareUserDataCsv({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final filePath = await exportUserDataToCsv(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final dateFormatter = DateFormat('MMM-dd-yyyy');
      final fileName = 'WholeSight_Data_${dateFormatter.format(startDate)}_to_${dateFormatter.format(endDate)}.csv';

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'WholeSight Nutrition Data Export',
        text: 'Your nutrition data from ${dateFormatter.format(startDate)} to ${dateFormatter.format(endDate)}',
      );
    } catch (e) {
      throw Exception('Failed to share data: $e');
    }
  }

  Future<List<Meal>> _getMealsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Meal> allMeals = [];
    
    // Get meals for each date in the range
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate.add(Duration(days: 1)))) {
      final result = await foodRepository.getMealsByUserAndDate(userId, currentDate);
      
      result.fold(
        (failure) => throw Exception('Failed to get meals for $currentDate'),
        (meals) => allMeals.addAll(meals),
      );
      
      currentDate = currentDate.add(Duration(days: 1));
    }
    
    return allMeals;
  }

  String _convertMealsToCsv(List<Meal> meals, DateTime startDate, DateTime endDate) {
    final List<List<dynamic>> csvData = [];
    
    // CSV Headers
    csvData.add([
      'Date',
      'Time',
      'Meal Type',
      'Food Name',
      'Quantity',
      'Calories',
      'Protein (g)',
      'Carbs (g)',
      'Fat (g)',
      'Notes'
    ]);

    // Add meal data
    for (final meal in meals) {
      final dateFormatter = DateFormat('yyyy-MM-dd');
      
      if (meal.foods.isEmpty) {
        // Empty meal
        csvData.add([
          dateFormatter.format(meal.date),
          meal.time,
          meal.type.name,
          'No items logged',
          '',
          0,
          0,
          0,
          0,
          ''
        ]);
      } else {
        // Meal with items
        for (final item in meal.foods) {
          csvData.add([
            dateFormatter.format(meal.date),
            meal.time,
            meal.type.name,
            item.name,
            item.quantity,
            item.calories,
            item.protein ?? 0,
            item.carbs ?? 0,
            item.fat ?? 0,
            '' // Notes field for future use
          ]);
        }
      }
    }

    // Add summary row
    csvData.add([]);
    csvData.add(['SUMMARY']);
    csvData.add(['Export Date Range:', '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}']);
    csvData.add(['Total Meals:', meals.length.toString()]);
    csvData.add(['Total Food Items:', meals.fold(0, (sum, meal) => sum + meal.foods.length).toString()]);
    
    // Calculate totals
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      for (final item in meal.foods) {
        totalCalories += item.calories;
        totalProtein += item.protein ?? 0;
        totalCarbs += item.carbs ?? 0;
        totalFat += item.fat ?? 0;
      }
    }

    csvData.add(['Total Calories:', totalCalories.toStringAsFixed(1)]);
    csvData.add(['Total Protein (g):', totalProtein.toStringAsFixed(1)]);
    csvData.add(['Total Carbs (g):', totalCarbs.toStringAsFixed(1)]);
    csvData.add(['Total Fat (g):', totalFat.toStringAsFixed(1)]);

    return const ListToCsvConverter().convert(csvData);
  }

  Future<File> _saveCsvToFile(
    String csvData,
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final directory = await getTemporaryDirectory();
    final dateFormatter = DateFormat('MMM-dd-yyyy');
    final fileName = 'WholeSight_Data_${dateFormatter.format(startDate)}_to_${dateFormatter.format(endDate)}.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csvData);
    return file;
  }

  // Quick date range helpers
  static DateTimeRange getLastWeekRange() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = endDate.subtract(Duration(days: 7));
    return DateTimeRange(start: startDate, end: endDate);
  }

  static DateTimeRange getLastMonthRange() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
    return DateTimeRange(start: startDate, end: endDate);
  }

  static DateTimeRange getLast3MonthsRange() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(endDate.year, endDate.month - 3, endDate.day);
    return DateTimeRange(start: startDate, end: endDate);
  }

  static DateTimeRange getAllTimeRange() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(2020, 1, 1); // App launch date or reasonable start
    return DateTimeRange(start: startDate, end: endDate);
  }

  static DateTimeRange getCurrentMonthRange() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: startDate, end: endDate);
  }
}