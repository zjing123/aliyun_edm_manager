import 'package:flutter/material.dart';
import 'package:aliyun_edm_manager/models/common/tool_item.dart';
import 'package:aliyun_edm_manager/pages/util_tools/email_split_page.dart';

class UtilToolsPage extends StatelessWidget {
  // 响应式断点配置
  static final Map<double, int> _breakpoints = {
    1600.0: 9,
    1400.0: 8,
    1200.0: 7,
    1000.0: 6,
    800.0: 5,
    600.0: 4,
    500.0: 3,
    0.0: 2, // 默认值
  };

  // 图标和文字尺寸常量
  static const double _minIconSize = 24.0;
  static const double _maxIconSize = 60.0;
  static const double _minFontSize = 10.0;
  static const double _maxFontSize = 18.0;

  const UtilToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实用工具'),
      ),
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
          final cardSize = _calculateCardSize(constraints.maxWidth, crossAxisCount);
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                return _buildToolCard(
                  context,
                  cardSize: cardSize,
                  tool: tools[index],
                );
              },
            ),
          );
        },
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    final availableWidth = width - 48;
    return _breakpoints.entries
        .firstWhere((entry) => availableWidth > entry.key)
        .value;
  }

  // 提取卡片尺寸计算逻辑
  double _calculateCardSize(double screenWidth, int crossAxisCount) {
    final availableWidth = screenWidth - 48;
    final spacing = 16.0;
    return ((availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount)
        .clamp(80.0, double.infinity);
  }

  Widget _buildToolCard(BuildContext context, {
    required double cardSize,
    required ToolItem tool,
  }) {
    final iconSize = (cardSize * 0.4).clamp(_minIconSize, _maxIconSize);
    final fontSize = (cardSize * 0.12).clamp(_minFontSize, _maxFontSize);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => tool.onTap(context),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 80.0,
            minHeight: 80.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tool.icon, size: iconSize, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                tool.title,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ToolItem> get tools => [
    ToolItem(
      title: '邮箱分割',
      icon: Icons.call_split,
      onTap: (context) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EmailSplitPage()),
        );
      },
    ),
    ToolItem(
      title: '邮件格式调整',
      icon: Icons.format_quote,
      onTap: (context) {
        // TODO: 实现邮箱分割功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邮件格式调整功能开发中...')),
        );
      },
    ),
    // 可以继续添加更多工具
  ];
} 