import 'package:flutter/material.dart';
import '../pages/receiver_list_page.dart';
import '../pages/overview_page.dart';
import '../pages/sending_address_page.dart';
import '../pages/template_management_page.dart';
import '../pages/send_email_page.dart';
import '../pages/batch_send_task_list_page.dart';
import '../pages/invalid_addresses_page.dart';
import '../pages/sending_data_page.dart';
import '../pages/sending_details_page.dart';
import '../pages/config_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentRoute = '/overview';

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
        NavigationItem(title: '发信地址', route: '/sending-address'),
        NavigationItem(title: '模板管理', route: '/template-management'),
      ],
    ),
    NavigationItem(
      title: '发送邮件',
      icon: Icons.send,
      children: [
        NavigationItem(title: '收件人列表', route: '/recipient-list'),
        NavigationItem(title: '发送邮件', route: '/send-email'),
        NavigationItem(title: '批量发送任务', route: '/batch-send-tasks'),
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
                      return _buildNavigationItem(_navigationItems[index]);
                    },
                  ),
                ),
                // 系统配置选项
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.settings, size: 20, color: Colors.grey),
                    title: const Text(
                      '系统配置',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      _openConfigPage();
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

  Widget _buildNavigationItem(NavigationItem item) {
    // 检查是否是当前路由的父级菜单
    bool isParentSelected = false;
    bool hasSelectedChild = false;
    
    if (item.children != null && item.children!.isNotEmpty) {
      hasSelectedChild = item.children!.any((child) => child.route == _currentRoute);
      isParentSelected = hasSelectedChild;
    }

    if (item.children != null && item.children!.isNotEmpty) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: isParentSelected ? Colors.blue[50] : null,
            borderRadius: isParentSelected ? BorderRadius.circular(8) : null,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ExpansionTile(
            leading: Icon(
              item.icon, 
              size: 20,
              color: isParentSelected ? Colors.blue[700] : Colors.grey[600],
            ),
            title: Text(
              item.title,
              style: TextStyle(
                color: isParentSelected ? Colors.blue[700] : Colors.grey[800],
                fontWeight: isParentSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            initiallyExpanded: hasSelectedChild,
            children: item.children!
                .map((child) => _buildChildNavigationItem(child))
                .toList(),
          ),
        ),
      );
    }

    final isSelected = item.route == _currentRoute;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[600] : null,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon, 
          size: 20,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          _navigateToRoute(item.route!);
        },
      ),
    );
  }

  Widget _buildChildNavigationItem(NavigationItem child) {
    final isSelected = child.route == _currentRoute;
    
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[600] : null,
        borderRadius: BorderRadius.circular(6),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ] : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 40, right: 16),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                child.title, 
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _navigateToRoute(child.route!);
        },
      ),
    );
  }

  void _navigateToRoute(String route) {
    setState(() {
      _currentRoute = route;
    });
    navigatorKey.currentState?.pushReplacementNamed(route);
  }

  Widget _getPageByRoute(String route) {
    switch (route) {
      case '/overview':
        return const OverviewPage();
      case '/sending-address':
        return const SendingAddressPage();
      case '/template-management':
        return const TemplateManagementPage();
      case '/recipient-list':
        return const ReceiverListPage();
      case '/send-email':
        return const SendEmailPage();
      case '/batch-send-tasks':
        return const BatchSendTaskListPage();
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

  void _openConfigPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConfigPage(),
      ),
    );
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