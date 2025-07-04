import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../services/aliyun_edm_service.dart';
import '../services/config_service.dart';
import '../models/receiver_detail.dart';
import '../providers/receiver_list_provider.dart';
import '../utils/dialog_util.dart';
import 'filter_emails_config_page.dart';

class BatchCreateReceiverPage extends StatefulWidget {
  const BatchCreateReceiverPage({super.key});

  @override
  State<BatchCreateReceiverPage> createState() => _BatchCreateReceiverPageState();
}

class _BatchCreateReceiverPageState extends State<BatchCreateReceiverPage> {
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
  List<String> _successLists = [];
  List<String> _failedLists = [];
  List<String> _invalidEmails = [];

  @override
  void initState() {
    super.initState();
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
        title: const Text("批量创建收件人列表"),
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
              '批量创建收件人列表',
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
                        '功能说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 支持CSV、TXT文件格式，每行一个邮箱地址\n'
                    '• 自动按指定数量拆分邮箱数据\n'
                    '• 支持邮箱去重、无效邮箱过滤\n'
                    '• 自动创建收件人列表并添加收件人\n'
                    '• 支持过滤特定邮箱列表',
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
            color: Colors.black.withOpacity(0.05),
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
                    '选择包含邮箱地址的文件',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '支持 CSV 和 TXT 格式，每行一个邮箱地址',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text('选择文件'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.green[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.file_present, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '文件大小: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _totalEmails = 0;
                        _processedEmails = 0;
                        _totalLists = 0;
                        _processedLists = 0;
                        _currentStatus = '';
                        _successLists.clear();
                        _failedLists.clear();
                        _invalidEmails.clear();
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
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
            color: Colors.black.withOpacity(0.05),
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
                '配置选项',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 收件人列表前缀
          TextFormField(
            controller: _prefixController,
            decoration: const InputDecoration(
              labelText: '收件人列表前缀',
              hintText: '例如：收件人列表',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // 收件人别名后缀
          TextFormField(
            controller: _suffixController,
            decoration: const InputDecoration(
              labelText: '收件人别名后缀',
              hintText: '例如：@nexperia.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // 每个列表包含的收件人数量
          TextFormField(
            controller: _countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '每个列表包含的收件人数量',
              hintText: '例如：1000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // 过滤邮件列表
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '排除邮件列表（可选）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FilterEmailsConfigPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('配置默认'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _filterEmailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '每行一个邮箱地址，这些邮箱将被排除不处理',
                  border: OutlineInputBorder(),
                  helperText: '留空则使用默认配置的过滤邮箱',
                ),
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
            color: Colors.black.withOpacity(0.05),
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
                '设置选项',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('合并默认过滤邮箱列表'),
            subtitle: const Text('勾选后将自动合并默认配置的过滤邮箱和本次输入的过滤邮箱'),
            value: _mergeDefaultFilterEmails,
            onChanged: (value) {
              setState(() {
                _mergeDefaultFilterEmails = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          CheckboxListTile(
            title: const Text('邮箱去重'),
            subtitle: const Text('自动去除重复的邮箱地址'),
            value: _removeDuplicates,
            onChanged: (value) {
              setState(() {
                _removeDuplicates = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          CheckboxListTile(
            title: const Text('忽略无效邮箱'),
            subtitle: const Text('跳过格式不正确的邮箱地址'),
            value: _ignoreInvalidEmails,
            onChanged: (value) {
              setState(() {
                _ignoreInvalidEmails = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          CheckboxListTile(
            title: const Text('跳过空邮箱'),
            subtitle: const Text('跳过空行或只包含空格的邮箱'),
            value: _skipEmptyEmails,
            onChanged: (value) {
              setState(() {
                _skipEmptyEmails = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
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
            color: Colors.black.withOpacity(0.05),
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
              Icon(Icons.timeline, color: Colors.blue[600], size: 20),
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
          
          Text(_currentStatus),
          const SizedBox(height: 8),
          
          if (_totalLists > 0) ...[
            LinearProgressIndicator(
              value: _processedLists / _totalLists,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            const SizedBox(height: 8),
            Text('收件人列表: $_processedLists / $_totalLists'),
          ],
          
          if (_totalEmails > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _processedEmails / _totalEmails,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
            const SizedBox(height: 8),
            Text('邮箱地址: $_processedEmails / $_totalEmails'),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedFile == null || _isProcessing ? null : _startProcessing,
        icon: _isProcessing 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.play_arrow, color: Colors.white),
        label: Text(_isProcessing ? '处理中...' : '开始创建'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            color: Colors.black.withOpacity(0.05),
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
                  '成功创建 ${_successLists.length} 个收件人列表',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.bold,
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
                  '失败 ${_failedLists.length} 个收件人列表',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.bold,
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
                  '无效邮箱 ${_invalidEmails.length} 个',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
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

    // 检查阿里云配置
    final edmService = AliyunEdmService();
    if (!await edmService.isConfigured()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先在设置中配置阿里云AccessKey'),
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
    final edmService = AliyunEdmService();
    
    // 从Provider获取现有的收件人列表名称用于重复检查
    setState(() {
      _currentStatus = '正在获取现有收件人列表...';
    });
    
    final provider = context.read<ReceiverListProvider>();
    final existingNames = provider.receiverNames;
    
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
      final batch = emailBatches[i];
      final listName = '${_prefixController.text.trim()}${i + 1}';
      final alias = '${_getCurrentDate()}${(i + 1).toString().padLeft(2, '0')}${_suffixController.text.trim()}';
      
      // 检查名称是否重复
      if (existingNames.contains(listName.toLowerCase().trim())) {
        print('收件人列表名称重复: $listName');
        _failedLists.add('$listName (名称重复)');
        continue;
      }
      
      setState(() {
        _currentStatus = '正在创建收件人列表: $listName (${i + 1}/$_totalLists)';
      });

      try {
        // 创建收件人列表
        final createResponse = await edmService.createReceiver(listName, alias: alias);
        final receiverId = createResponse.receiverId;
        
        // 分批添加收件人（每次最多500个）
        final emailChunks = _chunkEmails(batch, 500);
        for (int j = 0; j < emailChunks.length; j++) {
          final chunk = emailChunks[j];
          setState(() {
            _currentStatus = '正在添加收件人到列表: $listName (${j + 1}/${emailChunks.length})';
          });
          
          // 为每个邮箱创建收件人参数
          final receiverParamsList = chunk.map((email) => 
            ReceiverDetailParams(email: email, fieldValues: {})
          ).toList();
          
          // 批量添加收件人
          await edmService.saveReceiverDetails(receiverId, receiverParamsList);
          
          setState(() {
            _processedEmails += chunk.length;
          });
        }
        
        _successLists.add(listName);
        // 将新创建的名称添加到现有名称集合中，避免后续重复
        existingNames.add(listName.toLowerCase().trim());
      } catch (e) {
        print('创建收件人列表失败: $listName, 错误: $e');
        _failedLists.add(listName);
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
    final chunks = <List<String>>[];
    for (int i = 0; i < emails.length; i += chunkSize) {
      final end = (i + chunkSize < emails.length) ? i + chunkSize : emails.length;
      chunks.add(emails.sublist(i, end));
    }
    return chunks;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }
} 