import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/dataManager.dart'; // 导入Firestore服务
// import '../models/user.dart'; // 导入User数据模型

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // 使用Firebase Authentication创建用户
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 用户注册成功，弹出对话框收集额外信息
      if (userCredential.user != null) {
        _showAdditionalInfoDialog(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      // 显示注册错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('注册失败: ${e.message}')),
      );
    }
  }

  void _showAdditionalInfoDialog(String userId) {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _positionController = TextEditingController();
    final TextEditingController _departmentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('填写额外信息'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: '名字')),
                TextField(
                    controller: _positionController,
                    decoration: InputDecoration(labelText: '职位')),
                TextField(
                    controller: _departmentController,
                    decoration: InputDecoration(labelText: '部门')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () {
                _saveUserInfo(userId, _nameController.text,
                    _positionController.text, _departmentController.text);
                Navigator.of(context).pop(); // 关闭对话框
                Navigator.of(context).pop(); // 返回登录界面
              },
            ),
          ],
        );
      },
    );
  }

  void _saveUserInfo(
      String userId, String name, String position, String department) {
    Employee user = Employee(
      id: userId,
      name: name,
      position: position,
      department: department,
    );

    FirestoreService _firestoreService = FirestoreService();
    _firestoreService.setEmployee(user); // 保存用户信息
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('注册'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '邮箱',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('注册'),
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}
