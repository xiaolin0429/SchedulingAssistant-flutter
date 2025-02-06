import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/shift_type_repository.dart';
import 'shift_type_event.dart';
import 'shift_type_state.dart';

class ShiftTypeBloc extends Bloc<ShiftTypeEvent, ShiftTypeState> {
  final ShiftTypeRepository _shiftTypeRepository;

  ShiftTypeBloc(this._shiftTypeRepository) : super(const ShiftTypeInitial()) {
    on<LoadShiftTypes>(_onLoadShiftTypes);
    on<AddShiftType>(_onAddShiftType);
    on<UpdateShiftType>(_onUpdateShiftType);
    on<DeleteShiftType>(_onDeleteShiftType);
    on<SearchShiftTypes>(_onSearchShiftTypes);
  }

  Future<void> _onLoadShiftTypes(LoadShiftTypes event, Emitter<ShiftTypeState> emit) async {
    try {
      emit(const ShiftTypeLoading());
      await _shiftTypeRepository.initializePresetTypes();
      final shiftTypes = await _shiftTypeRepository.getAll();
      emit(ShiftTypeLoaded(shiftTypes: shiftTypes));
    } catch (e) {
      emit(ShiftTypeError(e.toString()));
    }
  }

  Future<void> _onAddShiftType(AddShiftType event, Emitter<ShiftTypeState> emit) async {
    if (state is ShiftTypeLoaded) {
      try {
        await _shiftTypeRepository.insert(event.shiftType);
        final shiftTypes = await _shiftTypeRepository.getAll();
        emit(ShiftTypeLoaded(shiftTypes: shiftTypes));
      } catch (e) {
        emit(ShiftTypeError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateShiftType(UpdateShiftType event, Emitter<ShiftTypeState> emit) async {
    if (state is ShiftTypeLoaded) {
      try {
        await _shiftTypeRepository.update(event.shiftType);
        final shiftTypes = await _shiftTypeRepository.getAll();
        emit(ShiftTypeLoaded(shiftTypes: shiftTypes));
      } catch (e) {
        emit(ShiftTypeError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteShiftType(DeleteShiftType event, Emitter<ShiftTypeState> emit) async {
    if (state is ShiftTypeLoaded) {
      try {
        await _shiftTypeRepository.delete(event.id);
        final shiftTypes = await _shiftTypeRepository.getAll();
        emit(ShiftTypeLoaded(shiftTypes: shiftTypes));
      } catch (e) {
        emit(ShiftTypeError(e.toString()));
      }
    }
  }

  Future<void> _onSearchShiftTypes(SearchShiftTypes event, Emitter<ShiftTypeState> emit) async {
    if (state is ShiftTypeLoaded) {
      try {
        final shiftTypes = await _shiftTypeRepository.searchShiftTypes(event.keyword);
        emit(ShiftTypeLoaded(
          shiftTypes: shiftTypes,
          isSearching: true,
          searchKeyword: event.keyword,
        ));
      } catch (e) {
        emit(ShiftTypeError(e.toString()));
      }
    }
  }
} 