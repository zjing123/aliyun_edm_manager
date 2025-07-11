import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';
import 'package:aliyun_edm_manager/services/config/config_service.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/models/receiver/receiver_detail.dart';
import 'package:aliyun_edm_manager/services/background_receiver_service.dart';
import 'package:aliyun_edm_manager/pages/receiver/background_processing_page.dart';
import 'package:aliyun_edm_manager/utils/performance_optimizer.dart';


/// 收件人列表冲突处理选项
enum ConflictAction {
  /// 删除现有列表并创建新列表
  deleteAndCreate,
  /// 直接追加到现有列表
  append,
  /// 取消操作
  cancel,
}

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
  
  // 性能优化配置
  int _batchSize = 500; // 修正为500，符合阿里云API限制
  int _maxConcurrent = 3; // 最大并发数
  bool _enablePerformanceMode = true; // 启用性能模式
  
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
                    '• 支持过滤特定邮箱列表\n'
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
            color: Colors.black.withAlpha(13),
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
            color: Colors.black.withAlpha(13),
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
                      // TODO: 暂时注释掉，等待FilterEmailsConfigPage页面完善
                      // final result = await Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => const FilterEmailsConfigPage(),
                      //   ),
                      // );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('过滤邮箱配置功能正在开发中'),
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
            color: Colors.black.withAlpha(13),
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
          
          const Divider(),
          
          // 性能优化配置
          Row(
            children: [
              Icon(Icons.speed, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '性能优化',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          CheckboxListTile(
            title: const Text('启用性能模式'),
            subtitle: const Text('启用并发处理和批量优化，提升处理速度'),
            value: _enablePerformanceMode,
            onChanged: (value) {
              setState(() {
                _enablePerformanceMode = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          if (_enablePerformanceMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('每批处理数量'),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: _batchSize,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [200, 300, 500].map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text('$size 个'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _batchSize = value ?? 1000;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('最大并发数'),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: _maxConcurrent,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [1, 2, 3, 5].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('$count 个'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _maxConcurrent = value ?? 3;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
            color: Colors.black.withAlpha(13),
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
    return Column(
      children: [
        // 前台处理按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _startProcessing(useBackground: false),
            icon: _isProcessing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isProcessing ? '处理中...' : '前台处理'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 后台处理按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _startProcessing(useBackground: true),
            icon: const Icon(Icons.schedule),
            label: const Text('后台处理'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // 性能测试按钮
        const SizedBox(height: 12),

        
        // 说明文字
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '前台处理：在当前页面显示进度，会阻塞界面操作\n'
                  '后台处理：跳转到进度页面，可以继续操作其他界面',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: Colors.black.withAlpha(13),
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        if (mounted) {
          setState(() {
            _selectedFile = result.files.first;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startProcessing({bool useBackground = false}) async {
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
      if (useBackground) {
        // 后台处理
        await _startBackgroundProcessing(count);
      } else {
        // 前台处理
        await _processFile(count);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 处理文件并创建收件人列表
  Future<void> _processFile(int countPerList) async {
    // 检查配置
    if (!_checkConfiguration()) return;
    
    // 初始化服务管理器
    final serviceManager = _initializeServiceManager();
    
    // 解析文件数据
    final emailBatches = await _parseReceiverFile(countPerList);
    if (emailBatches.isEmpty) return;
    
    // 处理收件人列表
    await _handleReceiverList(serviceManager, emailBatches);
    
    if (mounted) {
      setState(() {
        _currentStatus = '处理完成';
      });
    }
  }

  /// 检查阿里云配置
  bool _checkConfiguration() {
    final globalConfig = context.read<GlobalConfigProvider>();
    if (!globalConfig.isConfigured) {
      if (mounted) {
        setState(() {
          _currentStatus = '阿里云AccessKey未配置，请先配置';
        });
      }
      return false;
    }
    return true;
  }

  /// 初始化服务管理器
  AliyunServiceManager _initializeServiceManager() {
    final globalConfig = context.read<GlobalConfigProvider>();
    final serviceManager = AliyunServiceManager();
    serviceManager.initialize(globalConfig);
    return serviceManager;
  }

  /// 解析收件人文件数据
  Future<List<List<String>>> _parseReceiverFile(int countPerList) async {
    final startTime = DateTime.now();
    debugPrint('📁 [批量创建] 开始解析收件人文件 - ${startTime.toIso8601String()}');
    
    if (mounted) {
      setState(() {
        _currentStatus = '正在读取文件...';
      });
    }

    // 读取文件内容
    final fileReadStartTime = DateTime.now();
    List<String> emails = await _readEmailsFromFile();
    final fileReadDuration = DateTime.now().difference(fileReadStartTime);
    debugPrint('📖 [批量创建] 文件读取完成 - 耗时: ${fileReadDuration.inMilliseconds}ms, 原始邮箱数量: ${emails.length}');
    
    if (mounted) {
      setState(() {
        _currentStatus = '正在过滤邮箱...';
      });
    }
    
    // 过滤邮箱
    final filterStartTime = DateTime.now();
    emails = await _filterEmails(emails);
    final filterDuration = DateTime.now().difference(filterStartTime);
    debugPrint('🔍 [批量创建] 邮箱过滤完成 - 耗时: ${filterDuration.inMilliseconds}ms, 过滤后邮箱数量: ${emails.length}');
    
    if (emails.isEmpty) {
      if (mounted) {
        setState(() {
          _currentStatus = '没有有效的邮箱地址';
        });
      }
      debugPrint('⚠️ [批量创建] 过滤后没有有效邮箱地址');
      return [];
    }

    // 拆分邮箱列表
    final splitStartTime = DateTime.now();
    final emailBatches = _splitEmails(emails, countPerList);
    final splitDuration = DateTime.now().difference(splitStartTime);
    debugPrint('✂️ [批量创建] 邮箱列表拆分完成 - 耗时: ${splitDuration.inMilliseconds}ms, 批次数量: ${emailBatches.length}');
    
    if (mounted) {
      setState(() {
        _totalEmails = emails.length;
        _totalLists = emailBatches.length;
        _currentStatus = '开始处理收件人列表...';
      });
    }
    
    final totalDuration = DateTime.now().difference(startTime);
    debugPrint('✅ [批量创建] 文件解析完成 - 总耗时: ${totalDuration.inMilliseconds}ms');
    debugPrint('   📊 解析统计:');
    debugPrint('   - 文件读取: ${fileReadDuration.inMilliseconds}ms');
    debugPrint('   - 邮箱过滤: ${filterDuration.inMilliseconds}ms');
    debugPrint('   - 列表拆分: ${splitDuration.inMilliseconds}ms');
    debugPrint('   - 原始邮箱: ${emails.length} 个');
    debugPrint('   - 有效邮箱: ${emails.length} 个');
    debugPrint('   - 批次数量: ${emailBatches.length} 个');
    debugPrint('   - 每批次大小: $countPerList 个');
    
    return emailBatches;
  }

  /// 处理收件人列表创建和收件人数据写入
  Future<void> _handleReceiverList(AliyunServiceManager serviceManager, List<List<String>> emailBatches) async {
    final receiverService = serviceManager.receiverService;
    final provider = context.read<ReceiverListProvider>();
    final existingNames = provider.receiverNames;
    
    // 查询现有收件人列表
    if (mounted) {
      setState(() {
        _currentStatus = '正在查询现有收件人列表...';
      });
    }
    
    final existingReceivers = await receiverService.queryReceivers();
    
    // 处理每个批次
    for (int i = 0; i < emailBatches.length; i++) {
      final batch = emailBatches[i];
      final listName = '${_prefixController.text.trim()}${i + 1}';
      final alias = '${_getCurrentDate()}${(i + 1).toString().padLeft(2, '0')}${_suffixController.text.trim()}';
      
      if (mounted) {
        setState(() {
          _currentStatus = '正在处理收件人列表: $listName (${i + 1}/$_totalLists)';
        });
      }

      try {
        // 检查收件人列表是否存在
        final existingReceiver = _findExistingReceiver(existingReceivers, listName);
        
        if (existingReceiver == null) {
          // 列表不存在，直接创建
          await _createNewReceiverList(receiverService, listName, alias, batch);
        } else {
          // 列表存在，检查是否有收件人数据
          final hasReceivers = existingReceiver['Count'] > 0;
          
          if (!hasReceivers) {
            // 列表存在但无收件人数据，直接写入
            await _addReceiversToExistingList(receiverService, existingReceiver['ReceiverId'], batch);
          } else {
            // 列表存在且有收件人数据，需要用户选择处理方式
            final action = await _showConflictDialog(listName, existingReceiver['Count']);
            if (action == ConflictAction.cancel) {
              _failedLists.add('$listName (用户取消)');
              continue;
            } else if (action == ConflictAction.deleteAndCreate) {
              await _deleteAndCreateReceiverList(receiverService, listName, alias, batch, existingReceiver['ReceiverId']);
            } else if (action == ConflictAction.append) {
              await _addReceiversToExistingList(receiverService, existingReceiver['ReceiverId'], batch);
            }
          }
        }
        
        _successLists.add(listName);
        // 将新创建的名称添加到现有名称集合中，避免后续重复
        existingNames.add(listName.toLowerCase().trim());
      } catch (e) {
        debugPrint('处理收件人列表失败: $listName, 错误: $e');
        _failedLists.add(listName);
      }
      
      if (mounted) {
        setState(() {
          _processedLists = i + 1;
        });
      }
    }
  }

  /// 查找现有的收件人列表
  Map<String, dynamic>? _findExistingReceiver(List<Map<String, dynamic>> existingReceivers, String listName) {
    try {
      return existingReceivers.firstWhere(
        (receiver) => receiver['ReceiversName'] == listName,
      );
    } catch (e) {
      return null;
    }
  }

  /// 创建新的收件人列表
  Future<void> _createNewReceiverList(
    dynamic receiverService, 
    String listName, 
    String alias, 
    List<String> emails
  ) async {
    if (mounted) {
      setState(() {
        _currentStatus = '正在创建收件人列表: $listName';
      });
    }
    
    final createResponse = await receiverService.createReceiver(listName, alias: alias);
    final receiverId = createResponse.receiverId;
    
    await _addReceiversToExistingList(receiverService, receiverId, emails);
  }

  /// 向现有收件人列表添加收件人
  Future<void> _addReceiversToExistingList(
    dynamic receiverService, 
    String receiverId, 
    List<String> emails
  ) async {
    // 数据预处理（去重、验证）
    final preprocessResult = DataPreprocessor.preprocessData(emails);
    final validEmails = preprocessResult['validEmails'] as List<String>;
    final invalidEmails = preprocessResult['invalidEmails'] as List<String>;
    final duplicateEmails = preprocessResult['duplicateEmails'] as List<String>;
    if (mounted && invalidEmails.isNotEmpty) {
      setState(() {
        _invalidEmails.addAll(invalidEmails);
      });
    }
    if (validEmails.isEmpty) return;

    // 分批处理+性能监控
    int batchCount = 0;
    await MemoryManager.processLargeData(
      validEmails,
      (chunk) async {
        batchCount++;
        
        // 跳过已处理邮箱
        final unprocessedEmails = chunk.where((e) => !CacheManager.isProcessed(e)).toList();
        if (unprocessedEmails.isEmpty) return;
        
        // 添加请求间隔，避免频率限制
        if (batchCount > 1) {
          final interval = Duration(milliseconds: 500 + (batchCount * 100)); // 递增间隔
          debugPrint('⏳ [批量创建] 批次 $batchCount 等待 ${interval.inMilliseconds}ms 后继续...');
          await Future.delayed(interval);
        }
        
        final receiverParamsList = unprocessedEmails.map((email) => ReceiverDetailParams(email: email, fieldValues: {})).toList();
        final startTime = DateTime.now();
        
        try {
          await RetryManager.retryWithSmartStrategy(
            () => receiverService.saveReceiverDetails(receiverId, receiverParamsList),
            operationName: '批量添加收件人',
          );
          final duration = DateTime.now().difference(startTime);
          PerformanceOptimizer.recordResponseTime(duration.inMilliseconds);
          PerformanceOptimizer.recordResult(true);
          
          for (final email in unprocessedEmails) {
            CacheManager.markProcessed(email);
          }
          
          debugPrint('✅ [批量创建] 批次 $batchCount 处理完成 - 成功: ${unprocessedEmails.length} 个');
        } catch (e) {
          final duration = DateTime.now().difference(startTime);
          PerformanceOptimizer.recordResponseTime(duration.inMilliseconds);
          PerformanceOptimizer.recordResult(false, e.toString());
          
          for (final email in unprocessedEmails) {
            CacheManager.markFailed(email);
          }
          
          debugPrint('❌ [批量创建] 批次 $batchCount 处理失败 - 错误: $e');
          rethrow;
        }
        
        if (mounted) {
          setState(() {
            _processedEmails += unprocessedEmails.length;
          });
        }
      },
      chunkSize: PerformanceOptimizer.currentBatchSize,
      operationName: '批量添加收件人',
    );
    
    // 动态调整参数
    PerformanceOptimizer.performDynamicAdjustment();
  }

  /// 删除现有列表并创建新列表
  Future<void> _deleteAndCreateReceiverList(
    dynamic receiverService, 
    String listName, 
    String alias, 
    List<String> emails,
    String existingReceiverId
  ) async {
    if (mounted) {
      setState(() {
        _currentStatus = '正在删除现有收件人列表: $listName';
      });
    }
    
    // 删除现有列表
    await receiverService.deleteReceiver(existingReceiverId);
    
    // 等待删除操作完成（阿里云删除操作需要时间）
    await Future.delayed(Duration(seconds: 2));
    
    // 创建新列表（添加后缀避免重名）
    final newListName = '${listName}_new';
    await _createNewReceiverList(receiverService, newListName, alias, emails);
  }

  /// 显示冲突处理对话框
  Future<ConflictAction> _showConflictDialog(String listName, int existingCount) async {
    return await showDialog<ConflictAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('收件人列表冲突'),
          content: Text(
            '收件人列表 "$listName" 已存在，且包含 $existingCount 个收件人。\n\n'
            '请选择处理方式：',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ConflictAction.cancel),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ConflictAction.deleteAndCreate),
              child: Text('删除现有列表并创建新列表'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ConflictAction.append),
              child: Text('直接追加到现有列表'),
            ),
          ],
        );
      },
    ) ?? ConflictAction.cancel;
  }

  Future<List<String>> _readEmailsFromFile() async {
    if (_selectedFile == null) return [];
    
    final startTime = DateTime.now();
    debugPrint('📖 [批量创建] 开始读取文件: ${_selectedFile!.name} (${(_selectedFile!.size / 1024).toStringAsFixed(1)}KB)');
    
    try {
      final file = File(_selectedFile!.path!);
      final content = await file.readAsString(encoding: utf8);
      final lines = content.split('\n');
      
      final result = lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [批量创建] 文件读取完成 - 耗时: ${duration.inMilliseconds}ms, 读取行数: ${lines.length}, 有效行数: ${result.length}');
      
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [批量创建] 文件读取失败 - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      throw Exception('读取文件失败: $e');
    }
  }

  Future<List<String>> _filterEmails(List<String> emails) async {
    final startTime = DateTime.now();
    debugPrint('🔍 [批量创建] 开始过滤邮箱 - 原始数量: ${emails.length}');
    
    List<String> filteredEmails = List.from(emails);
    
    // 跳过空邮箱
    if (_skipEmptyEmails) {
      final emptyFilterStartTime = DateTime.now();
      final beforeEmptyFilter = filteredEmails.length;
      filteredEmails = filteredEmails.where((email) => email.isNotEmpty).toList();
      final emptyFilterDuration = DateTime.now().difference(emptyFilterStartTime);
      final afterEmptyFilter = filteredEmails.length;
      debugPrint('🚫 [批量创建] 空邮箱过滤 - 耗时: ${emptyFilterDuration.inMilliseconds}ms, 过滤前: $beforeEmptyFilter, 过滤后: $afterEmptyFilter');
    }
    
    // 过滤无效邮箱
    if (_ignoreInvalidEmails) {
      final invalidFilterStartTime = DateTime.now();
      final beforeInvalidFilter = filteredEmails.length;
      final validEmails = <String>[];
      for (final email in filteredEmails) {
        if (_isValidEmail(email)) {
          validEmails.add(email);
        } else {
          _invalidEmails.add(email);
        }
      }
      filteredEmails = validEmails;
      final invalidFilterDuration = DateTime.now().difference(invalidFilterStartTime);
      final afterInvalidFilter = filteredEmails.length;
      debugPrint('❌ [批量创建] 无效邮箱过滤 - 耗时: ${invalidFilterDuration.inMilliseconds}ms, 过滤前: $beforeInvalidFilter, 过滤后: $afterInvalidFilter, 无效邮箱: ${_invalidEmails.length}');
    }
    
    // 邮箱去重
    if (_removeDuplicates) {
      final duplicateFilterStartTime = DateTime.now();
      final beforeDuplicateFilter = filteredEmails.length;
      filteredEmails = filteredEmails.toSet().toList();
      final duplicateFilterDuration = DateTime.now().difference(duplicateFilterStartTime);
      final afterDuplicateFilter = filteredEmails.length;
      final removedDuplicates = beforeDuplicateFilter - afterDuplicateFilter;
      debugPrint('🔄 [批量创建] 邮箱去重 - 耗时: ${duplicateFilterDuration.inMilliseconds}ms, 去重前: $beforeDuplicateFilter, 去重后: $afterDuplicateFilter, 移除重复: $removedDuplicates');
    }
    
    // 合并默认过滤邮箱和页面输入的过滤邮箱（可选）
    Set<String> allFilterEmails = {};
    final pageFilterEmails = _filterEmailsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_mergeDefaultFilterEmails) {
      final configFilterStartTime = DateTime.now();
      final configService = await ConfigService.getInstance();
      final defaultFilterEmails = configService.getFilterEmails();
      allFilterEmails = {...defaultFilterEmails, ...pageFilterEmails};
      final configFilterDuration = DateTime.now().difference(configFilterStartTime);
      debugPrint('⚙️ [批量创建] 配置过滤邮箱加载 - 耗时: ${configFilterDuration.inMilliseconds}ms, 默认过滤: ${defaultFilterEmails.length}, 页面过滤: ${pageFilterEmails.length}, 总过滤: ${allFilterEmails.length}');
    } else {
      allFilterEmails = {...pageFilterEmails};
      debugPrint('📝 [批量创建] 仅使用页面过滤邮箱 - 数量: ${allFilterEmails.length}');
    }
    
    if (allFilterEmails.isNotEmpty) {
      final customFilterStartTime = DateTime.now();
      final beforeCustomFilter = filteredEmails.length;
      debugPrint('🚫 [批量创建] 开始自定义邮箱过滤 - 过滤列表: $allFilterEmails');
      debugPrint('📊 [批量创建] 过滤前邮箱数量: ${filteredEmails.length}');
      final beforeFilter = List<String>.from(filteredEmails);
      filteredEmails = filteredEmails.where((email) => !allFilterEmails.contains(email)).toList();
      final customFilterDuration = DateTime.now().difference(customFilterStartTime);
      final afterCustomFilter = filteredEmails.length;
      final removedByCustomFilter = beforeCustomFilter - afterCustomFilter;
      debugPrint('✅ [批量创建] 自定义邮箱过滤完成 - 耗时: ${customFilterDuration.inMilliseconds}ms, 过滤前: $beforeCustomFilter, 过滤后: $afterCustomFilter, 移除: $removedByCustomFilter');
      debugPrint('📋 [批量创建] 被过滤掉的邮箱: ${beforeFilter.where((email) => allFilterEmails.contains(email)).take(10).join(', ')}${beforeFilter.where((email) => allFilterEmails.contains(email)).length > 10 ? '...' : ''}');
    }
    
    final totalDuration = DateTime.now().difference(startTime);
    debugPrint('✅ [批量创建] 邮箱过滤完成 - 总耗时: ${totalDuration.inMilliseconds}ms');
    debugPrint('   📊 过滤统计:');
    debugPrint('   - 原始邮箱: ${emails.length} 个');
    debugPrint('   - 最终邮箱: ${filteredEmails.length} 个');
    debugPrint('   - 无效邮箱: ${_invalidEmails.length} 个');
    debugPrint('   - 过滤比例: ${((emails.length - filteredEmails.length) / emails.length * 100).toStringAsFixed(2)}%');
    
    return filteredEmails;
  }

  bool _isValidEmail(String email) {
    // 更严格的邮箱验证正则表达式
    // 不允许连续的点号，不允许以点号开头或结尾的本地部分
    final emailRegex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9._%+-]*[a-zA-Z0-9])?@[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$');
    
    // 额外的验证：检查是否包含连续点号
    if (email.contains('..')) {
      return false;
    }
    
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
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
           '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
           '${now.second.toString().padLeft(2, '0')}';
  }



  /// 开始后台处理
  Future<void> _startBackgroundProcessing(int countPerList) async {
    // 解析文件数据
    final emailBatches = await _parseReceiverFile(countPerList);
    if (emailBatches.isEmpty) return;

    // 获取全局配置
    final globalConfig = context.read<GlobalConfigProvider>();
    final provider = context.read<ReceiverListProvider>();
    final existingNames = provider.receiverNames;

    // 跳转到后台处理页面
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackgroundProcessingPage(),
      ),
    );

    // 开始后台处理
    final backgroundService = BackgroundReceiverService.instance;
    await backgroundService.startBackgroundProcessing(
      globalConfig: globalConfig,
      emailBatches: emailBatches,
      prefix: _prefixController.text.trim(),
      suffix: _suffixController.text.trim(),
      existingNames: existingNames.toList(),
      batchSize: _batchSize,
      maxConcurrent: _maxConcurrent,
      enablePerformanceMode: _enablePerformanceMode,
    );
  }


} 