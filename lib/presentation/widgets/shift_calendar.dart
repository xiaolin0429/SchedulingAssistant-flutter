import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/shift.dart';

class ShiftCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final List<Shift> shifts;
  final Function(DateTime) onDateSelected;

  const ShiftCalendar({
    super.key,
    required this.selectedDate,
    required this.shifts,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2025, 12, 31),
        focusedDay: selectedDate,
        currentDay: DateTime.now(), // 设置今日日期
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          onDateSelected(selectedDay);
        },
        onPageChanged: (focusedDay) {
          // 当翻页时，保持在当前选中的日期
          onDateSelected(focusedDay);
        },
        eventLoader: (day) {
          return shifts
              .where((shift) => isSameDay(DateTime.parse(shift.date), day))
              .toList();
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final dayShifts = shifts
                .where((shift) => isSameDay(DateTime.parse(shift.date), day))
                .toList();

            return _buildDayCell(
              context,
              day,
              dayShifts,
              isSelected: false,
              isToday: false,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final dayShifts = shifts
                .where((shift) => isSameDay(DateTime.parse(shift.date), day))
                .toList();

            return _buildDayCell(
              context,
              day,
              dayShifts,
              isSelected: true,
              isToday: false,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final dayShifts = shifts
                .where((shift) => isSameDay(DateTime.parse(shift.date), day))
                .toList();

            return _buildDayCell(
              context,
              day,
              dayShifts,
              isSelected: false,
              isToday: true,
            );
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronVisible: false,
          rightChevronVisible: false,
        ),
        calendarStyle: const CalendarStyle(
          outsideTextStyle: TextStyle(color: Colors.grey),
          weekendTextStyle: TextStyle(color: Colors.red),
          markersMaxCount: 0, // 不显示默认的标记点
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
          weekendStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<Shift> dayShifts, {
    required bool isSelected,
    required bool isToday,
  }) {
    final hasShift = dayShifts.isNotEmpty;
    final shift = hasShift ? dayShifts.first : null;

    return Container(
      margin: const EdgeInsets.all(1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : shift?.type.colorValue.withAlpha(51),
              border: isToday
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 1,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : day.weekday >= 6
                          ? Colors.red
                          : null,
                ),
              ),
            ),
          ),
          if (hasShift)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: shift!.type.colorValue.withAlpha(26),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  shift.type.name,
                  style: TextStyle(
                    fontSize: 9,
                    color: shift.type.colorValue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
