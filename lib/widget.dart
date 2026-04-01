import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mihomoR/view/proxies.dart';
import 'main.dart';
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




Future<VoidCallback> showLoadingDialogGlobal() async {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return () {};

  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (_) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: Theme.of(navigatorKey.currentContext!).colorScheme.primaryContainer,
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  return () => overlayEntry.remove();
}
void showErrorSnackBarGlobal(String message) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;

  final colorScheme = Theme.of(ctx).colorScheme;

  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.surface, // 主题背景色
      content: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: message));
        },
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onSurface), // 主题文本色
        ),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}