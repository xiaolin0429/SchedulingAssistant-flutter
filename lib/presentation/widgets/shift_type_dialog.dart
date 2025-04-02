import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../data/models/shift_type.dart';
import '../blocs/shift_type/shift_type_bloc.dart';
import '../blocs/shift_type/shift_type_event.dart';
import '../../core/localization/app_localizations.dart';

class ShiftTypeDialog extends StatefulWidget {
  final ShiftType? shiftType;

  const ShiftTypeDialog({
    super.key,
    this.shiftType,
  });

  @override
  State<ShiftTypeDialog> createState() => _ShiftTypeDialogState();
}

class _ShiftTypeDialogState extends State<ShiftTypeDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late Color _selectedColor;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shiftType?.name);
    _startTimeController =
        TextEditingController(text: widget.shiftType?.startTime);
    _endTimeController = TextEditingController(text: widget.shiftType?.endTime);
    _selectedColor = Color(widget.shiftType?.color ?? Colors.blue.toARGB32());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.shiftType == null
          ? localizations.translate('shift_type_add')
          : localizations.translate('shift_type_edit')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('shift_type_name'),
                  hintText: localizations.translate('shift_type_name_hint'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('shift_type_name_hint');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        labelText:
                            localizations.translate('shift_type_start_time'),
                        hintText: 'HH:mm',
                      ),
                      onTap: () => _selectTime(context, _startTimeController),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        labelText:
                            localizations.translate('shift_type_end_time'),
                        hintText: 'HH:mm',
                      ),
                      onTap: () => _selectTime(context, _endTimeController),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(localizations.translate('shift_type_color')),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showColorPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.translate('shift_type_cancel')),
        ),
        TextButton(
          onPressed: _saveShiftType,
          child: Text(localizations.translate('shift_type_save')),
        ),
      ],
    );
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
    );

    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _showColorPicker() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = _selectedColor;
        return AlertDialog(
          title: Text(localizations.translate('shift_type_choose_color')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              labelTypes: const [],
              displayThumbColor: true,
              portraitOnly: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.translate('shift_type_cancel')),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedColor = pickerColor);
                Navigator.pop(context);
              },
              child: Text(localizations.translate('confirm')),
            ),
          ],
        );
      },
    );
  }

  void _saveShiftType() {
    if (!_formKey.currentState!.validate()) return;

    final shiftType = ShiftType(
      id: widget.shiftType?.id,
      name: _nameController.text,
      startTime:
          _startTimeController.text.isEmpty ? null : _startTimeController.text,
      endTime: _endTimeController.text.isEmpty ? null : _endTimeController.text,
      color: _selectedColor.toARGB32(),
      isPreset: widget.shiftType?.isPreset ?? false,
    );

    if (widget.shiftType == null) {
      context.read<ShiftTypeBloc>().add(AddShiftType(shiftType));
    } else {
      context.read<ShiftTypeBloc>().add(UpdateShiftType(shiftType));
    }

    Navigator.pop(context);
  }
}
