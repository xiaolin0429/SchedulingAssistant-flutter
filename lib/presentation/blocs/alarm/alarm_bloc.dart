import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/services/alarm_service.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final AlarmService _alarmService;
  StreamSubscription? _alarmsSubscription;

  AlarmBloc(this._alarmService) : super(const AlarmInitial()) {
    on<LoadAlarms>(_onLoadAlarms);
    on<AddAlarm>(_onAddAlarm);
    on<UpdateAlarm>(_onUpdateAlarm);
    on<DeleteAlarm>(_onDeleteAlarm);
    on<ToggleAlarmEnabled>(_onToggleAlarmEnabled);
    on<UpdateAlarmRepeat>(_onUpdateAlarmRepeat);
    on<LoadNextAlarm>(_onLoadNextAlarm);
    on<DeleteAlarms>(_onDeleteAlarms);

    // 监听闹钟流
    _alarmsSubscription = _alarmService.alarmsStream.listen((alarms) {
      add(const LoadAlarms());
    });
  }

  Future<void> _onLoadAlarms(
    LoadAlarms event,
    Emitter<AlarmState> emit,
  ) async {
    emit(const AlarmLoading());
    try {
      final alarms = await _alarmService.getAllAlarms();
      final nextAlarm = await _alarmService.getNextAlarm();
      emit(AlarmLoaded(alarms: alarms, nextAlarm: nextAlarm));
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onAddAlarm(
    AddAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await _alarmService.addAlarm(event.alarm);
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onUpdateAlarm(
    UpdateAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await _alarmService.updateAlarm(event.alarm);
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onDeleteAlarm(
    DeleteAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await _alarmService.deleteAlarm(event.id);
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onToggleAlarmEnabled(
    ToggleAlarmEnabled event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await _alarmService.toggleAlarmEnabled(event.id);
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onUpdateAlarmRepeat(
    UpdateAlarmRepeat event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await _alarmService.updateAlarmRepeat(
        event.id,
        event.repeat,
        event.repeatDays,
      );
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onLoadNextAlarm(
    LoadNextAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    if (state is AlarmLoaded) {
      try {
        final nextAlarm = await _alarmService.getNextAlarm();
        final currentState = state as AlarmLoaded;
        emit(currentState.copyWith(nextAlarm: nextAlarm));
      } catch (e) {
        emit(AlarmError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteAlarms(
    DeleteAlarms event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      await _alarmService.deleteAlarms(event.ids);
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _alarmsSubscription?.cancel();
    return super.close();
  }
} 