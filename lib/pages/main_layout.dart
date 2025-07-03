import 'package:flutter/material.dart';
import 'receiver_list_page.dart';
import 'template_management_page.dart';
import 'send_statistics_page.dart';
import 'send_details_page.dart';
import 'send_email_page.dart';
import 'invalid_addresses_page.dart';
import 'config_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: '邮件设置',
      icon: Icons.settings,
      children: [
        NavigationChild(title: '模板管理', icon: Icons.description_outlined),
      ],
    ),
    NavigationItem(
      title: '发送邮件',
      icon: Icons.send,
      children: [
        NavigationChild(title: '发送邮件', icon: Icons.send_outlined),
        NavigationChild(title: '收件人列表', icon: Icons.people_outline),
        NavigationChild(title: '无效地址', icon: Icons.error_outline),
      ],
    ),
    NavigationItem(
      title: '数据统计',
      icon: Icons.analytics,
      children: [
        NavigationChild(title: '发送数据', icon: Icons.bar_chart),
        NavigationChild(title: '发送详情', icon: Icons.list_alt),
      ],
    ),
  ];

  Widget _getPageByIndex(int index) {
    switch (index) {
      case 0: // 模板管理
        return const TemplateManagementPage();
      case 1: // 发送邮件
        return const SendEmailPage();
      case 2: // 收件人列表
        return const ReceiverListPage();
      case 3: // 无效地址
        return const InvalidAddressesPage();
      case 4: // 发送数据
        return const SendStatisticsPage();
      case 5: // 发送详情
        return const SendDetailsPage();
      default:
        return const ReceiverListPage();
    }
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return '模板管理';
      case 1:
        return '发送邮件';
      case 2:
        return '收件人列表';
      case 3:
        return '无效地址';
      case 4:
        return '发送数据';
      case 5:
        return '发送详情';
      default:
        return '收件人列表';
    }
  }

  void _openConfigPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          Container(
            width: 250,
            color: Colors.grey[100],
            child: Column(
              children: [
                // 头部
                Container(
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                                         boxShadow: [
                       BoxShadow(
                         color: Colors.grey.withValues(alpha: 0.2),
                         spreadRadius: 1,
                         blurRadius: 4,
                         offset: const Offset(0, 2),
                       ),
                     ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.email, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'EDM管理系统',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 导航菜单
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildNavigationItems(),
                  ),
                ),
                // 底部设置
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openConfigPage,
                      icon: const Icon(Icons.settings),
                      label: const Text('系统配置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右侧内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部标题栏
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                                         boxShadow: [
                       BoxShadow(
                         color: Colors.grey.withValues(alpha: 0.1),
                         spreadRadius: 1,
                         blurRadius: 4,
                         offset: const Offset(0, 2),
                       ),
                     ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(_selectedIndex),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            // 刷新当前页面
                          });
                        },
                        tooltip: '刷新',
                      ),
                    ],
                  ),
                ),
                // 主内容区域
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: _getPageByIndex(_selectedIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavigationItems() {
    List<Widget> items = [];
    int childIndex = 0;
    
    for (int i = 0; i < _navigationItems.length; i++) {
      final item = _navigationItems[i];
      
      // 添加分组标题
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
      
      // 添加子菜单项
      for (final child in item.children) {
        final isSelected = childIndex == _selectedIndex;
        items.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: ListTile(
              leading: Icon(
                child.icon,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                size: 20,
              ),
              title: Text(
                child.title,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.blue[600] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedTileColor: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                setState(() {
                  _selectedIndex = childIndex;
                });
              },
            ),
          ),
        );
        childIndex++;
      }
      
      // 添加分隔线
      if (i < _navigationItems.length - 1) {
        items.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 1,
            color: Colors.grey[300],
          ),
        );
      }
    }
    
    return items;
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final List<NavigationChild> children;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.children,
  });
}

class NavigationChild {
  final String title;
  final IconData icon;

  NavigationChild({
    required this.title,
    required this.icon,
  });
} 