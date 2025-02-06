import 'package:equatable/equatable.dart';
import '../../../data/models/shift.dart';

abstract class ShiftEvent extends Equatable {
  const ShiftEvent();

  @override
  List<Object?> get props => [];
}

class LoadShifts extends ShiftEvent {
  final DateTime? date;

  const LoadShifts({this.date});

  @override
  List<Object?> get props => [date];
}

class AddShift extends ShiftEvent {
  final Shift shift;

  const AddShift(this.shift);

  @override
  List<Object> get props => [shift];
}

class UpdateShift extends ShiftEvent {
  final Shift shift;

  const UpdateShift(this.shift);

  @override
  List<Object> get props => [shift];
}

class DeleteShift extends ShiftEvent {
  final int id;

  const DeleteShift(this.id);

  @override
  List<Object> get props => [id];
}

class UpdateShiftNote extends ShiftEvent {
  final int id;
  final String note;

  const UpdateShiftNote({
    required this.id,
    required this.note,
  });

  @override
  List<Object> get props => [id, note];
}

class LoadMonthlyStatistics extends ShiftEvent {
  final int year;
  final int month;

  const LoadMonthlyStatistics({
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [year, month];
}

class BatchUpsertShifts extends ShiftEvent {
  final List<Shift> shifts;

  const BatchUpsertShifts(this.shifts);

  @override
  List<Object> get props => [shifts];
}

class SelectDate extends ShiftEvent {
  final DateTime date;

  const SelectDate(this.date);

  @override
  List<Object> get props => [date];
} 