import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/shift_type.dart';
import '../../blocs/shift_type/shift_type_bloc.dart';
import '../../blocs/shift_type/shift_type_event.dart';
import '../../blocs/shift_type/shift_type_state.dart';
import '../../widgets/shift_type_dialog.dart';

class ShiftTypesPage extends StatelessWidget {
  const ShiftTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('班次类型管理'),
        centerTitle: true,
      ),
      body: const ShiftTypesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ShiftTypeDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ShiftTypesList extends StatelessWidget {
  const ShiftTypesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftTypeBloc, ShiftTypeState>(
      builder: (context, state) {
        if (state is ShiftTypeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ShiftTypeError) {
          return Center(child: Text('错误: ${state.message}'));
        }

        if (state is ShiftTypeLoaded) {
          if (state.shiftTypes.isEmpty) {
            return const Center(child: Text('暂无班次类型'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: state.shiftTypes.length,
            itemBuilder: (context, index) {
              final shiftType = state.shiftTypes[index];
              return ShiftTypeCard(shiftType: shiftType);
            },
          );
        }

        return const Center(child: Text('未知状态'));
      },
    );
  }
}

class ShiftTypeCard extends StatelessWidget {
  final ShiftType shiftType;

  const ShiftTypeCard({
    super.key,
    required this.shiftType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ShiftTypeDialog(shiftType: shiftType),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 颜色标识
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(shiftType.color),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              // 班次信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shiftType.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (shiftType.startTime != null && shiftType.endTime != null)
                      Text(
                        '${shiftType.startTime} - ${shiftType.endTime}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              // 更多操作按钮
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showShiftTypeOptions(context, shiftType);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShiftTypeOptions(BuildContext context, ShiftType shiftType) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => ShiftTypeDialog(shiftType: shiftType),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, shiftType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, ShiftType shiftType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除班次类型'),
          content: Text('确定要删除"${shiftType.name}"班次类型吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (shiftType.id != null) {
                  context.read<ShiftTypeBloc>().add(DeleteShiftType(shiftType.id!));
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
} 