import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/services/data/data_export_service.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:intl/intl.dart';

class DataExportDialog extends StatefulWidget {
  final DataExportService dataExportService;

  const DataExportDialog({
    Key? key,
    required this.dataExportService,
  }) : super(key: key);

  @override
  State<DataExportDialog> createState() => _DataExportDialogState();
}

class _DataExportDialogState extends State<DataExportDialog> {
  DateTimeRange? _selectedRange;
  bool _isExporting = false;
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Export Your Data',
        style: AppTextStyles.headline4.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a date range to export your nutrition data as CSV:',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 20),

              // Quick date range buttons
              Text(
                'Quick Options:',
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickDateButton(
                    'Last Week',
                    DataExportService.getLastWeekRange(),
                  ),
                  _buildQuickDateButton(
                    'Last Month',
                    DataExportService.getLastMonthRange(),
                  ),
                  _buildQuickDateButton(
                    'This Month',
                    DataExportService.getCurrentMonthRange(),
                  ),
                  _buildQuickDateButton(
                    'Last 3 Months',
                    DataExportService.getLast3MonthsRange(),
                  ),
                  _buildQuickDateButton(
                    'All Data',
                    DataExportService.getAllTimeRange(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Custom date range option
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Custom Range:',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showCalendar = !_showCalendar;
                          if (_showCalendar) {
                            _rangeStart = null;
                            _rangeEnd = null;
                            _selectedRange = null;
                          }
                        });
                      },
                      icon: Icon(
                        _showCalendar ? Icons.expand_less : Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      label: Text(
                        _showCalendar ? 'Hide' : 'Select',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),

              if (_showCalendar) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<DateTime>(
                    firstDay: DateTime(2020),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    rangeSelectionMode: RangeSelectionMode.enforced,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableGestures: AvailableGestures.all,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: AppTextStyles.body1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: AppColors.primary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white70,
                      ),
                      defaultTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white,
                      ),
                      todayTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeStartTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      rangeEndTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      withinRangeTextStyle: AppTextStyles.body2.copyWith(
                        color: Colors.white,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeStartDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      withinRangeDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      rangeHighlightColor: AppColors.primary.withOpacity(0.1),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    onRangeSelected: (start, end, focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _rangeStart = start;
                        _rangeEnd = end;
                        if (start != null && end != null) {
                          _selectedRange = DateTimeRange(start: start, end: end);
                        } else {
                          _selectedRange = null;
                        }
                      });
                    },
                  ),
                ),
              ],

              if (_selectedRange != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Selected: ${DateFormat('MMM dd, yyyy').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _isExporting ? AppColors.textMedium : AppColors.textMedium,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _selectedRange != null && !_isExporting ? _exportData : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: _isExporting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.download),
          label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String label, DateTimeRange range) {
    final isSelected = _selectedRange != null &&
        _selectedRange!.start.isAtSameMomentAs(range.start) &&
        _selectedRange!.end.isAtSameMomentAs(range.end);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRange = range;
          _rangeStart = range.start;
          _rangeEnd = range.end;
          _showCalendar = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    if (_selectedRange == null) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: User not authenticated'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await widget.dataExportService.shareUserDataCsv(
        userId: authState.user.id,
        startDate: _selectedRange!.start,
        endDate: _selectedRange!.end,
      );

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data export completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}