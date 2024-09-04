import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/persona.dart'; // 引入 PersonaDrawer
import '../widgets/mission.dart';
import '../widgets/Calendar.dart';
import '../widgets/toDoList.dart';
import '../database/dataManager.dart'; // 引入 FirestoreService

class HomePage extends StatefulWidget {
  final GlobalKey<HomePageState> homePageKey; // 公有类型 HomePageState

  HomePage({Key? key, required this.homePageKey}) : super(key: homePageKey);

  @override
  HomePageState createState() => HomePageState(); // 公有类型
}

class HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Offset fabPosition = Offset(20.0, 20.0); // 浮动按钮的初始位置
  int _currentIndex = 0; // 当前选中的索引
  final FirestoreService _firestoreService = FirestoreService();
  bool _isAdmin = false;
  bool _loading = true;
  late Employee _currentEmployee; // 当前用户的完整信息

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Employee? employee = await _firestoreService.getEmployee(user.uid);
      if (employee != null) {
        setState(() {
          _isAdmin = employee.isAdmin;
          _currentEmployee = employee; // 保存当前用户的信息
          _loading = false;
        });
      }
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void resetCurrentIndex() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: PersonaDrawer(
        homePageKey: widget.homePageKey,
        currentEmployee: _currentEmployee, // 将当前用户信息传递给抽屉组件
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              MissionPage(
                  isAdmin: _isAdmin,
                  currentEmployee: _currentEmployee), // 传递isAdmin和当前用户信息
              CalendarPage(),
              ToDoListPage(
                  isAdmin: _isAdmin,
                  currentEmployee: _currentEmployee), // 传递isAdmin和当前用户信息
            ],
          ),
          Positioned(
            left: fabPosition.dx,
            top: fabPosition.dy,
            child: Draggable(
              child: FloatingActionButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                child: Icon(Icons.person),
                heroTag:
                    'fab-hero-${fabPosition.dx}-${fabPosition.dy}', // 为FAB分配唯一的heroTag
              ),
              feedback: FloatingActionButton(
                onPressed: null,
                child: Icon(Icons.person),
                heroTag:
                    'fab-hero-feedback-${fabPosition.dx}-${fabPosition.dy}', // 为feedback分配唯一的heroTag
              ),
              childWhenDragging: Container(),
              onDraggableCanceled: (velocity, offset) {
                setState(() {
                  fabPosition = offset;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: _isAdmin ? '任务管理' : '任务',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: '待办事项',
          ),
        ],
      ),
    );
  }
}
