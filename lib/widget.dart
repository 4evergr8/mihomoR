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
  late final PageController _pageController;

  static final List<Widget> _widgetOptions = <Widget>[
    SubscriptionView(),
    ProxiesView(),
    ControlView(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // 禁止手势滑动
        children: _widgetOptions,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
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
        selectedItemColor: colorScheme.secondary,
        unselectedItemColor: colorScheme.onSurface,
        backgroundColor: colorScheme.surface,
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
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (_) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: Colors.black.withOpacity(0.1),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // 返回关闭函数
  return () {
    overlayEntry.remove();
  };
}