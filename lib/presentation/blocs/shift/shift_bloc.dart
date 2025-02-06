import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/shift_repository.dart';
import 'shift_event.dart';
import 'shift_state.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository _shiftRepository;

  ShiftBloc(this._shiftRepository) : super(const ShiftInitial()) {
    on<LoadShifts>(_onLoadShifts);
    on<AddShift>(_onAddShift);
    on<UpdateShift>(_onUpdateShift);
    on<DeleteShift>(_onDeleteShift);
    on<UpdateShiftNote>(_onUpdateShiftNote);
    on<LoadMonthlyStatistics>(_onLoadMonthlyStatistics);
    on<BatchUpsertShifts>(_onBatchUpsertShifts);
    on<SelectDate>(_onSelectDate);
  }

  Future<void> _onLoadShifts(LoadShifts event, Emitter<ShiftState> emit) async {
    try {
      emit(const ShiftLoading());
      final shifts = await _shiftRepository.getAll();
      emit(ShiftLoaded(
        shifts: shifts,
        selectedDate: DateTime.now(),
      ));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> _onAddShift(AddShift event, Emitter<ShiftState> emit) async {
    if (state is ShiftLoaded) {
      try {
        await _shiftRepository.insert(event.shift);
        final shifts = await _shiftRepository.getAll();
        emit(ShiftLoaded(
          shifts: shifts,
          selectedDate: (state as ShiftLoaded).selectedDate,
          monthlyStatistics: (state as ShiftLoaded).monthlyStatistics,
        ));
      } catch (e) {
        emit(ShiftError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateShift(UpdateShift event, Emitter<ShiftState> emit) async {
    if (state is ShiftLoaded) {
      try {
        await _shiftRepository.update(event.shift);
        final shifts = await _shiftRepository.getAll();
        emit(ShiftLoaded(
          shifts: shifts,
          selectedDate: (state as ShiftLoaded).selectedDate,
          monthlyStatistics: (state as ShiftLoaded).monthlyStatistics,
        ));
      } catch (e) {
        emit(ShiftError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteShift(DeleteShift event, Emitter<ShiftState> emit) async {
    if (state is ShiftLoaded) {
      try {
        await _shiftRepository.delete(event.id);
        final shifts = await _shiftRepository.getAll();
        emit(ShiftLoaded(
          shifts: shifts,
          selectedDate: (state as ShiftLoaded).selectedDate,
          monthlyStatistics: (state as ShiftLoaded).monthlyStatistics,
        ));
      } catch (e) {
        emit(ShiftError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateShiftNote(UpdateShiftNote event, Emitter<ShiftState> emit) async {
    if (state is ShiftLoaded) {
      try {
        final shift = await _shiftRepository.getById(event.id);
        if (shift != null) {
          await _shiftRepository.update(shift.copyWith(
            note: event.note,
            noteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          ));
          final shifts = await _shiftRepository.getAll();
          emit(ShiftLoaded(
            shifts: shifts,
            selectedDate: (state as ShiftLoaded).selectedDate,
            monthlyStatistics: (state as ShiftLoaded).monthlyStatistics,
          ));
        }
      } catch (e) {
        emit(ShiftError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMonthlyStatistics(LoadMonthlyStatistics event, Emitter<ShiftState> emit) async {
    if (state is ShiftLoaded) {
      try {
        final stats = await _shiftRepository.getMonthlyStatistics(event.year, event.month);
        emit((state as ShiftLoaded).copyWith(monthlyStatistics: stats));
      } catch (e) {
        emit(ShiftError(e.toString()));
      }
    }
  }

  Future<void> _onBatchUpsertShifts(BatchUpsertShifts event, Emitter<ShiftState> emit) async {
    if (state is ShiftLoaded) {
      try {
        await _shiftRepository.upsertShifts(event.shifts);
        final shifts = await _shiftRepository.getAll();
        emit(ShiftLoaded(
          shifts: shifts,
          selectedDate: (state as ShiftLoaded).selectedDate,
          monthlyStatistics: (state as ShiftLoaded).monthlyStatistics,
        ));
      } catch (e) {
        emit(ShiftError(e.toString()));
      }
    }
  }

  void _onSelectDate(SelectDate event, Emitter<ShiftState> emit) {
    if (state is ShiftLoaded) {
      emit((state as ShiftLoaded).copyWith(selectedDate: event.date));
    }
  }
} 