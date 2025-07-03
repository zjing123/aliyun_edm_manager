import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '邮件推送控制台',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          _buildNavItem(context, Icons.people, '收件人列表', '/receivers'),
          _buildNavItem(context, Icons.mail_outline, '发送邮件', '/send-email'),
          _buildNavItem(context, Icons.block, '无效地址', '/invalid-address'),
          _buildNavItem(context, Icons.bar_chart, '数据统计', '/statistics'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: currentRoute == route,
      onTap: () {
        Navigator.pop(context); // close the drawer first
        if (currentRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}