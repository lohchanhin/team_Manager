// ignore_for_file: file_names

import "package:cloud_firestore/cloud_firestore.dart";

class Task {
  String id; // 唯一标识符
  String title;
  String description;
  int progress; // 进度，整数类型
  String issues;
  String estimatedCompletionDate; // 预计完成日期
  String responsible; // 负责人

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.issues,
    required this.estimatedCompletionDate,
    required this.responsible,
  });

  // 从Firestore文档创建Task对象
  factory Task.fromFirestore(Map<String, dynamic> firestoreDoc) {
    return Task(
      id: firestoreDoc['id'] as String,
      title: firestoreDoc['title'] as String,
      description: firestoreDoc['description'] as String,
      progress: firestoreDoc['progress'] as int,
      issues: firestoreDoc['issues'] as String,
      estimatedCompletionDate:
          firestoreDoc['estimatedCompletionDate'] as String,
      responsible: firestoreDoc['responsible'] as String,
    );
  }

  // 将Task对象转换为Map，以便存储到Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'progress': progress,
      'issues': issues,
      'estimatedCompletionDate': estimatedCompletionDate,
      'responsible': responsible,
    };
  }
}

class Mission {
  String id; // 用于唯一标识任务
  String title; // 任务标题
  String description; // 任务描述
  List<String> challenges; // 可能面临的难题，作为列表
  String? responsible; // 任务负责人

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.challenges,
    this.responsible,
  });

  // 从Firestore文档创建Mission对象
  factory Mission.fromFirestore(Map<String, dynamic> firestoreDoc) {
    List<String> challengesList =
        (firestoreDoc['challenges'] as String).split('\n');
    return Mission(
      id: firestoreDoc['id'] as String,
      title: firestoreDoc['title'] as String,
      description: firestoreDoc['description'] as String,
      challenges: challengesList,
      responsible: firestoreDoc['responsible'] as String?,
    );
  }

  // 将Mission对象转换为Map，以便存储到Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'challenges': challenges.join('\n'), // 将列表转换为字符串
      'responsible': responsible,
    };
  }
}

class CalendarEvent {
  DateTime date;
  String description;

  CalendarEvent({required this.date, required this.description});

  // 从Firestore文档创建CalendarEvent对象
  factory CalendarEvent.fromFirestore(Map<String, dynamic> firestoreDoc) {
    return CalendarEvent(
      date: (firestoreDoc['date'] as Timestamp).toDate(),
      description: firestoreDoc['description'] as String,
    );
  }

  // 将CalendarEvent对象转换为Map，以便存储到Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
    };
  }
}

class Employee {
  String id; // 用户的唯一标识符
  String name; // 名字
  String position; // 职位
  String department; // 部门
  bool isAdmin; // 是否为管理员

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    this.isAdmin = false, // 默认为普通用户
  });

  // 从Firestore文档创建Employee对象
  factory Employee.fromFirestore(Map<String, dynamic> firestoreDoc, String id) {
    return Employee(
      id: id,
      name: firestoreDoc['name'] as String,
      position: firestoreDoc['position'] as String,
      department: firestoreDoc['department'] as String,
      isAdmin: firestoreDoc['isAdmin'] as bool? ?? false, // 默认非管理员
    );
  }

  // 将Employee对象转换为Map，以便存储到Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'position': position,
      'department': department,
      'isAdmin': isAdmin,
    };
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 生成唯一ID的方法
  String generateUniqueId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }

  // 创建或更新任务（仅管理员）
  Future<void> setTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toFirestore());
  }

  // 读取单个任务（所有用户都可以查看）
  Future<Task?> getTask(String taskId) async {
    var snapshot = await _firestore.collection('tasks').doc(taskId).get();
    if (snapshot.exists) {
      return Task.fromFirestore(snapshot.data()!);
    }
    return null;
  }

  // 获取任务的Stream（所有用户都可以查看）
  Stream<List<Task>> getTasksStream() {
    return _firestore.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromFirestore(doc.data()!)).toList());
  }

  // 删除任务（仅管理员）
  Future<void> deleteTask(String taskId, Employee employee) async {
    if (employee.isAdmin) {
      await _firestore.collection('tasks').doc(taskId).delete();
    } else {
      throw Exception('权限不足，无法删除任务');
    }
  }

  // 更新任务（员工可以更新，管理员只能查看）
  Future<void> updateTask(Task task, Employee employee) async {
    if (!employee.isAdmin) {
      // 如果员工，不是管理员，则允许更新任务
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());
    } else {
      // 如果是管理员，则仅抛出异常或不执行更新操作
      throw Exception('管理员只能查看任务，无法更新任务');
    }
  }

  // 创建或更新日历事件
  Future<void> setCalendarEvent(CalendarEvent event) async {
    await _firestore
        .collection('calendarEvents')
        .doc(event.date.toIso8601String())
        .set(event.toFirestore());
  }

  // 创建或更新任务目标
  Future<void> setMission(Mission mission) async {
    await _firestore
        .collection('missions')
        .doc(mission.id)
        .set(mission.toFirestore());
  }

  // 读取单个Mission
  Future<Mission?> getMission(String missionId) async {
    var snapshot = await _firestore.collection('missions').doc(missionId).get();
    if (snapshot.exists) {
      return Mission.fromFirestore(snapshot.data()!);
    }
    return null;
  }

// 获取全部Missions的实时流
  Stream<List<Mission>> getMissionsStream() {
    return _firestore.collection('missions').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Mission.fromFirestore(doc.data()!))
          .toList();
    });
  }

  // 删除Mission
  Future<void> deleteMission(String missionId) async {
    await _firestore.collection('missions').doc(missionId).delete();
  }

  // 读取单个CalendarEvent
  Future<CalendarEvent?> getCalendarEvent(DateTime eventDate) async {
    var snapshot = await _firestore
        .collection('calendarEvents')
        .doc(eventDate.toIso8601String())
        .get();
    if (snapshot.exists) {
      return CalendarEvent.fromFirestore(snapshot.data()!);
    }
    return null;
  }

  // 删除CalendarEvent
  Future<void> deleteCalendarEvent(DateTime eventDate) async {
    await _firestore
        .collection('calendarEvents')
        .doc(eventDate.toIso8601String())
        .delete();
  }

  // 创建或更新用户
  Future<void> setEmployee(Employee Employee) async {
    await _firestore
        .collection('Employees')
        .doc(Employee.id)
        .set(Employee.toFirestore());
  }

// 监听单个用户的变化
  Stream<Employee?> getEmployeeStream(String employeeId) {
    return _firestore
        .collection('Employees')
        .doc(employeeId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Employee.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // 获取单个员工的详细信息
  Future<Employee?> getEmployee(String employeeId) async {
    var snapshot =
        await _firestore.collection('Employees').doc(employeeId).get();
    if (snapshot.exists) {
      return Employee.fromFirestore(snapshot.data()!, snapshot.id);
    }
    return null;
  }

  // 更新用户
  Future<void> updateEmployee(Employee Employee) async {
    await _firestore
        .collection('Employees')
        .doc(Employee.id)
        .update(Employee.toFirestore());
  }

  // 删除用户
  Future<void> deleteEmployee(String EmployeeId) async {
    await _firestore.collection('Employees').doc(EmployeeId).delete();
  }

  // 获取用户的Stream（用于实时更新）
  Stream<List<Employee>> getEmployeesStream() {
    return _firestore.collection('Employees').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => Employee.fromFirestore(doc.data()!, doc.id))
            .toList());
  }
}
