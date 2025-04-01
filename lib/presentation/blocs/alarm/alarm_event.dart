import 'package:equatable/equatable.dart';
import '../../../data/models/alarm.dart';

abstract class AlarmEvent extends Equatable {
  const AlarmEvent();

  @override
  List<Object?> get props => [];
}

class LoadAlarms extends AlarmEvent {
  const LoadAlarms();
}

class AddAlarm extends AlarmEvent {
  final AlarmEntity alarm;

  const AddAlarm(this.alarm);

  @override
  List<Object> get props => [alarm];
}

class UpdateAlarm extends AlarmEvent {
  final AlarmEntity alarm;

  const UpdateAlarm(this.alarm);

  @override
  List<Object> get props => [alarm];
}

class DeleteAlarm extends AlarmEvent {
  final int id;

  const DeleteAlarm(this.id);

  @override
  List<Object> get props => [id];
}

class ToggleAlarmEnabled extends AlarmEvent {
  final int id;

  const ToggleAlarmEnabled(this.id);

  @override
  List<Object> get props => [id];
}

class UpdateAlarmRepeat extends AlarmEvent {
  final int id;
  final bool repeat;
  final List<int> repeatDays;

  const UpdateAlarmRepeat({
    required this.id,
    required this.repeat,
    required this.repeatDays,
  });

  @override
  List<Object> get props => [id, repeat, repeatDays];
}

class LoadNextAlarm extends AlarmEvent {
  const LoadNextAlarm();
}

class DeleteAlarms extends AlarmEvent {
  final List<int> ids;

  const DeleteAlarms(this.ids);

  @override
  List<Object> get props => [ids];
}

/// 重新安排所有闹钟通知事件，用于通知设置变更时
class RescheduleAlarms extends AlarmEvent {
  const RescheduleAlarms();
}
