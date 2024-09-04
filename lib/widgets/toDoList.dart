import 'package:flutter/material.dart';
import './toDoListDetail.dart'; // 引入任务详情页面
import '../database/dataManager.dart'; // 引入Firestore服务

class ToDoListPage extends StatefulWidget {
  final bool isAdmin;
  final Employee currentEmployee; // 接收当前用户信息

  ToDoListPage({required this.isAdmin, required this.currentEmployee});

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? '员工任务管理' : '待办事项'),
        automaticallyImplyLeading: false,
      ),
      body: widget.isAdmin
          ? _buildEmployeeList() // 管理员视图
          : _buildTaskListForCurrentUser(), // 普通用户视图
    );
  }

  // 构建管理员视图：列出所有员工
  Widget _buildEmployeeList() {
    return StreamBuilder<List<Employee>>(
      stream: _firestoreService.getEmployeesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        var employees = snapshot.data ?? [];
        // 过滤掉管理员，只显示非管理员的员工
        var filteredEmployees = employees.where((emp) => !emp.isAdmin).toList();
        return ListView.builder(
          itemCount: filteredEmployees.length,
          itemBuilder: (context, index) {
            var employee = filteredEmployees[index];
            return ListTile(
              title: Text(employee.name),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeTaskListPage(
                      employee: employee,
                      isAdmin: widget.isAdmin, // 传递isAdmin标志
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 构建普通用户视图：列出当前用户的任务
  Widget _buildTaskListForCurrentUser() {
    return StreamBuilder<List<Task>>(
      stream: _firestoreService.getTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        var tasks = snapshot.data ?? [];
        var filteredTasks = tasks
            .where((task) => task.responsible == widget.currentEmployee.name)
            .toList();
        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            var task = filteredTasks[index];
            return ListTile(
              title: Text(task.title),
              subtitle: Text(task.description),
              trailing: Text('${task.progress.toStringAsFixed(1)}%'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToDoListDetailPage(
                      id: task.id,
                      title: task.title,
                      details: task.description,
                      progress: task.progress,
                      issues: task.issues,
                      estimatedCompletion:
                          task.estimatedCompletionDate.toString(),
                      currentStatus: '进行中',
                      isAdmin: widget.isAdmin,
                      responsible: widget.currentEmployee,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// 员工任务列表页面
class EmployeeTaskListPage extends StatelessWidget {
  final Employee employee;
  final bool isAdmin;

  EmployeeTaskListPage({required this.employee, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: Text('${employee.name} 的任务列表'),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firestoreService.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          var tasks = snapshot.data ?? [];
          var filteredTasks =
              tasks.where((task) => task.responsible == employee.name).toList();
          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              var task = filteredTasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Text('${task.progress.toStringAsFixed(1)}%'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ToDoListDetailPage(
                        id: task.id,
                        title: task.title,
                        details: task.description,
                        progress: task.progress,
                        issues: task.issues,
                        estimatedCompletion:
                            task.estimatedCompletionDate.toString(),
                        currentStatus: '进行中',
                        isAdmin: isAdmin, // 传递isAdmin标志
                        responsible: employee, // 传递负责人的名称
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
}
