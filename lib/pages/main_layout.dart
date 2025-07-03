import 'package:flutter/material.dart';
import 'receiver_list_page.dart';
import 'config_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const ReceiverListPage(),
  ];

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop(); // close drawer
  }

  void _openConfig() {
    Navigator.of(context).pop(); // close drawer first
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ConfigPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('阿里云 EDM 管理'),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '菜单',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('收件人列表'),
              selected: _selectedIndex == 0,
              onTap: () => _onSelectPage(0),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('系统配置'),
              onTap: _openConfig,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}