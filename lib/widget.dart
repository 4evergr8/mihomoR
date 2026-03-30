import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mihomoR/view/proxies.dart';
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
    ProxiesView(),
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


    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: '订阅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link),
            label: '节点',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.control_camera),
            label: '控制',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary, // 使用主题中的颜色
        unselectedItemColor: Theme.of(context).colorScheme.onSurface, // 使用主题中的未选中颜色
        backgroundColor: Theme.of(context).colorScheme.surface, // 使用主题中的背景颜色
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
Future<VoidCallback> showLoadingDialog(BuildContext context, {String title = '加载中...'}) async {
  final dialog = showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(title),
        ],
      ),
    ),
  );

  // 返回关闭函数
  return () {
    if (Navigator.canPop(context)) Navigator.pop(context);
  };
}