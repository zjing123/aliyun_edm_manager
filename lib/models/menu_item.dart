import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<MenuItem>? children;

  const MenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.children,
  });
}

// 菜单数据定义
class MenuData {
  static const List<MenuItem> menuItems = [
    MenuItem(
      title: '模板管理',
      icon: Icons.description,
      route: '/template-management',
    ),
    MenuItem(
      title: '收件人列表',
      icon: Icons.people,
      route: '/receiver-list',
    ),
    MenuItem(
      title: '发送数据',
      icon: Icons.data_usage,
      route: '/send-data',
    ),
    MenuItem(
      title: '发送详情',
      icon: Icons.details,
      route: '/send-details',
    ),
  ];
}