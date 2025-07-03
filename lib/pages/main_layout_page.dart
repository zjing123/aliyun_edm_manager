import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class MainLayoutPage extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayoutPage({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航菜单
          Container(
            width: _isCollapsed ? 60 : 240,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // 应用标题
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (!_isCollapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '邮件管理平台',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                          _isCollapsed ? Icons.menu : Icons.menu_open,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isCollapsed = !_isCollapsed;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // 菜单列表
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: MenuData.menuItems.length,
                    itemBuilder: (context, index) {
                      final item = MenuData.menuItems[index];
                      final isSelected = widget.currentRoute == item.route;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.pushNamed(context, item.route);
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue[50] : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected 
                                    ? Border.all(color: Colors.blue[200]!)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                                  ),
                                  if (!_isCollapsed) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected ? Colors.blue[600] : Colors.grey[800],
                                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 右侧内容区域
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}