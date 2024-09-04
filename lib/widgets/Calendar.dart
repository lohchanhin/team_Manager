import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/dataManager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Task>> _tasksByDate = {};
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    _firestoreService.getEmployee(userId).then((employee) {
      if (employee != null) {
        _firestoreService.getTasksStream().listen((tasks) {
          setState(() {
            _tasksByDate = {};
            for (var task in tasks) {
              DateTime completionDate =
                  DateTime.parse(task.estimatedCompletionDate);

              // 只保留日期部分
              DateTime dateOnly = DateTime(completionDate.year,
                  completionDate.month, completionDate.day);

              if (_tasksByDate[dateOnly] == null) {
                _tasksByDate[dateOnly] = [];
              }
              _tasksByDate[dateOnly]?.add(task);
            }
          });
        });
      }
    });
  }

  List<Task> _getTasksForDay(DateTime day) {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    return _tasksByDate[dateOnly] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日历'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getTasksForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay);

    if (tasks.isEmpty) {
      return Center(
        child: Text('没有任务'),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          child: ListTile(
            title: Text(task.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('负责人: ${task.responsible}'),
                Text('任务进度: ${task.progress}%'),
                Text('任务说明: ${task.description}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
