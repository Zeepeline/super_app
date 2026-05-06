import 'package:flutter/material.dart';
import 'package:super_app/features/holidays/domain/entities/holiday_entity.dart';
import 'package:super_app/features/holidays/data/models/holiday_model.dart';

import '../../../../core/theme/app_theme.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<HolidayEntity> holidays;
  final Function(DateTime) onDateSelected;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.holidays,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    ).weekday;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
                .map(
                  (d) => Text(
                    d,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.kOnSurfaceVariantColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 rows
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - (firstDayOfMonth - 1) + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final isSelected = dayNumber == selectedDate.day;
              final currentDay = DateTime(
                selectedDate.year,
                selectedDate.month,
                dayNumber,
              );

              final holiday = holidays.firstWhere(
                (h) =>
                    h.date.year == currentDay.year &&
                    h.date.month == currentDay.month &&
                    h.date.day == currentDay.day,
                orElse: () => HolidayModel(date: DateTime(1970), name: ''),
              );

              final isHoliday = holiday.name.isNotEmpty;
              final hasSession = [
                4,
                6,
                10,
                12,
              ].contains(dayNumber); // Mock dots

              return GestureDetector(
                onTap: () {
                  onDateSelected(currentDay);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1A1A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: AppTheme.kPrimaryColor.withOpacity(0.3),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isHoliday
                                    ? Colors.redAccent
                                    : (dayNumber < 4
                                          ? AppTheme.kOnSurfaceVariantColor
                                          : Colors.white)),
                          fontWeight: isSelected || isHoliday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      if (hasSession) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
