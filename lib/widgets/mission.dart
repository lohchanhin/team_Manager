import 'package:flutter/material.dart';
import './missionDetail.dart';
import '../database/dataManager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MissionPage extends StatefulWidget {
  final bool isAdmin;
  final Employee currentEmployee; // 添加当前用户的信息

  MissionPage({required this.isAdmin, required this.currentEmployee});

  @override
  _MissionPageState createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Mission> missions = []; // 用于保存从 StreamBuilder 获取的数据

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? '任务管理' : '任务'),
        automaticallyImplyLeading: false,
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    _showAddMissionDialog(context);
                  },
                ),
              ]
            : null,
      ),
      body: StreamBuilder<List<Mission>>(
        stream: _firestoreService.getMissionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Stream Error: ${snapshot.error}');
            return Center(child: Text('发生错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('目前没有任务'));
          }

          missions = snapshot.data!;

          return ListView.builder(
            itemCount: missions.length,
            itemBuilder: (context, index) {
              Mission mission = missions[index];

              return ListTile(
                title: Text(mission.title),
                trailing: widget.isAdmin
                    ? ElevatedButton(
                        child: Text('查看/编辑'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MissionDetailPage(
                                mission: mission,
                                isAdmin: widget.isAdmin,
                                employee: widget.currentEmployee, // 传递employee
                              ),
                            ),
                          );
                        },
                      )
                    : ElevatedButton(
                        child: Text('领取'),
                        onPressed: () async {
                          try {
                            await _handleAcceptMission(context, mission, index);
                          } catch (e) {
                            print('Error accepting mission: $e');
                          }
                        },
                      ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MissionDetailPage(
                        mission: mission,
                        isAdmin: widget.isAdmin,
                        employee: widget.currentEmployee, // 传递employee
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleAcceptMission(
      BuildContext context, Mission mission, int index) async {
    // 提前获取 ScaffoldMessenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 直接使用传递过来的 employee 数据
      Employee employee = widget.currentEmployee;

      Task newTask = Task(
        id: mission.id,
        title: mission.title,
        description: mission.description,
        progress: 0,
        issues: '',
        estimatedCompletionDate: DateTime.now().toIso8601String(),
        responsible: employee.name,
      );

      // 添加任务到Firestore的 tasks 集合中
      await _firestoreService.setTask(newTask);

      // 从Firestore的 missions 集合中删除任务
      await _firestoreService.deleteMission(mission.id);

      if (mounted) {
        setState(() {
          missions.removeAt(index);
        });

        // 使用提前获取的 scaffoldMessenger 显示消息
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('任务已领取')),
        );
      }
    } catch (e) {
      if (mounted) {
        // 使用提前获取的 scaffoldMessenger 显示错误消息
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('接受任务时发生错误: $e')),
        );
      }
      print('Error during mission acceptance: $e');
    }
  }

  void _showAddMissionDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('新增任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: '任务标题'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: '任务描述'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                String title = titleController.text.trim();
                String description = descriptionController.text.trim();

                if (title.isNotEmpty && description.isNotEmpty) {
                  String missionId =
                      _firestoreService.generateUniqueId('missions');

                  Mission newMission = Mission(
                    id: missionId,
                    title: title,
                    description: description,
                    challenges: [],
                  );

                  await _firestoreService.setMission(newMission);

                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: Text('添加任务'),
            ),
          ],
        );
      },
    );
  }
}
