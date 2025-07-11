import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:aliyun_edm_manager/services/di/service_locator.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/services/config/config_service.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_list_model.dart';
import 'package:aliyun_edm_manager/constants/pagination_constants.dart';
import 'package:aliyun_edm_manager/constants/receiver_constants.dart';

/// 改进的批量创建收件人页面 - 使用依赖注入模式
class BatchCreateReceiverPageImproved extends StatefulWidget {
  const BatchCreateReceiverPageImproved({super.key});

  @override
  State<BatchCreateReceiverPageImproved> createState() => _BatchCreateReceiverPageImprovedState();
}

class _BatchCreateReceiverPageImprovedState extends State<BatchCreateReceiverPageImproved> {
  // 依赖注入的服务
  late final ServiceLocator _serviceLocator;
  late final AliyunServiceManager _aliyunServiceManager;
  late final ReceiverListProvider _receiverListProvider;
  late final GlobalConfigProvider _globalConfigProvider;

  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  
  // 表单控制器
  final TextEditingController _prefixController = TextEditingController(text: '收件人列表');
  final TextEditingController _suffixController = TextEditingController(text: '@nexperia.com');
  final TextEditingController _countController = TextEditingController(text: '1000');
  final TextEditingController _filterEmailsController = TextEditingController();
  
  // 设置选项
  bool _removeDuplicates = true;
  bool _ignoreInvalidEmails = true;
  bool _skipEmptyEmails = true;
  bool _mergeDefaultFilterEmails = true;
  
  // 处理进度
  int _totalEmails = 0;
  int _processedEmails = 0;
  int _totalLists = 0;
  int _processedLists = 0;
  String _currentStatus = '';
  
