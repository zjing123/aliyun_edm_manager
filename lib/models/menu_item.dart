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
      title: '邮件设置平台',
      icon: Icons.settings,
      route: '/settings',
    ),
    MenuItem(
      title: '邮件人列表',
      icon: Icons.people,
      route: '/receiver-list',
    ),
    MenuItem(
      title: '账号管理',
      icon: Icons.account_circle,
      route: '/account',
    ),
    MenuItem(
      title: '发送域名',
      icon: Icons.domain,
      route: '/domain',
    ),
    MenuItem(
      title: '发送地址',
      icon: Icons.email,
      route: '/sender-address',
    ),
    MenuItem(
      title: '独立IP',
      icon: Icons.public,
      route: '/dedicated-ip',
    ),
    MenuItem(
      title: '邮件标签',
      icon: Icons.label,
      route: '/email-tags',
    ),
    MenuItem(
      title: '联系管理',
      icon: Icons.contacts,
      route: '/contacts',
    ),
    MenuItem(
      title: 'IP防护',
      icon: Icons.security,
      route: '/ip-protection',
    ),
    MenuItem(
      title: '事件分发',
      icon: Icons.event,
      route: '/event-dispatch',
    ),
    MenuItem(
      title: '发送邮件',
      icon: Icons.send,
      route: '/send-email',
    ),
    MenuItem(
      title: '主发地址',
      icon: Icons.alternate_email,
      route: '/main-address',
    ),
    MenuItem(
      title: '数据统计',
      icon: Icons.analytics,
      route: '/statistics',
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