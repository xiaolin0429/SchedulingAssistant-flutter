import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/services/alarm_service.dart';
import '../../../data/models/alarm.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';
import 'package:flutter/foundation.dart';

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
    on<RescheduleAlarms>(_onRescheduleAlarms);

    // 监听闹钟流
    _alarmsSubscription = _alarmService.alarmsStream.listen((alarms) async {
      // 使用add方法触发一个内部事件来更新状态，而不是直接使用emit
      try {
        final nextAlarm = await _alarmService.getNextAlarm();
        add(_InternalUpdateState(alarms.cast<AlarmEntity>(), nextAlarm));
      } catch (e) {
        // 使用事件更新状态
        if (state is AlarmLoaded) {
          final currentState = state as AlarmLoaded;
          add(_InternalUpdateState(
              alarms.cast<AlarmEntity>(), currentState.nextAlarm));
        } else {
          add(_InternalUpdateState(alarms.cast<AlarmEntity>(), null));
        }
      }
    });

    // 添加内部状态更新处理器
    on<_InternalUpdateState>((event, emit) {
      emit(AlarmLoaded(alarms: event.alarms, nextAlarm: event.nextAlarm));
    });

    // 初始加载
    add(const LoadAlarms());
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
      debugPrint('AlarmBloc收到添加闹钟事件: ${event.alarm.toMap()}');
      await _alarmService.addAlarm(event.alarm);
      debugPrint('闹钟添加成功');
    } catch (e) {
      debugPrint('AlarmBloc添加闹钟失败: $e');
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onUpdateAlarm(
    UpdateAlarm event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      debugPrint('AlarmBloc收到更新闹钟事件: ${event.alarm.toMap()}');
      await _alarmService.updateAlarm(event.alarm);
      debugPrint('闹钟更新成功');
    } catch (e) {
      debugPrint('AlarmBloc更新闹钟失败: $e');
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

  /// 处理重新安排所有闹钟通知事件
  Future<void> _onRescheduleAlarms(
    RescheduleAlarms event,
    Emitter<AlarmState> emit,
  ) async {
    try {
      // 调用服务层方法重新安排所有闹钟
      await _alarmService.rescheduleAllAlarms();

      // 重新加载闹钟状态（可选，因为alarmsStream会自动更新状态）
      if (state is AlarmLoaded) {
        // 保持当前加载的状态，避免UI闪烁
        final currentState = state as AlarmLoaded;
        // 刷新下一个闹钟信息
        final nextAlarm = await _alarmService.getNextAlarm();
        emit(currentState.copyWith(nextAlarm: nextAlarm));
      } else {
        // 如果当前未加载状态，则触发完整加载
        add(const LoadAlarms());
      }
    } catch (e) {
      // 只记录错误但不改变状态，避免UI闪烁
      debugPrint('重新安排闹钟失败: $e');
    }
  }

  @override
  Future<void> close() {
    _alarmsSubscription?.cancel();
    return super.close();
  }
}

// 内部状态更新事件
class _InternalUpdateState extends AlarmEvent {
  final List<AlarmEntity> alarms;
  final AlarmEntity? nextAlarm;

  const _InternalUpdateState(this.alarms, this.nextAlarm);

  @override
  List<Object?> get props => [alarms, nextAlarm];
}
