import 'package:equatable/equatable.dart';
import '../../../data/models/alarm.dart';

abstract class AlarmState extends Equatable {
  const AlarmState();

  @override
  List<Object?> get props => [];
}

class AlarmInitial extends AlarmState {
  const AlarmInitial();
}

class AlarmLoading extends AlarmState {
  const AlarmLoading();
}

class AlarmLoaded extends AlarmState {
  final List<AlarmEntity> alarms;
  final AlarmEntity? nextAlarm;

  const AlarmLoaded({
    required this.alarms,
    this.nextAlarm,
  });

  @override
  List<Object?> get props => [alarms, nextAlarm];

  AlarmLoaded copyWith({
    List<AlarmEntity>? alarms,
    AlarmEntity? nextAlarm,
  }) {
    return AlarmLoaded(
      alarms: alarms ?? this.alarms,
      nextAlarm: nextAlarm ?? this.nextAlarm,
    );
  }
}

class AlarmError extends AlarmState {
  final String message;

  const AlarmError(this.message);

  @override
  List<Object> get props => [message];
} 