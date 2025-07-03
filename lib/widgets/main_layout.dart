import 'package:flutter/material.dart';
import '../pages/receiver_list_page.dart';
import '../pages/overview_page.dart';
import '../pages/sending_domain_page.dart';
import '../pages/sending_address_page.dart';
import '../pages/independent_ip_page.dart';
import '../pages/email_tags_page.dart';
import '../pages/template_management_page.dart';
import '../pages/ip_protection_page.dart';
import '../pages/event_distribution_page.dart';
import '../pages/send_email_page.dart';
import '../pages/invalid_addresses_page.dart';
import '../pages/sending_data_page.dart';
import '../pages/sending_details_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: '概览',
      route: '/overview',
      icon: Icons.dashboard,
    ),
    NavigationItem(
      title: '邮件设置',
      icon: Icons.settings,
      children: [
        NavigationItem(title: '发信域名', route: '/sending-domain'),
        NavigationItem(title: '发信地址', route: '/sending-address'),
        NavigationItem(title: '独立 IP', route: '/independent-ip'),
        NavigationItem(title: '邮件标签', route: '/email-tags'),
        NavigationItem(title: '模板管理', route: '/template-management'),
        NavigationItem(title: 'IP防护', route: '/ip-protection'),
        NavigationItem(title: '事件分发', route: '/event-distribution'),
      ],
    ),
    NavigationItem(
      title: '发送邮件',
      icon: Icons.send,
      children: [
        NavigationItem(title: '收件人列表', route: '/recipient-list'),
        NavigationItem(title: '发送邮件', route: '/send-email'),
        NavigationItem(title: '无效地址', route: '/invalid-addresses'),
      ],
    ),
    NavigationItem(
      title: '数据统计',
      icon: Icons.bar_chart,
      children: [
        NavigationItem(title: '发送数据', route: '/sending-data'),
        NavigationItem(title: '发送详情', route: '/sending-details'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: 250,
            color: Colors.grey[100],
            child: Column(
              children: [
                // 顶部标题
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: const Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '邮件推送控制台',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 导航菜单
                Expanded(
                  child: ListView.builder(
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      return _buildNavigationItem(_navigationItems[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
          // 主内容区域
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Navigator(
                key: navigatorKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => _getPageByRoute(settings.name ?? '/'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item, int index) {
    if (item.children != null && item.children!.isNotEmpty) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(item.icon, size: 20),
          title: Text(item.title),
          children: item.children!
              .map((child) => ListTile(
                    contentPadding: const EdgeInsets.only(left: 56),
                    title: Text(child.title, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      navigatorKey.currentState?.pushReplacementNamed(child.route!);
                    },
                  ))
              .toList(),
        ),
      );
    }

    return ListTile(
      leading: Icon(item.icon, size: 20),
      title: Text(item.title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        navigatorKey.currentState?.pushReplacementNamed(item.route!);
      },
    );
  }

  Widget _getPageByRoute(String route) {
    switch (route) {
      case '/overview':
        return const OverviewPage();
      case '/sending-domain':
        return const SendingDomainPage();
      case '/sending-address':
        return const SendingAddressPage();
      case '/independent-ip':
        return const IndependentIPPage();
      case '/email-tags':
        return const EmailTagsPage();
      case '/template-management':
        return const TemplateManagementPage();
      case '/ip-protection':
        return const IPProtectionPage();
      case '/event-distribution':
        return const EventDistributionPage();
      case '/recipient-list':
        return const ReceiverListPage();
      case '/send-email':
        return const SendEmailPage();
      case '/invalid-addresses':
        return const InvalidAddressesPage();
      case '/sending-data':
        return const SendingDataPage();
      case '/sending-details':
        return const SendingDetailsPage();
      default:
        return const OverviewPage();
    }
  }
}

class NavigationItem {
  final String title;
  final String? route;
  final IconData? icon;
  final List<NavigationItem>? children;

  NavigationItem({
    required this.title,
    this.route,
    this.icon,
    this.children,
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();