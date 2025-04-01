import 'package:flutter/material.dart';
import '../../data/models/shift.dart';
import '../../core/localization/app_localizations.dart';

class TodayShiftCard extends StatelessWidget {
  final Shift? shift;
  final Function(Shift) onShiftUpdated;

  const TodayShiftCard({
    super.key,
    this.shift,
    required this.onShiftUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('today_shift'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (shift != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${AppLocalizations.of(context).translate('shift_type_label')} ${shift!.type.name}'),
                        const SizedBox(height: 4),
                        Text(
                            '${AppLocalizations.of(context).translate('shift_time_label')} ${shift!.startTime} - ${shift!.endTime}'),
                        if (shift!.note?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${AppLocalizations.of(context).translate('note_label')} ${shift!.note}'),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showNoteDialog(context),
                    icon: const Icon(Icons.edit),
                    tooltip: AppLocalizations.of(context).translate('add_note'),
                  ),
                ],
              ),
            ] else
              Center(
                child: TextButton.icon(
                  onPressed: () => _showShiftDialog(context),
                  icon: const Icon(Icons.add),
                  label:
                      Text(AppLocalizations.of(context).translate('add_shift')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(BuildContext context) async {
    final controller = TextEditingController(text: shift?.note);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('add_note')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).translate('note_hint'),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (shift != null) {
                onShiftUpdated(shift!.copyWith(
                  note: controller.text,
                  noteUpdatedAt: DateTime.now().millisecondsSinceEpoch,
                ));
              }
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showShiftDialog(BuildContext context) async {
    // TODO: 实现编辑排班对话框
  }
}
