import 'package:flutter/material.dart';
import '../database/dataManager.dart'; // 引入Firestore服务

class MissionDetailPage extends StatefulWidget {
  final Mission mission;
  final bool isAdmin;
  final Employee employee; // 当前用户的员工信息

  MissionDetailPage({
    required this.mission,
    required this.isAdmin,
    required this.employee,
  });

  @override
  _MissionDetailPageState createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  late Mission _mission;
  bool _isLoading = false; // 是否正在加载

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mission.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('任务详情',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(_mission.description, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Text('负责人',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(_mission.responsible ?? '暂无负责人',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Text('可能遇到的难题',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ..._mission.challenges.map((challenge) =>
                      Text('- $challenge', style: TextStyle(fontSize: 16))),
                  SizedBox(height: 20),
                  if (widget.isAdmin) ...[
                    ElevatedButton(
                      onPressed: () => _showEditDialog(context),
                      child: Text('编辑任务'),
                    ),
                    ElevatedButton(
                      onPressed: () => _deleteMission(context),
                      child: Text('删除任务'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => _acceptMission(context),
                      child: Text('接受任务'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  // 管理员编辑任务
  void _showEditDialog(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: _mission.title);
    final TextEditingController descriptionController =
        TextEditingController(text: _mission.description);
    final List<TextEditingController> challengeControllers =
        _mission.challenges.map((c) => TextEditingController(text: c)).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('编辑任务'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: '任务标题'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: '任务描述'),
                    ),
                    SizedBox(height: 10),
                    Text('可能遇到的难题'),
                    ...challengeControllers.map(
                      (controller) => Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: '难题',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setDialogState(() {
                                challengeControllers.remove(controller);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          challengeControllers.add(TextEditingController());
                        });
                      },
                      child: Text('添加难题'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String updatedTitle = titleController.text.trim();
                    String updatedDescription =
                        descriptionController.text.trim();
                    List<String> updatedChallenges = challengeControllers
                        .map((c) => c.text.trim())
                        .where((c) => c.isNotEmpty)
                        .toList();

                    if (updatedTitle.isNotEmpty &&
                        updatedDescription.isNotEmpty) {
                      Mission updatedMission = Mission(
                        id: _mission.id,
                        title: updatedTitle,
                        description: updatedDescription,
                        challenges: updatedChallenges,
                        responsible: _mission.responsible,
                      );

                      await FirestoreService().setMission(updatedMission);

                      // 在对话框关闭之前更新页面显示的任务详情
                      setState(() {
                        _mission = updatedMission;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('任务已更新')),
                      );

                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('标题和描述不能为空')),
                      );
                    }
                  },
                  child: Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 管理员删除任务
  void _deleteMission(BuildContext context) async {
    await FirestoreService().deleteMission(_mission.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('任务已删除')),
    );

    Navigator.of(context).pop();
  }

  // 员工接受任务
  void _acceptMission(BuildContext context) async {
    setState(() {
      _isLoading = true; // 开始加载
    });

    Task newTask = Task(
      id: _mission.id,
      title: _mission.title,
      description: _mission.description,
      progress: 0,
      issues: '',
      estimatedCompletionDate:
          DateTime.now().add(Duration(days: 7)).toIso8601String(),
      responsible: widget.employee.name,
    );

    try {
      await FirestoreService().setTask(newTask);
      await FirestoreService().deleteMission(_mission.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('任务已接受并添加到您的任务列表')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('接受任务时发生错误：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // 加载结束
      });
    }
  }
}
