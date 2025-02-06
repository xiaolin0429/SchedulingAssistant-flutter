import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../data/models/shift_type.dart';
import '../blocs/shift_type/shift_type_bloc.dart';
import '../blocs/shift_type/shift_type_event.dart';

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
    _startTimeController = TextEditingController(text: widget.shiftType?.startTime);
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
    return AlertDialog(
      title: Text(widget.shiftType == null ? '添加班次类型' : '编辑班次类型'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '请输入班次类型名称',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入名称';
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
                      decoration: const InputDecoration(
                        labelText: '开始时间',
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
                      decoration: const InputDecoration(
                        labelText: '结束时间',
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
                  const Text('颜色：'),
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
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _saveShiftType,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
    );

    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = _selectedColor;
        return AlertDialog(
          title: const Text('选择颜色'),
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
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedColor = pickerColor);
                Navigator.pop(context);
              },
              child: const Text('确定'),
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
      startTime: _startTimeController.text.isEmpty ? null : _startTimeController.text,
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