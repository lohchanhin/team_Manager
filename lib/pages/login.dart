import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance; // Firebase Authentication实例

  Future<void> _login() async {
    try {
      // 使用邮箱和密码进行登录
      await _auth.signInWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text);
      Navigator.pushNamed(context, '/home'); // 登录成功，跳转到主页
    } on FirebaseAuthException catch (e) {
      // 处理登录错误
      _showErrorDialog(e.message ?? '登录失败');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('错误'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('好'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录'),
        automaticallyImplyLeading: false, // 隐藏返回按钮
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '邮箱'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: '密码'),
              obscureText: true, // 密码隐藏
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('登录'),
              onPressed: _login, // 登录按钮调用_login方法
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('注册'),
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
          ],
        ),
      ),
    );
  }
}
