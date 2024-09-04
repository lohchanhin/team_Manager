import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/dataManager.dart';
import '../pages/home.dart'; // 引入 HomePage

class PersonaDrawer extends StatefulWidget {
  final GlobalKey<HomePageState> homePageKey; // 使用公有类型 HomePageState
  final Employee currentEmployee; // 当前用户的完整信息

  PersonaDrawer(
      {Key? key, required this.homePageKey, required this.currentEmployee})
      : super(key: key);

  @override
  _PersonaDrawerState createState() => _PersonaDrawerState();
}

class _PersonaDrawerState extends State<PersonaDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _nameController;
  late TextEditingController _positionController;
  late TextEditingController _departmentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentEmployee.name);
    _positionController =
        TextEditingController(text: widget.currentEmployee.position);
    _departmentController =
        TextEditingController(text: widget.currentEmployee.department);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _updateProfile(BuildContext context, Employee currentUserInfo) {
    _nameController.text = currentUserInfo.name;
    _positionController.text = currentUserInfo.position;
    _departmentController.text = currentUserInfo.department;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('编辑个人资料'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: '名字'),
                ),
                TextField(
                  controller: _positionController,
                  decoration: InputDecoration(labelText: '职位'),
                ),
                TextField(
                  controller: _departmentController,
                  decoration: InputDecoration(labelText: '部门'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                FirestoreService().updateEmployee(Employee(
                  id: _auth.currentUser!.uid,
                  name: _nameController.text,
                  position: _positionController.text,
                  department: _departmentController.text,
                ));
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _clearData() {
    _nameController.clear();
    _positionController.clear();
    _departmentController.clear();
    widget.homePageKey.currentState?.resetCurrentIndex(); // 重置 currentIndex
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    _clearData(); // 清除用户数据和状态
    Navigator.of(context).pushReplacementNamed('/login'); // 返回登录页面
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(widget.currentEmployee.name),
            accountEmail: Text(
                '${widget.currentEmployee.position} - ${widget.currentEmployee.department}'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                widget.currentEmployee.name.substring(0, 1).toUpperCase(),
                style: TextStyle(fontSize: 40.0),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('个人资料设置'),
                  onTap: () => _updateProfile(context, widget.currentEmployee),
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('登出'),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