  // 处理结果
  final List<String> _successLists = [];
  final List<String> _failedLists = [];
  final List<String> _invalidEmails = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// 初始化服务 - 使用依赖注入
  Future<void> _initializeServices() async {
    try {
      // 获取服务定位器实例
      _serviceLocator = ServiceLocator();
      
      // 确保服务已初始化
      await _serviceLocator.initialize();
      
      // 获取所需的服务
      _aliyunServiceManager = _serviceLocator.aliyunServiceManager;
      _receiverListProvider = _serviceLocator.receiverListProvider;
      _globalConfigProvider = _serviceLocator.globalConfigProvider;
      
      // 检查配置
      if (!_globalConfigProvider.isConfigured) {
        setState(() {
          _currentStatus = '阿里云AccessKey未配置，请先配置';
        });
        return;
      }
      
      setState(() {
        _currentStatus = '服务初始化完成';
      });
    } catch (e) {
      setState(() {
        _currentStatus = '服务初始化失败: $e';
      });
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _suffixController.dispose();
    _countController.dispose();
    _filterEmailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("批量创建收件人列表 (改进版)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            const Text(
              '批量创建收件人列表 (改进版)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 说明信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '改进说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 使用依赖注入模式，降低耦合度\n'
                    '• 统一的服务管理，便于测试和维护\n'
                    '• 自动配置检查，减少重复代码\n'
                    '• 更好的错误处理和状态管理\n'
                    '• 支持收件人列表数量限制检查（每个列表最多2000个收件人）',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 文件选择区域
            _buildFileSelectionSection(),
            const SizedBox(height: 24),
            
            // 配置区域
            _buildConfigurationSection(),
            const SizedBox(height: 24),
            
            // 设置选项
            _buildSettingsSection(),
            const SizedBox(height: 24),
            
            // 处理进度
            if (_isProcessing) _buildProgressSection(),
            
            // 开始创建按钮
            _buildCreateButton(),
            const SizedBox(height: 24),
            
            // 处理结果
            if (_successLists.isNotEmpty || _failedLists.isNotEmpty) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_upload, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '文件选择',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_selectedFile == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '点击选择文件',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '支持 CSV、TXT 格式，每行一个邮箱地址',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _selectFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('选择文件'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已选择文件: ${_selectedFile!.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '大小: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '配置设置',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('收件人列表前缀'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _prefixController,
                      decoration: InputDecoration(
                        hintText: '收件人列表',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('收件人别名后缀'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _suffixController,
                      decoration: InputDecoration(
                        hintText: '@nexperia.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('每个列表的收件人数量'),
              const SizedBox(height: 8),
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '1000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: '每个收件人列表最多可添加${ReceiverConstants.maxReceiversPerList}个收件人',
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('收件人列表数量限制'),
                          content: Text(
                            '根据阿里云API限制，每个收件人列表最多只能添加${ReceiverConstants.maxReceiversPerList}个收件人。\n\n'
                            '如果输入的数量超过此限制，系统会自动调整每个列表的收件人数量，确保不超过限制。\n\n'
                            '建议：根据您的需求合理设置每个列表的收件人数量，避免超过限制。',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('知道了'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                onChanged: (value) {
                  // 实时验证输入值
                  final count = int.tryParse(value);
                  if (count != null && count > ReceiverConstants.maxReceiversPerList) {
                    // 可以在这里添加视觉提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('收件人数量不能超过${ReceiverConstants.maxReceiversPerList}个'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '处理设置',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('跳过空邮箱'),
            subtitle: const Text('忽略文件中的空行'),
            value: _skipEmptyEmails,
            onChanged: (value) {
              setState(() {
                _skipEmptyEmails = value ?? true;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('忽略无效邮箱'),
            subtitle: const Text('过滤掉格式不正确的邮箱地址'),
            value: _ignoreInvalidEmails,
            onChanged: (value) {
              setState(() {
                _ignoreInvalidEmails = value ?? true;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('去除重复邮箱'),
            subtitle: const Text('自动去除重复的邮箱地址'),
            value: _removeDuplicates,
            onChanged: (value) {
              setState(() {
                _removeDuplicates = value ?? true;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('合并默认过滤邮箱'),
            subtitle: const Text('同时应用系统默认的过滤邮箱列表'),
            value: _mergeDefaultFilterEmails,
            onChanged: (value) {
              setState(() {
                _mergeDefaultFilterEmails = value ?? true;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('自定义过滤邮箱'),
              const SizedBox(height: 8),
              TextField(
                controller: _filterEmailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '每行一个邮箱地址，这些邮箱将被过滤掉',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '处理进度',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            _currentStatus,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          if (_totalLists > 0) ...[
            LinearProgressIndicator(
              value: _processedLists / _totalLists,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text('收件人列表: $_processedLists / $_totalLists'),
          ],
          
          if (_totalEmails > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _processedEmails / _totalEmails,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text('收件人: $_processedEmails / $_totalEmails'),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _startProcessing,
        icon: _isProcessing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isProcessing ? '处理中...' : '开始创建'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '处理结果',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_successLists.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '成功创建: ${_successLists.length} 个列表',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          if (_failedLists.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.error, color: Colors.red[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '创建失败: ${_failedLists.length} 个列表',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          if (_invalidEmails.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '无效邮箱: ${_invalidEmails.length} 个',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('选择文件失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedFile == null) return;

    // 检查配置
    if (_prefixController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入收件人列表前缀'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_suffixController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入收件人别名后缀'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? count;
    try {
      count = int.parse(_countController.text.trim());
      if (count <= 0) throw Exception('数量必须大于0');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的收件人数量'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _totalEmails = 0;
      _processedEmails = 0;
      _totalLists = 0;
      _processedLists = 0;
      _currentStatus = '';
      _successLists.clear();
      _failedLists.clear();
      _invalidEmails.clear();
    });

    try {
      await _processFile(count);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('处理失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processFile(int countPerList) async {
    // 使用依赖注入的服务
    final receiverService = _aliyunServiceManager.receiverService;
    
    // 从Provider获取现有的收件人列表名称用于重复检查
    setState(() {
      _currentStatus = '正在获取现有收件人列表...';
    });
    
    final existingNames = _receiverListProvider.receiverNames;
    
    // 读取文件内容
    setState(() {
      _currentStatus = '正在读取文件...';
    });

    List<String> emails = await _readEmailsFromFile();
    
    // 过滤邮箱
    setState(() {
      _currentStatus = '正在过滤邮箱...';
    });
    
    emails = await _filterEmails(emails);
    
    if (emails.isEmpty) {
      setState(() {
        _currentStatus = '没有有效的邮箱地址';
      });
      return;
    }

    // 拆分邮箱列表
    final emailBatches = _splitEmails(emails, countPerList);
    
    setState(() {
      _totalEmails = emails.length;
      _totalLists = emailBatches.length;
      _currentStatus = '开始创建收件人列表...';
    });

    // 处理每个批次
    for (int i = 0; i < emailBatches.length; i++) {
      var batch = emailBatches[i];
      final baseListName = '${_prefixController.text.trim()}${i + 1}';
      final alias = '${_getCurrentDate()}${(i + 1).toString().padLeft(2, '0')}${_suffixController.text.trim()}';
      
      // 检查收件人列表是否存在
      final existingReceiver = await _checkReceiverListExists(baseListName);
      
      String finalListName = baseListName;
      String receiverId = '';
      
      if (existingReceiver == null) {
        // 情况1：收件人列表不存在，直接创建
        setState(() {
          _currentStatus = '正在创建收件人列表: $finalListName (${i + 1}/$_totalLists)';
        });
        
        try {
          final createResponse = await receiverService.createReceiver(finalListName, alias: alias);
          receiverId = createResponse.receiverId;
          _successLists.add(finalListName);
        } catch (e) {
          print('创建收件人列表失败: $finalListName, 错误: $e');
          _failedLists.add(finalListName);
          continue;
        }
      } else {
        // 检查现有列表是否有收件人数据
        final hasReceivers = await _checkReceiverListHasData(existingReceiver.receiverId);
        
        if (!hasReceivers) {
          // 情况2：收件人列表存在但没有收件人数据，直接使用现有列表
          setState(() {
            _currentStatus = '使用现有空列表: $finalListName (${i + 1}/$_totalLists)';
          });
          
          receiverId = existingReceiver.receiverId;
          _successLists.add(finalListName);
        } else {
          // 情况3：收件人列表存在且有收件人数据，需要用户选择
          final userChoice = await _showReceiverListConflictDialog(finalListName, existingReceiver);
          
          if (userChoice == null) {
            // 用户取消
            setState(() {
              _currentStatus = '用户取消处理: $finalListName';
            });
            continue;
          } else if (userChoice == 'delete') {
            // 用户选择删除现有列表
            setState(() {
              _currentStatus = '正在删除现有列表: $finalListName';
            });
            
            try {
              await receiverService.deleteReceiver(existingReceiver.receiverId);
              
              // 等待删除完成，然后创建新列表（添加后缀避免重名）
              final newListName = '${finalListName}_${DateTime.now().millisecondsSinceEpoch}';
              setState(() {
                _currentStatus = '正在创建新列表: $newListName (${i + 1}/$_totalLists)';
              });
              
              final createResponse = await receiverService.createReceiver(newListName, alias: alias);
              receiverId = createResponse.receiverId;
              finalListName = newListName;
              _successLists.add(finalListName);
            } catch (e) {
              print('删除或创建收件人列表失败: $finalListName, 错误: $e');
              _failedLists.add(finalListName);
              continue;
            }
          } else if (userChoice == 'append') {
            // 用户选择直接追加到现有列表
            setState(() {
              _currentStatus = '追加到现有列表: $finalListName (${i + 1}/$_totalLists)';
            });
            
            receiverId = existingReceiver.receiverId;
            _successLists.add(finalListName);
          }
        }
      }
      
      // 检查收件人列表数量限制（每个列表最多2000个收件人）
      const maxReceiversPerList = ReceiverConstants.maxReceiversPerList;
      
      try {
        // 查询当前收件人列表中的收件人数量
        final currentDetail = await receiverService.getReceiverDetail(receiverId, pageSize: 1);
        final currentCount = currentDetail?.members.length ?? 0;
        
        debugPrint('📊 [批量创建] 收件人列表状态检查:');
        debugPrint('   - 收件人列表ID: $receiverId');
        debugPrint('   - 当前收件人数量: $currentCount');
        debugPrint('   - 本次添加数量: ${batch.length}');
        debugPrint('   - 添加后总数量: ${currentCount + batch.length}');
        debugPrint('   - 最大允许数量: $maxReceiversPerList');
        
        // 检查是否会超过限制
        if (currentCount + batch.length > maxReceiversPerList) {
          final canAddCount = maxReceiversPerList - currentCount;
          debugPrint('⚠️ [批量创建] 警告: 添加后将超过收件人列表限制');
          debugPrint('📝 [批量创建] 当前列表已有: $currentCount 个收件人');
          debugPrint('📝 [批量创建] 本次尝试添加: ${batch.length} 个收件人');
          debugPrint('📝 [批量创建] 最多还能添加: $canAddCount 个收件人');
          
          if (canAddCount <= 0) {
            debugPrint('❌ [批量创建] 收件人列表已达到最大限制($maxReceiversPerList个)，无法添加更多收件人');
            setState(() {
              _currentStatus = '错误: 收件人列表已达到最大限制($maxReceiversPerList个)';
            });
            continue;
          }
          
          // 如果超过限制，只添加能添加的部分
          debugPrint('🔄 [批量创建] 自动调整添加数量: ${batch.length} -> $canAddCount');
          final adjustedBatch = batch.take(canAddCount.toInt()).toList();
          
          setState(() {
            _currentStatus = '由于列表限制，只添加 $canAddCount 个收件人，剩余 ${batch.length - canAddCount} 个未添加';
          });
          
          // 使用调整后的批次继续处理
          batch = adjustedBatch;
        }
      } catch (e) {
        debugPrint('⚠️ [批量创建] 无法查询当前收件人数量，继续执行: $e');
        // 如果无法查询当前数量，继续执行，但给出警告
        debugPrint('⚠️ [批量创建] 建议: 检查收件人列表是否存在或网络连接是否正常');
      }
      
      // 分批添加收件人（每次最多400个，符合API限制500条记录）
      final emailChunks = _chunkEmails(batch, 400);
      for (int j = 0; j < emailChunks.length; j++) {
        final chunk = emailChunks[j];
        setState(() {
          _currentStatus = '正在添加收件人到列表: $finalListName (${j + 1}/${emailChunks.length})';
        });
        
        // 为每个邮箱创建收件人参数
        final receiverParamsList = chunk.map((email) => 
          ReceiverDetailParams(email: email, fieldValues: {})
        ).toList();
        
        // 批量添加收件人
        try {
          final saveResult = await receiverService.saveReceiverDetails(receiverId, receiverParamsList);
          
          // 记录处理结果
          if (saveResult.hasFailed) {
            print('⚠️ [批量创建] 部分收件人添加失败:');
            print('   - 成功: ${saveResult.successCount} 个');
            print('   - 失败: ${saveResult.errorCount} 个');
            print('   - 已存在: ${saveResult.existList?.length ?? 0} 个');
            if (saveResult.failList != null) {
              print('   - 失败列表: ${saveResult.failList!.take(3).join(', ')}${saveResult.failList!.length > 3 ? '...' : ''}');
            }
          }
          
          setState(() {
            _processedEmails += chunk.length;
          });
          
          // 添加请求间隔，避免API调用过于频繁
          if (j < emailChunks.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          print('❌ [批量创建] 添加收件人失败: $e');
          
          // 检查是否是收件人列表ID错误
          if (e.toString().contains('InvalidReceiverId.Malformed')) {
            setState(() {
              _currentStatus = '错误: 收件人列表ID不存在或格式错误，跳过此批次';
            });
            _failedLists.add(finalListName);
            continue;
          }
          
          // 检查是否是批量大小错误
          if (e.toString().contains('InvalidReceiverDetailMax.Malformed')) {
            setState(() {
              _currentStatus = '错误: 批量大小超过限制，尝试减少批量大小...';
            });
            
            // 尝试减少批量大小重试
            try {
              final smallerChunks = _chunkEmails(chunk, (chunk.length / 2).round());
              for (final smallerChunk in smallerChunks) {
                final smallerParamsList = smallerChunk.map((email) => 
                  ReceiverDetailParams(email: email, fieldValues: {})
                ).toList();
                
                await receiverService.saveReceiverDetails(receiverId, smallerParamsList);
                setState(() {
                  _processedEmails += smallerChunk.length;
                });
              }
            } catch (retryError) {
              print('❌ [批量创建] 减少批量大小后仍然失败: $retryError');
              setState(() {
                _currentStatus = '错误: 即使减少批量大小仍然失败，跳过此批次';
              });
              _failedLists.add(finalListName);
              continue;
            }
          } else {
            // 其他错误
            setState(() {
              _currentStatus = '错误: 添加收件人失败，跳过此批次';
            });
            _failedLists.add(finalListName);
            continue;
          }
        }
      }
      
      setState(() {
        _processedLists = i + 1;
      });
    }
    
    setState(() {
      _currentStatus = '处理完成';
    });
  }

  Future<List<String>> _readEmailsFromFile() async {
    if (_selectedFile == null) return [];
    
    try {
      final file = File(_selectedFile!.path!);
      final content = await file.readAsString(encoding: utf8);
      final lines = content.split('\n');
      
      return lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('读取文件失败: $e');
    }
  }

  Future<List<String>> _filterEmails(List<String> emails) async {
    List<String> filteredEmails = List.from(emails);
    
    // 跳过空邮箱
    if (_skipEmptyEmails) {
      filteredEmails = filteredEmails.where((email) => email.isNotEmpty).toList();
    }
    
    // 过滤无效邮箱
    if (_ignoreInvalidEmails) {
      final validEmails = <String>[];
      for (final email in filteredEmails) {
        if (_isValidEmail(email)) {
          validEmails.add(email);
        } else {
          _invalidEmails.add(email);
        }
      }
      filteredEmails = validEmails;
    }
    
    // 邮箱去重
    if (_removeDuplicates) {
      filteredEmails = filteredEmails.toSet().toList();
    }
    
    // 合并默认过滤邮箱和页面输入的过滤邮箱（可选）
    Set<String> allFilterEmails = {};
    final pageFilterEmails = _filterEmailsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_mergeDefaultFilterEmails) {
      final configService = await ConfigService.getInstance();
      final defaultFilterEmails = configService.getFilterEmails();
      allFilterEmails = {...defaultFilterEmails, ...pageFilterEmails};
    } else {
      allFilterEmails = {...pageFilterEmails};
    }
    if (allFilterEmails.isNotEmpty) {
      print('=== 过滤邮件列表 ===');
      print('过滤列表中的邮箱: $allFilterEmails');
      print('过滤前邮箱数量: ${filteredEmails.length}');
      final beforeFilter = List<String>.from(filteredEmails);
      filteredEmails = filteredEmails.where((email) => !allFilterEmails.contains(email)).toList();
      print('过滤后邮箱数量: ${filteredEmails.length}');
      print('被过滤掉的邮箱: ${beforeFilter.where((email) => allFilterEmails.contains(email)).toList()}');
    }
    
    return filteredEmails;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  List<List<String>> _splitEmails(List<String> emails, int countPerList) {
    final batches = <List<String>>[];
    for (int i = 0; i < emails.length; i += countPerList) {
      final end = (i + countPerList < emails.length) ? i + countPerList : emails.length;
      batches.add(emails.sublist(i, end));
    }
    return batches;
  }

  List<List<String>> _chunkEmails(List<String> emails, int chunkSize) {
    // 限制最大批量大小为400，符合API限制500条记录
    final maxChunkSize = chunkSize > 400 ? 400 : chunkSize;
    final chunks = <List<String>>[];
    for (int i = 0; i < emails.length; i += maxChunkSize) {
      final end = (i + maxChunkSize < emails.length) ? i + maxChunkSize : emails.length;
      chunks.add(emails.sublist(i, end));
    }
    return chunks;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// 检查收件人列表是否存在
  Future<ReceiverListModel?> _checkReceiverListExists(String listName) async {
    try {
      final receiverService = _aliyunServiceManager.receiverService;
      final receivers = await receiverService.queryReceivers();
      
      // 查找完全匹配的列表名称
      for (final receiver in receivers) {
        if (receiver['ReceiversName']?.toString().toLowerCase() == listName.toLowerCase()) {
          return ReceiverListModel.fromMap(receiver);
        }
      }
      
      return null;
    } catch (e) {
      print('检查收件人列表存在性失败: $e');
      return null;
    }
  }

  /// 检查收件人列表是否有数据
  Future<bool> _checkReceiverListHasData(String receiverId) async {
    try {
      final receiverService = _aliyunServiceManager.receiverService;
      final detail = await receiverService.getReceiverDetail(
        receiverId,
        pageSize: 1, // 只需要检查是否有数据，不需要获取所有数据
      );
      
      return detail?.members.isNotEmpty ?? false;
    } catch (e) {
      print('检查收件人列表数据失败: $e');
      return false;
    }
  }

  /// 显示收件人列表冲突对话框
  Future<String?> _showReceiverListConflictDialog(String listName, ReceiverListModel existingReceiver) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('收件人列表冲突'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('收件人列表 "$listName" 已存在，且包含收件人数据。'),
              const SizedBox(height: 16),
              const Text('请选择处理方式：'),
              const SizedBox(height: 8),
              const Text('• 删除现有列表并创建新列表（列表名称会添加时间戳后缀）'),
              const Text('• 直接追加到现有列表（保留现有数据）'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // 取消
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('delete'), // 删除并新建
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除并新建'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('append'), // 直接追加
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text('直接追加'),
            ),
          ],
        );
      },
    );
  }
} 