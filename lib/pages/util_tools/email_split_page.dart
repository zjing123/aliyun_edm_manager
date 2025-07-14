import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:aliyun_edm_manager/theme/app_theme_extension.dart';

class EmailSplitPage extends StatefulWidget {
  const EmailSplitPage({super.key});

  @override
  State<EmailSplitPage> createState() => _EmailSplitPageState();
}

class _EmailSplitPageState extends State<EmailSplitPage> {
  final TextEditingController _inputController = TextEditingController();
  List<String> _result = [];
  bool _isProcessing = false;
  
  // 文件选择
  PlatformFile? _selectedFile;
  
  // 设置选项
  bool _removeDuplicates = true;
  bool _ignoreInvalidEmails = true;
  bool _skipEmptyEmails = true;
  bool _trimWhitespace = true;
  
  // 分隔符设置
  final List<String> _separators = ['逗号', '分号', '空格', '换行', '制表符'];
  final List<String> _separatorValues = [',', ';', ' ', '\n', '\t'];
  int _selectedSeparatorIndex = 0; // 默认选择逗号
  
  // 处理统计
  int _totalEmails = 0;
  int _validEmails = 0;
  int _invalidEmails = 0;
  int _duplicateEmails = 0;

  void _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
        
        // 读取文件内容
        await _readFileContent();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件选择失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _readFileContent() async {
    if (_selectedFile == null) return;
    
    try {
      final file = File(_selectedFile!.path!);
      final content = await file.readAsString();
      setState(() {
        _inputController.text = content;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件读取失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _splitEmails() {
    setState(() {
      _isProcessing = true;
    });

    // 模拟处理时间
    Future.delayed(const Duration(milliseconds: 500), () {
      final input = _inputController.text;
      
      // 构建分隔符正则表达式
      final selectedSeparator = _separatorValues[_selectedSeparatorIndex];
      
      String pattern = '';
      if (selectedSeparator == ' ') {
        pattern = r'\s+';
      } else if (selectedSeparator == '\n') {
        pattern = r'\n+';
      } else if (selectedSeparator == '\t') {
        pattern = r'\t+';
      } else {
        pattern = RegExp.escape(selectedSeparator);
      }
      
      // 分割邮箱
      List<String> emails = input
          .split(RegExp(pattern))
          .map((e) => _trimWhitespace ? e.trim() : e)
          .where((e) => e.isNotEmpty)
          .toList();
      
      // 应用过滤选项
      if (_skipEmptyEmails) {
        emails = emails.where((e) => e.isNotEmpty).toList();
      }
      
      if (_ignoreInvalidEmails) {
        emails = emails.where((e) => _isValidEmail(e)).toList();
      }
      
      if (_removeDuplicates) {
        final uniqueEmails = <String>{};
        final duplicates = <String>[];
        
        for (final email in emails) {
          if (!uniqueEmails.add(email)) {
            duplicates.add(email);
          }
        }
        emails = uniqueEmails.toList();
        _duplicateEmails = duplicates.length;
      }
      
      // 统计结果
      _totalEmails = emails.length;
      _validEmails = emails.where((e) => _isValidEmail(e)).length;
      _invalidEmails = emails.where((e) => !_isValidEmail(e)).length;
      
      setState(() {
        _result = emails;
        _isProcessing = false;
      });
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  void _copyResult() {
    if (_result.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _result.join('\n')));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearInput() {
    setState(() {
      _inputController.clear();
      _result.clear();
      _selectedFile = null;
      _totalEmails = 0;
      _validEmails = 0;
      _invalidEmails = 0;
      _duplicateEmails = 0;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('邮箱分割'),
        backgroundColor: Theme.of(context).extension<AppThemeExtension>()!.appBarBackground,
        foregroundColor: Theme.of(context).extension<AppThemeExtension>()!.appBarForeground,
        elevation: 0,
        titleTextStyle: Theme.of(context).extension<AppThemeExtension>()!.appBarTitleStyle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            const Text(
              '邮箱分割工具',
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
                        '使用说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 支持文件上传和手动输入两种方式\n'
                    '• 可选择多种分隔符进行分割\n'
                    '• 自动去除空白字符和空行\n'
                    '• 支持邮箱格式验证和去重\n'
                    '• 分割结果可一键复制到剪贴板',
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
            
            // 输入区域
            _buildInputSection(),
            const SizedBox(height: 24),
            
            // 分隔符设置
            _buildSeparatorSection(),
            const SizedBox(height: 24),
            
            // 设置选项
            _buildSettingsSection(),
            const SizedBox(height: 24),
            
            // 操作按钮
            _buildActionButtons(),
            const SizedBox(height: 24),
            
            // 处理统计
            if (_result.isNotEmpty) _buildStatisticsSection(),
            
            // 结果展示
            if (_result.isNotEmpty) _buildResultSection(),
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
                    '支持 TXT、CSV 格式，每行一个邮箱地址',
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

  Widget _buildInputSection() {
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
              Icon(Icons.input, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '邮箱列表输入',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _inputController,
            minLines: 6,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '请输入需要分割的邮箱列表\n支持格式：\nemail1@example.com, email2@example.com\nemail3@example.com; email4@example.com\nemail5@example.com email6@example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparatorSection() {
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
                '分隔符设置',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            children: List.generate(_separators.length, (index) {
              final isSelected = _selectedSeparatorIndex == index;
              final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
              return FilterChip(
                label: Text(_separators[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSeparatorIndex = index;
                  });
                },
                backgroundColor: appTheme.filterChipBackground,
                selectedColor: appTheme.filterChipSelected,
                checkmarkColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(appTheme.filterChipRadius),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : appTheme.filterChipBorder,
                  ),
                ),
              );
            }),
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
            title: const Text('去除空白字符'),
            subtitle: const Text('自动去除邮箱前后的空格'),
            value: _trimWhitespace,
            onChanged: (value) {
              setState(() {
                _trimWhitespace = value ?? true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
              Icon(Icons.play_arrow, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '操作',
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
                child: ElevatedButton.icon(
                  onPressed: _inputController.text.trim().isEmpty ? null : _splitEmails,
                  icon: _isProcessing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.content_cut),
                  label: Text(_isProcessing ? '处理中...' : '开始分割'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearInput,
                  icon: const Icon(Icons.clear),
                  label: const Text('清空'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
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
              Icon(Icons.analytics, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '处理统计',
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
                child: _buildStatCard('总邮箱数', _totalEmails.toString(), Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('有效邮箱', _validEmails.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('无效邮箱', _invalidEmails.toString(), Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('重复邮箱', _duplicateEmails.toString(), Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
              Icon(Icons.list_alt, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '分割结果',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '共 ${_result.length} 个邮箱',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyResult,
                  icon: const Icon(Icons.copy),
                  label: const Text('复制全部'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            height: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListView.builder(
              itemCount: _result.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _result[index],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 