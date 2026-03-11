import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../theme/util.dart';
import '../widget/bottom_nav_bar.dart';





void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    // 创建自定义的主题
    TextTheme textTheme = createTextTheme(context, "Noto Sans", "Noto Sans");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: '一个工具箱',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: const HomeScreen(), // 使用 HomeScreen 组件
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    return BottomNavBar(); // 仅显示底部导航栏
  }
}