import 'package:flutter/material.dart';
import 'package:aliyun_edm_manager/services/background_receiver_service.dart';

/// 后台处理进度页面
/// 显示批量添加收件人的处理进度，用户可以继续操作其他界面
class BackgroundProcessingPage extends StatefulWidget {
  const BackgroundProcessingPage({super.key});

  @override
  State<BackgroundProcessingPage> createState() => _BackgroundProcessingPageState();
}

class _BackgroundProcessingPageState extends State<BackgroundProcessingPage> {
  String _currentStatus = '准备中...';
  int _processedEmails = 0;
  int _totalEmails = 0;
  bool _isCompleted = false;
  List<String> _successLists = [];
  List<String> _failedLists = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    final backgroundService = BackgroundReceiverService.instance;
    
    // 设置进度回调
    backgroundService.setProgressCallback((status, processed, total) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
          _processedEmails = processed;
          _totalEmails = total;
        });
      }
    });

    // 设置完成回调
    backgroundService.setCompletionCallback((successLists, failedLists) {
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _successLists = successLists;
          _failedLists = failedLists;
          _currentStatus = '处理完成';
        });
      }
    });

    // 设置错误回调
    backgroundService.setErrorCallback((error) {
      if (mounted) {
        setState(() {
          _errorMessage = error;
          _currentStatus = '处理失败';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('后台处理进度'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isCompleted && _errorMessage == null)
            TextButton(
              onPressed: () {
                BackgroundReceiverService.instance.stopProcessing();
                Navigator.of(context).pop();
              },
              child: const Text('停止处理'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentStatus,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_totalEmails > 0) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _totalEmails > 0 ? _processedEmails / _totalEmails : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已处理: $_processedEmails / $_totalEmails',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 错误信息
            if (_errorMessage != null) ...[
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // 处理结果
            if (_isCompleted) ...[
              Text(
                '处理结果',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              
              // 成功列表
              if (_successLists.isNotEmpty) ...[
                _buildResultSection(
                  '成功创建的列表 (${_successLists.length})',
                  _successLists,
                  Colors.green,
                  Icons.check_circle,
                ),
                const SizedBox(height: 16),
              ],
              
              // 失败列表
              if (_failedLists.isNotEmpty) ...[
                _buildResultSection(
                  '失败的列表 (${_failedLists.length})',
                  _failedLists,
                  Colors.orange,
                  Icons.warning,
                ),
              ],
            ],
            
            const Spacer(),
            
            // 操作按钮
            if (_isCompleted || _errorMessage != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('返回'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, List<String> items, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $item',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_errorMessage != null) return Icons.error;
    if (_isCompleted) return Icons.check_circle;
    return Icons.sync;
  }

  Color _getStatusColor() {
    if (_errorMessage != null) return Colors.red;
    if (_isCompleted) return Colors.green;
    return Colors.blue;
  }
} 