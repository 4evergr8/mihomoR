import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'view/subscriptions.dart';
import 'view/control.dart';



class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    SubscriptionView(),
    ControlView(),
    ControlView(),



  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    // 获取当前主题
    final theme = Theme.of(context);

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: '配置',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.control_camera),
            label: '控制',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.secondary, // 使用主题中的颜色
        unselectedItemColor: theme.colorScheme.onSurface, // 使用主题中的未选中颜色
        backgroundColor: theme.colorScheme.surface, // 使用主题中的背景颜色
        onTap: _onItemTapped,
      ),
    );
  }
}


Future<void> showErrorDialog(BuildContext context, String title, Object error) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(error.toString())),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
Future<VoidCallback> showLoadingDialog(BuildContext context, {String? title}) async {
  final dialogContext = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (title != null) ...[
            const SizedBox(height: 12),
            Text(title),
          ],
        ],
      ),
    ),
  );

  // 返回一个关闭函数
  return () => Navigator.of(context, rootNavigator: true).pop();
}