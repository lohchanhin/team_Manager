import 'package:flutter/material.dart';
import '../database/dataManager.dart';

class ToDoListDetailPage extends StatefulWidget {
  final String id;
  final String title;
  final String details;
  final int progress;
  final String issues;
  final String estimatedCompletion;
  final String currentStatus;
  final bool isAdmin;
  final Employee responsible;

  ToDoListDetailPage({
    Key? key,
    required this.id,
    required this.title,
    required this.details,
    required this.progress,
    required this.issues,
    required this.estimatedCompletion,
    required this.currentStatus,
    required this.isAdmin,
    required this.responsible,
  }) : super(key: key);

  @override
  _ToDoListDetailPageState createState() => _ToDoListDetailPageState();
}

class _ToDoListDetailPageState extends State<ToDoListDetailPage> {
  late int _progressValue;
  late TextEditingController _issuesController;
  late DateTime _estimatedCompletionDate;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _progressValue = widget.progress;
    _issuesController = TextEditingController(text: widget.issues);
    _estimatedCompletionDate = DateTime.parse(widget.estimatedCompletion);
  }

  @override
  void dispose() {
    _issuesController.dispose();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!widget.isAdmin) {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _estimatedCompletionDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
      );
      if (picked != null && picked != _estimatedCompletionDate) {
        if (!_isDisposed) {
          setState(() {
            _estimatedCompletionDate = picked;
          });
        }
      }
    }
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('任务进度: ${_progressValue}%'),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progressValue / 100.0,
          backgroundColor: Colors.grey[300],
          color: Colors.blue,
        ),
        if (!widget.isAdmin)
          Slider(
            value: _progressValue.toDouble(),
            min: 0.0,
            max: 100.0,
            divisions: 100,
            label: '$_progressValue%',
            onChanged: (double value) {
              if (!_isDisposed) {
                setState(() {
                  _progressValue = value.round();
                });
              }
            },
          ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, bool enabled) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      maxLines: null,
      enabled: enabled,
    );
  }

  bool _isLoading = false; // 加载状态

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // 显示加载指示器
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('任务标题', widget.title, false),
                  SizedBox(height: 8),
                  _buildTextField('任务描述', widget.details, false),
                  SizedBox(height: 16),
                  _buildProgressBar(),
                  SizedBox(height: 16),
                  _buildTextField(
                      '当前所遇问题', _issuesController.text, !widget.isAdmin),
                  ListTile(
                    title: Text(
                      '预计完成时间: ${_estimatedCompletionDate.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  SizedBox(height: 20),
                  AnimatedOpacity(
                    opacity: !widget.isAdmin ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: !widget.isAdmin
                        ? ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _isLoading = true; // 开始加载
                              });

                              Task updatedTask = Task(
                                id: widget.id,
                                title: widget.title,
                                description: widget.details,
                                progress: _progressValue,
                                issues: _issuesController.text,
                                estimatedCompletionDate:
                                    _estimatedCompletionDate.toIso8601String(),
                                responsible: widget.responsible.name,
                              );

                              try {
                                await FirestoreService().updateTask(
                                    updatedTask, widget.responsible);
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('无法更新任务：${e.toString()}'),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false; // 加载结束
                                  });
                                }
                              }
                            },
                            child: Text('提交修改'),
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),
    );
  }
}
