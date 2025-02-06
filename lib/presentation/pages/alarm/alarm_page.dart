import 'package:flutter/material.dart';

class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部提示文本
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                '闹钟提醒功能需要在设置中开启通知权限，并可选择是否同步到系统闹钟',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
            
            // 空状态提示
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无闹钟',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 添加闹钟按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAlarmBottomSheet(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAlarmBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const AddAlarmBottomSheet();
      },
    );
  }
}

class AddAlarmBottomSheet extends StatefulWidget {
  const AddAlarmBottomSheet({super.key});

  @override
  State<AddAlarmBottomSheet> createState() => _AddAlarmBottomSheetState();
}

class _AddAlarmBottomSheetState extends State<AddAlarmBottomSheet> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<bool> _weekdays = List.generate(7, (_) => false); // 周一到周日的重复设置
  bool _syncToSystem = false; // 是否同步到系统闹钟

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          AppBar(
            title: const Text('添加闹钟'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // TODO: 保存闹钟设置到本地存储
                  // TODO: 如果开启了同步，则同步到系统闹钟
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          ),

          // 时间选择器
          ListTile(
            title: const Text('闹钟时间'),
            trailing: TextButton(
              onPressed: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              child: Text(
                _selectedTime.format(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 重复设置
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('重复', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < 7; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _weekdays[i] = !_weekdays[i];
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _weekdays[i] ? Colors.blue : Colors.grey[200],
                          ),
                          child: Center(
                            child: Text(
                              _getWeekdayShortName(i),
                              style: TextStyle(
                                color: _weekdays[i] ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 同步到系统闹钟开关
          SwitchListTile(
            title: const Text('同步到系统闹钟'),
            value: _syncToSystem,
            onChanged: (bool value) {
              setState(() {
                _syncToSystem = value;
              });
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getWeekdayShortName(int index) {
    const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdayNames[index];
  }
} 