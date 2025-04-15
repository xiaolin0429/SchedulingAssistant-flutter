import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/shift_type_repository.dart';
import '../../../data/repositories/calendar_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/models/monthly_statistics.dart';
import '../../../data/models/shift.dart';
import 'home_event.dart';
import 'home_state.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/logger.dart';
import '../../../core/di/injection_container.dart' as di;

/// 主页状态管理bloc
/// 负责处理主页的数据加载、排班操作和统计信息
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ShiftRepository shiftRepository;
  final ShiftTypeRepository shiftTypeRepository;
  final SettingsRepository settingsRepository;
  final CalendarRepository calendarRepository;

  HomeBloc({
    required this.shiftRepository,
    required this.settingsRepository,
    required this.shiftTypeRepository,
    required this.calendarRepository,
  }) : super(const HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<SelectDate>(_onSelectDate);
    on<SyncCalendar>(_onSyncCalendar);
    on<SyncData>(_onSyncData);
    on<ShowNoteDialog>(_onShowNoteDialog);
    on<SaveNoteToShift>(_onSaveNoteToShift);
    on<StartShift>(_onStartShift);
    on<NextShift>(_onNextShift);
    on<UpdateTodayShift>(_onUpdateTodayShift);
    on<QuickAddShift>(_onQuickAddShift);
    on<LoadMonthlyStatistics>(_onLoadMonthlyStatistics);
    on<StartBatchScheduling>(_onStartBatchScheduling);
    on<ExecuteBatchScheduling>(_onExecuteBatchScheduling);
    on<ResetShiftSelection>(_onResetShiftSelection);
  }

  /// 加载主页数据
  Future<void> _onLoadHomeData(
      LoadHomeData event, Emitter<HomeState> emit) async {
    try {
      emit(const HomeLoading());
      final selectedDate = event.date ?? DateTime.now();

      // 初始化预设班次类型
      await shiftTypeRepository.initializePresetTypes();
      final shiftTypes = await shiftTypeRepository.getAll();

      // 获取本月的排班数据
      final monthlyShifts = await shiftRepository.getShiftsByMonth(
        selectedDate.year,
        selectedDate.month,
      );

      // 获取今天的排班
      final todayShift = await shiftRepository.getShiftByDate(selectedDate);

      // 计算月度统计
      final stats = await _calculateMonthlyStatistics(
          selectedDate.year, selectedDate.month);

      emit(HomeLoaded(
        selectedDate: selectedDate,
        todayShift: todayShift,
        monthlyShifts: monthlyShifts,
        monthlyStatistics: stats,
        isSyncing: false,
        availableShiftTypes: shiftTypes,
        isSelectingShiftType: false,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// 选择日期
  Future<void> _onSelectDate(SelectDate event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        debugPrint('选择日期: ${event.date}');

        // 获取选中日期的班次信息
        final selectedShift = await shiftRepository.getShiftByDate(event.date);
        if (selectedShift != null) {
          debugPrint('获取到的班次信息: ${selectedShift.type.name}');
        } else {
          debugPrint('该日期无班次信息');
        }

        // 如果选择的是不同月份，需要重新加载月度数据
        if (event.date.month != currentState.selectedDate.month ||
            event.date.year != currentState.selectedDate.year) {
          debugPrint('月份发生变化，重新加载月度数据');

          // 重要改动：先更新选中日期，并设置加载状态标志，但保留旧数据
          // 这样可以平滑过渡，避免闪屏
          emit(currentState.copyWith(
            selectedDate: event.date,
            todayShift: selectedShift,
            isSyncing: true, // 设置同步/加载状态
          ));

          // 异步加载新月份数据
          final monthlyShifts = await shiftRepository.getShiftsByMonth(
            event.date.year,
            event.date.month,
          );
          debugPrint('本月班次数量: ${monthlyShifts.length}');

          final stats = await _calculateMonthlyStatistics(
            event.date.year,
            event.date.month,
          );
          debugPrint(
              '月度统计: 总工作天数${stats.totalWorkDays}, 总工作时长${stats.totalWorkHours}小时');

          // 数据加载完成后，更新状态并关闭加载指示器
          emit(currentState.copyWith(
            selectedDate: event.date,
            todayShift: selectedShift,
            monthlyShifts: monthlyShifts,
            monthlyStatistics: stats,
            isSyncing: false, // 关闭加载状态
          ));
          debugPrint('状态已更新(跨月)');
        } else {
          debugPrint('同月份内选择日期');
          // 同月份内，不需要重新加载整个月的数据，只更新选中日期和对应班次
          final newState = currentState.copyWith(
            selectedDate: event.date,
            todayShift: selectedShift,
            // 保留当前月份数据，不重新加载
          );
          if (selectedShift != null) {
            debugPrint('更新后的班次信息: ${selectedShift.type.name}');
          }
          emit(newState);
          debugPrint('状态已更新(同月)');
        }
      } catch (e) {
        debugPrint('选择日期时发生错误: $e');
        // 错误时保持当前状态，只更新选中日期
        emit(currentState.copyWith(
          selectedDate: event.date,
        ));
      }
    } else {
      debugPrint('当前不是HomeLoaded状态，无法处理选择日期事件');
    }
  }

  /// 开始排班
  Future<void> _onStartShift(StartShift event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final shiftTypes = await shiftTypeRepository.getAll();
        emit(currentState.copyWith(
          availableShiftTypes: shiftTypes,
          isSelectingShiftType: true,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 下一个班次
  Future<void> _onNextShift(NextShift event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        // 获取下一天的日期
        final nextDay = currentState.selectedDate.add(const Duration(days: 1));
        debugPrint('切换到下一天: $nextDay');

        final nextShift = await shiftRepository.getShiftByDate(nextDay);
        debugPrint('下一天的班次信息: ${nextShift?.type.name ?? '无班次'}');

        emit(currentState.copyWith(
          selectedDate: nextDay,
          todayShift: nextShift,
        ));
        debugPrint('下一班次状态已更新');
      } catch (e) {
        debugPrint('切换下一班次时发生错误: $e');
        emit(HomeError(e.toString()));
      }
    } else {
      debugPrint('当前不是HomeLoaded状态，无法处理下一班次事件');
    }
  }

  /// 更新今日班次
  Future<void> _onUpdateTodayShift(
      UpdateTodayShift event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final logger = di.getIt<LogService>();

        emit(currentState.copyWith(isSyncing: true));

        // 查找是否已有当天的班次记录
        final date = DateTime.parse(event.shift.date);
        final existingShift = await shiftRepository.getShiftByDate(date);

        int shiftId;
        String actionType;

        if (existingShift != null) {
          // 更新现有班次
          final updatedShift = existingShift.copyWith(
            type: event.shift.type,
            startTime: event.shift.startTime,
            endTime: event.shift.endTime,
          );
          shiftId = await shiftRepository.update(updatedShift);
          actionType = "更新";
          logger.logUserAction('更新班次', data: {
            'date': event.shift.date,
            'shiftType': event.shift.type.name,
            'isRestDay': event.shift.type.isRestDay,
          });
        } else {
          // 添加新班次
          shiftId = await shiftRepository.insert(event.shift);
          actionType = "添加";
          logger.logUserAction('添加班次', data: {
            'date': event.shift.date,
            'shiftType': event.shift.type.name,
            'isRestDay': event.shift.type.isRestDay,
          });
        }

        debugPrint('$actionType班次成功，ID: $shiftId');

        // 获取更新后的今日班次
        final updatedTodayShift = await shiftRepository.getShiftByDate(date);

        // 智能更新月度数据：只更新/添加当前修改的班次，而不是重新加载整个月
        List<Shift> updatedMonthlyShifts =
            List.from(currentState.monthlyShifts);

        // 检查班次是否在当前显示的月份内
        bool isInCurrentMonth = date.year == currentState.selectedDate.year &&
            date.month == currentState.selectedDate.month;

        if (isInCurrentMonth) {
          if (updatedTodayShift != null) {
            // 查找并更新/添加班次
            int existingIndex = updatedMonthlyShifts
                .indexWhere((shift) => shift.date == updatedTodayShift.date);

            if (existingIndex >= 0) {
              // 更新现有班次
              updatedMonthlyShifts[existingIndex] = updatedTodayShift;
            } else {
              // 添加新班次
              updatedMonthlyShifts.add(updatedTodayShift);
            }
          } else if (existingShift != null) {
            // 移除被删除的班次
            updatedMonthlyShifts
                .removeWhere((shift) => shift.date == existingShift.date);
          }

          // 重新计算统计数据 (目前无法避免这一步，因为统计数据可能因一个班次而改变)
          final stats = await _calculateMonthlyStatistics(
            currentState.selectedDate.year,
            currentState.selectedDate.month,
          );

          emit(currentState.copyWith(
            todayShift: updatedTodayShift,
            monthlyShifts: updatedMonthlyShifts,
            monthlyStatistics: stats,
            isSyncing: false,
          ));
        } else {
          // 如果修改的是非当前月份的班次，只更新 todayShift
          emit(currentState.copyWith(
            todayShift: updatedTodayShift,
            isSyncing: false,
          ));
        }
      } catch (e) {
        debugPrint('更新班次时发生错误: $e');
        final logger = di.getIt<LogService>();
        logger.e('更新班次失败', tag: 'HOME_BLOC', error: e);

        emit(currentState.copyWith(isSyncing: false));
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 加载月度统计
  Future<void> _onLoadMonthlyStatistics(
    LoadMonthlyStatistics event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final stats =
            await _calculateMonthlyStatistics(event.year, event.month);
        emit(currentState.copyWith(monthlyStatistics: stats));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 计算月度统计信息
  Future<MonthlyStatistics> _calculateMonthlyStatistics(
      int year, int month) async {
    // 直接使用仓库层的方法，避免重复实现统计逻辑
    return await shiftRepository.getMonthlyStatistics(year, month);
  }

  /// 刷新主页数据
  Future<void> _onRefreshHomeData(
      RefreshHomeData event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        // 重新加载数据
        add(LoadHomeData(date: currentState.selectedDate));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 同步日历
  Future<void> _onSyncCalendar(
      SyncCalendar event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final logger = di.getIt<LogService>();
        emit(currentState.copyWith(isSyncing: true));

        // 获取所有班次用于同步
        final allShifts = await shiftRepository.getAll();

        // 调用同步方法并记录成功
        await calendarRepository.syncCalendar(allShifts);

        logger.logUserAction('同步日历成功', data: {
          'shiftsCount': allShifts.length,
        });
        debugPrint('日历同步成功');

        emit(currentState.copyWith(isSyncing: false));
      } catch (e) {
        debugPrint('同步日历时发生错误: $e');
        final logger = di.getIt<LogService>();
        logger.e('同步日历失败', tag: 'HOME_BLOC', error: e);

        // 记录同步失败
        logger.logUserAction('同步日历失败', data: {
          'reason': e.toString(),
        });

        emit(currentState.copyWith(isSyncing: false));
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 同步数据
  Future<void> _onSyncData(SyncData event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        emit(currentState.copyWith(isSyncing: true));
        // TODO: 实现数据同步逻辑
        emit(currentState.copyWith(isSyncing: false));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 显示备注对话框
  Future<void> _onShowNoteDialog(
      ShowNoteDialog event, Emitter<HomeState> emit) async {
    debugPrint('触发显示备注对话框事件');

    // 只需确认当前状态并触发UI操作，不涉及回调
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;

      if (currentState.todayShift != null) {
        debugPrint('有排班信息，可以显示备注对话框: ${currentState.todayShift!.type.name}');
        // 此方法不再发出新状态，UI层会负责显示对话框
      } else {
        debugPrint('无法添加备注：今日没有排班信息');
      }
    } else {
      debugPrint('当前不是HomeLoaded状态，无法显示备注对话框');
    }
  }

  /// 保存班次备注
  Future<void> _onSaveNoteToShift(
      SaveNoteToShift event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final logger = di.getIt<LogService>();
        emit(currentState.copyWith(isSyncing: true));

        // 确保班次存在
        if (event.shift.id == null) {
          throw Exception('班次ID不能为空');
        }

        // 保存备注
        await shiftRepository.updateShiftNote(event.shift.id!, event.note);

        logger.logUserAction('保存班次备注', data: {
          'shiftId': event.shift.id,
          'date': event.shift.date,
          'noteLength': event.note.length,
        });

        // 重新获取今日班次以更新UI
        final selectedDate = DateTime.parse(event.shift.date);
        final updatedShift = await shiftRepository.getShiftByDate(selectedDate);

        // 更新状态
        emit(currentState.copyWith(
          todayShift: updatedShift,
          isSyncing: false,
        ));

        debugPrint('备注保存成功');
      } catch (e) {
        debugPrint('保存备注时发生错误: $e');
        final logger = di.getIt<LogService>();
        logger.e('保存班次备注失败', tag: 'HOME_BLOC', error: e);

        emit(currentState.copyWith(isSyncing: false));
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 快速添加班次
  Future<void> _onQuickAddShift(
      QuickAddShift event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        // 添加或更新班次
        await shiftRepository.upsertShift(event.shift);

        // 解析班次日期
        final date = DateTime.parse(event.shift.date);

        // 检查班次是否在当前显示的月份内
        bool isInCurrentMonth = date.year == currentState.selectedDate.year &&
            date.month == currentState.selectedDate.month;

        if (isInCurrentMonth) {
          // 获取更新后的班次数据
          final updatedShift = await shiftRepository.getShiftByDate(date);

          // 智能更新月度数据，只更新/添加修改的班次
          List<Shift> updatedMonthlyShifts =
              List.from(currentState.monthlyShifts);

          if (updatedShift != null) {
            // 查找并更新班次
            int existingIndex = updatedMonthlyShifts
                .indexWhere((shift) => shift.date == updatedShift.date);

            if (existingIndex >= 0) {
              // 更新现有班次
              updatedMonthlyShifts[existingIndex] = updatedShift;
            } else {
              // 添加新班次
              updatedMonthlyShifts.add(updatedShift);
            }
          }

          // 更新统计数据
          final stats = await _calculateMonthlyStatistics(
            currentState.selectedDate.year,
            currentState.selectedDate.month,
          );

          // 更新状态
          emit(currentState.copyWith(
            monthlyShifts: updatedMonthlyShifts,
            monthlyStatistics: stats,
            // 如果当前选中的日期就是修改的日期，同时更新todayShift
            todayShift: currentState.selectedDate.year == date.year &&
                    currentState.selectedDate.month == date.month &&
                    currentState.selectedDate.day == date.day
                ? updatedShift
                : currentState.todayShift,
          ));
        }
        // 如果不在当前月份，不需要更新UI状态，因为不会影响当前视图
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 启动批量排班
  Future<void> _onStartBatchScheduling(
      StartBatchScheduling event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final shiftTypes = await shiftTypeRepository.getAll();
        // 这里不直接修改状态，而是触发UI层弹出对话框
        // 在UI层实现批量排班对话框的显示
        emit(currentState.copyWith(
          availableShiftTypes: shiftTypes,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 执行批量排班
  Future<void> _onExecuteBatchScheduling(
      ExecuteBatchScheduling event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        final logger = di.getIt<LogService>();
        emit(currentState.copyWith(isSyncing: true));

        // 获取选中的班次类型
        final shiftTypes = await shiftTypeRepository.getAll();
        final selectedType = shiftTypes.firstWhere(
          (type) => type.id == event.shiftTypeId,
          orElse: () => throw Exception('未找到选中的班次类型'),
        );

        // 确保selectedDates不为null且不为空
        final selectedDates = event.selectedDates;
        if (selectedDates == null || selectedDates.isEmpty) {
          throw Exception('未选择任何日期');
        }

        logger.logUserAction('开始执行批量排班', data: {
          'startDate': DateFormat('yyyy-MM-dd').format(event.startDate),
          'endDate': DateFormat('yyyy-MM-dd').format(event.endDate),
          'selectedDatesCount': selectedDates.length,
          'shiftTypeName': selectedType.name,
        });

        // 创建新的班次对象列表
        final shifts = <Shift>[];
        for (final date in selectedDates) {
          shifts.add(Shift(
            date: DateFormat('yyyy-MM-dd').format(date),
            type: selectedType,
            startTime: selectedType.startTime,
            endTime: selectedType.endTime,
          ));
        }

        // 批量更新或插入班次
        await shiftRepository.upsertShifts(shifts);

        // 重新加载月度数据
        final monthlyShifts = await shiftRepository.getShiftsByMonth(
          currentState.selectedDate.year,
          currentState.selectedDate.month,
        );

        // 重新获取今日班次
        final todayShift = await shiftRepository.getShiftByDate(
          currentState.selectedDate,
        );

        // 重新计算统计数据
        final stats = await _calculateMonthlyStatistics(
          currentState.selectedDate.year,
          currentState.selectedDate.month,
        );

        emit(currentState.copyWith(
          monthlyShifts: monthlyShifts,
          todayShift: todayShift,
          monthlyStatistics: stats,
          isSyncing: false,
        ));

        logger.logUserAction('批量排班完成', data: {
          'shiftsCount': shifts.length,
        });

        debugPrint('批量排班完成，更新了 ${shifts.length} 个班次');
      } catch (e) {
        debugPrint('批量排班时发生错误: $e');
        final logger = di.getIt<LogService>();
        logger.e('执行批量排班失败', tag: 'HOME_BLOC', error: e);

        emit(currentState.copyWith(isSyncing: false));
        emit(HomeError(e.toString()));
      }
    }
  }

  /// 重置班次选择状态
  Future<void> _onResetShiftSelection(
      ResetShiftSelection event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      try {
        emit(currentState.copyWith(
          isSelectingShiftType: false,
        ));
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    // 清理资源
    return super.close();
  }
}
