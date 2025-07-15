import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import 'package:aliyun_edm_manager/theme/app_theme_extension.dart';

class EmailSplitPage extends StatefulWidget {
  const EmailSplitPage({super.key});

  @override
  State<EmailSplitPage> createState() => _EmailSplitPageState();
}

class _EmailSplitPageState extends State<EmailSplitPage> {
  final TextEditingController _excludeController = TextEditingController();
  List<String> _result = [];
  bool _isProcessing = false;
  
  // 文件选择
  PlatformFile? _selectedFile;
  
  // 文件分析结果
  String? _fileType; // 'txt', 'csv', 'excel'
  List<String>? _fileColumns; // CSV/Excel文件的列名
  int? _fileColumnCount; // 文件列数
  int _selectedEmailColumnIndex = 0; // 选择的邮箱列索引
  
  // 设置选项
  bool _removeDuplicates = true;
  bool _ignoreInvalidEmails = true;
  bool _skipEmptyEmails = true;
  bool _trimWhitespace = true;
  
  // 分隔符设置
  final List<String> _separators = ['逗号', '分号', '空格', '换行', '制表符'];
  final List<String> _separatorValues = [',', ';', ' ', '\n', '\t'];
  int _selectedSeparatorIndex = 0; // 默认选择逗号
  
  // 分割大小设置
  String _splitMode = 'fixed'; // 'fixed' 或 'custom'
  final TextEditingController _fixedSplitSizeController = TextEditingController(text: '1000');
  // 自定义分割规则
  final List<BatchSplitRule> _batchSplitRules = [];
  
  // 处理统计
  int _totalEmails = 0;
  int _validEmails = 0;
  int _invalidEmails = 0;
  int _duplicateEmails = 0;
  List<List<String>> _splitResults = []; // 分割结果

  @override
  void initState() {
    super.initState();
    // 初始化区间规则示例，第一行起始批次默认为1
    _batchSplitRules.addAll([
      BatchSplitRule(startBatch: 1, endBatch: 2, size: 1000),
      BatchSplitRule(startBatch: 3, endBatch: 3, size: 1500),
      BatchSplitRule(startBatch: 4, endBatch: 7, size: 2000),
      BatchSplitRule(startBatch: 8, endBatch: null, size: 3000), // 留空表示到结束
    ]);
  }

  void _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;
        setState(() {
          _selectedFile = file;
          // 重置文件分析结果
          _fileType = null;
          _fileColumns = null;
          _fileColumnCount = null;
          _selectedEmailColumnIndex = 0;
        });
        
        // 分析文件类型和结构
        await _analyzeFile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件选择失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeFile() async {
    if (_selectedFile == null) return;
    
    try {
      final fileName = _selectedFile!.name.toLowerCase();
      String fileType;
      
      // 确定文件类型
      if (fileName.endsWith('.txt')) {
        fileType = 'txt';
      } else if (fileName.endsWith('.csv')) {
        fileType = 'csv';
      } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        fileType = 'excel';
      } else {
        fileType = 'txt'; // 默认按txt处理
      }
      
      List<String>? columns;
      int? columnCount;
      
      if (fileType == 'csv') {
        // 分析CSV文件结构
        final analysis = await _analyzeCsvFile();
        columns = analysis['columns'];
        columnCount = analysis['columnCount'];
      } else if (fileType == 'excel') {
        // 分析Excel文件结构（这里简化处理，实际需要excel库）
        final analysis = await _analyzeExcelFile();
        columns = analysis['columns'];
        columnCount = analysis['columnCount'];
      } else {
        // TXT文件按行处理，不需要列选择
        columns = null;
        columnCount = null;
      }
      
      setState(() {
        _fileType = fileType;
        _fileColumns = columns;
        _fileColumnCount = columnCount;
        _selectedEmailColumnIndex = 0; // 默认选择第一列
      });
      
      debugPrint('📊 [邮箱分割] 文件分析完成 - 类型: $fileType, 列数: $columnCount, 列名: $columns');
      
          } catch (e) {
        debugPrint('❌ [邮箱分割] 文件分析失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('文件分析失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
  }

  Future<Map<String, dynamic>> _analyzeCsvFile() async {
    if (_selectedFile == null) throw Exception('未选择文件');
    
    final file = File(_selectedFile!.path!);
    final content = await file.readAsString(encoding: utf8);
    
    // 解析CSV内容
    final csvTable = const CsvToListConverter().convert(content);
    
    if (csvTable.isEmpty) {
      throw Exception('CSV文件为空');
    }
    
    // 获取第一行作为列名
    final firstRow = csvTable.first;
    final columns = firstRow.map((cell) => cell.toString()).toList();
    final columnCount = columns.length;
    
    return {
      'columns': columns,
      'columnCount': columnCount,
    };
  }

  Future<Map<String, dynamic>> _analyzeExcelFile() async {
    // 这里简化处理，实际需要添加excel库
    // 暂时返回模拟数据
    return {
      'columns': ['邮箱', '姓名', '公司', '备注'],
      'columnCount': 4,
    };
  }

  void _splitEmails() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. 读取文件内容
      List<String> emails = await _readEmailsFromFile();

      // 2. 读取排除邮箱
      final Set<String> excludeEmails = await _readExcludeEmails();

      // 3. 处理主邮箱列表
      if (emails.isNotEmpty) {
        emails = await _processEmails(emails, excludeEmails);
      }

      // 4. 统计结果
      _totalEmails = emails.length;
      _validEmails = emails.where((e) => _isValidEmail(e)).length;
      _invalidEmails = emails.where((e) => !_isValidEmail(e)).length;

      // 5. 执行分割
      List<List<String>> splitResults = [];
      if (_splitMode == 'fixed') {
        // 固定分割大小模式
        final splitSize = int.tryParse(_fixedSplitSizeController.text) ?? 1000;
        splitResults = _splitWithFixedSize(emails, splitSize);
      } else {
        // 自定义分割规则模式
        splitResults = _splitWithCustomRules(emails);
      }

      setState(() {
        _result = emails;
        _splitResults = splitResults;
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  List<List<String>> _splitWithFixedSize(List<String> emails, int splitSize) {
    List<List<String>> results = [];
    
    for (int i = 0; i < emails.length; i += splitSize) {
      final end = (i + splitSize < emails.length) ? i + splitSize : emails.length;
      results.add(emails.sublist(i, end));
    }
    
    return results;
  }

  List<List<String>> _splitWithCustomRules(List<String> emails) {
    List<List<String>> results = [];
    int currentIndex = 0;
    int batchNo = 1;
    
    while (currentIndex < emails.length) {
      // 找到当前批次适用的规则
      BatchSplitRule? rule;
      for (final r in _batchSplitRules) {
        final start = r.startBatch;
        final end = r.endBatch ?? 999999; // 留空表示到结束
        if (batchNo >= start && batchNo <= end) {
          rule = r;
          break;
        }
      }
      
      // 没有规则则默认每批1000
      final size = rule?.size ?? 1000;
      final endIdx = (currentIndex + size < emails.length) ? currentIndex + size : emails.length;
      results.add(emails.sublist(currentIndex, endIdx));
      currentIndex = endIdx;
      batchNo++;
    }
    
    return results;
  }

  Future<List<String>> _processEmails(List<String> emails, Set<String> excludeEmails) async {
    final startTime = DateTime.now();
    debugPrint('🔄 [邮箱分割] 开始处理邮箱 - 原始数量: ${emails.length}');
    
    // 创建过滤器链
    final filters = <EmailFilter>[
      if (_skipEmptyEmails) EmptyEmailFilter(),
      if (_ignoreInvalidEmails) InvalidEmailFilter(),
      if (_removeDuplicates) DuplicateEmailFilter(),
      ExcludeEmailFilter(excludeEmails),
      // 在这里可以轻松添加更多过滤器
      // 例如：DomainFilter(['gmail.com', 'yahoo.com']),
      // 例如：CaseInsensitiveFilter(),
      // 例如：EmailFormatFilter(),
    ];
    
    // 依次应用过滤器
    List<String> processedEmails = List.from(emails);
    for (final filter in filters) {
      final filterStartTime = DateTime.now();
      final beforeCount = processedEmails.length;
      
      processedEmails = await filter.apply(processedEmails);
      
      final filterDuration = DateTime.now().difference(filterStartTime);
      final afterCount = processedEmails.length;
      final removedCount = beforeCount - afterCount;
      
      debugPrint('✅ [邮箱分割] ${filter.name} - 耗时: ${filterDuration.inMilliseconds}ms, 处理前: $beforeCount, 处理后: $afterCount, 移除: $removedCount');
    }
    
    final totalDuration = DateTime.now().difference(startTime);
    debugPrint('✅ [邮箱分割] 邮箱处理完成 - 总耗时: ${totalDuration.inMilliseconds}ms, 最终数量: ${processedEmails.length}');
    
    return processedEmails;
  }

  Future<List<String>> _readEmailsFromFile() async {
    if (_selectedFile == null) return [];
    
    final startTime = DateTime.now();
    debugPrint('📖 [邮箱分割] 开始读取文件: ${_selectedFile!.name} (${(_selectedFile!.size / 1024).toStringAsFixed(1)}KB)');
    
    try {
      List<String> emails = [];
      
      if (_fileType == 'csv') {
        emails = await _readEmailsFromCsv();
      } else if (_fileType == 'excel') {
        emails = await _readEmailsFromExcel();
      } else {
        // TXT文件按行处理
        emails = await _readEmailsFromTxt();
      }
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [邮箱分割] 文件读取完成 - 耗时: ${duration.inMilliseconds}ms, 读取邮箱数量: ${emails.length}');
      
      return emails;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [邮箱分割] 文件读取失败 - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      throw Exception('读取文件失败: $e');
    }
  }

  Future<List<String>> _readEmailsFromTxt() async {
    final file = File(_selectedFile!.path!);
    final content = await file.readAsString(encoding: utf8);
    final lines = content.split('\n');
    
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<List<String>> _readEmailsFromCsv() async {
    final file = File(_selectedFile!.path!);
    final content = await file.readAsString(encoding: utf8);
    
    // 解析CSV内容
    final csvTable = const CsvToListConverter().convert(content);
    
    if (csvTable.isEmpty) {
      throw Exception('CSV文件为空');
    }
    
    // 跳过标题行，从指定列读取邮箱
    final emails = <String>[];
    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.length > _selectedEmailColumnIndex) {
        final email = row[_selectedEmailColumnIndex].toString().trim();
        if (email.isNotEmpty) {
          emails.add(email);
        }
      }
    }
    
    return emails;
  }

  Future<List<String>> _readEmailsFromExcel() async {
    // 这里简化处理，实际需要添加excel库
    // 暂时返回模拟数据
    return [
      'test1@example.com',
      'test2@example.com',
      'test3@example.com',
    ];
  }

  Future<Set<String>> _readExcludeEmails() async {
    final startTime = DateTime.now();
    debugPrint('📖 [邮箱分割] 开始读取排除邮箱');
    
    try {
      final excludeInput = _excludeController.text;
      if (excludeInput.trim().isEmpty) {
        debugPrint('✅ [邮箱分割] 排除邮箱为空，跳过处理');
        return <String>{};
      }
      
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
      
      // 分割排除邮箱
      final excludeEmails = excludeInput
          .split(RegExp(pattern))
          .map((e) => _trimWhitespace ? e.trim() : e)
          .where((e) => e.isNotEmpty)
          .toSet();
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('✅ [邮箱分割] 排除邮箱读取完成 - 耗时: ${duration.inMilliseconds}ms, 排除邮箱数量: ${excludeEmails.length}');
      
      return excludeEmails;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [邮箱分割] 排除邮箱读取失败 - 耗时: ${duration.inMilliseconds}ms, 错误: $e');
      throw Exception('读取排除邮箱失败: $e');
    }
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
      _excludeController.clear();
      _result.clear();
      _splitResults.clear();
      _selectedFile = null;
      _fileType = null;
      _fileColumns = null;
      _fileColumnCount = null;
      _selectedEmailColumnIndex = 0;
      _totalEmails = 0;
      _validEmails = 0;
      _invalidEmails = 0;
      _duplicateEmails = 0;
      _splitMode = 'fixed';
      _fixedSplitSizeController.text = '1000';
      _batchSplitRules.clear();
      _batchSplitRules.addAll([
        BatchSplitRule(startBatch: 1, endBatch: 2, size: 1000),
        BatchSplitRule(startBatch: 3, endBatch: 3, size: 1500),
        BatchSplitRule(startBatch: 4, endBatch: 7, size: 2000),
        BatchSplitRule(startBatch: 8, endBatch: null, size: 3000), // 留空表示到结束
      ]);
    });
  }

  // 验证第一行规则是否有效
  bool _validateFirstRule() {
    if (_batchSplitRules.isEmpty) return false;
    
    final firstRule = _batchSplitRules.first;
    
    // 验证开始批次
    if (firstRule.startBatch <= 0) return false;
    
    // 验证数量
    if (firstRule.size <= 0) return false;
    
    // 验证结束批次（如果有的话）
    if (firstRule.endBatch != null) {
      if (firstRule.endBatch! <= 0) return false;
      if (firstRule.endBatch! < firstRule.startBatch) return false;
    }
    
    return true;
  }

  // 自动计算下一个规则的开始批次
  int _calculateNextStartBatch() {
    if (_batchSplitRules.isEmpty) return 1;
    
    final lastRule = _batchSplitRules.last;
    if (lastRule.endBatch == null) {
      // 如果最后一个规则留空（表示到结束），则不能再添加新规则
      return -1;
    }
    return lastRule.endBatch! + 1;
  }

  // 获取批次规则的连续性提示
  String? _getBatchContinuityHint(int ruleIndex) {
    if (ruleIndex == 0) return null; // 第一行不需要提示
    
    final previousRule = _batchSplitRules[ruleIndex - 1];
    final currentRule = _batchSplitRules[ruleIndex];
    
    if (previousRule.endBatch != null) {
      final expectedStart = previousRule.endBatch! + 1;
      if (currentRule.startBatch != expectedStart) {
        return '起始批次应该是 $expectedStart';
      }
    }
    
    return null;
  }

  // 更新规则时自动调整后续规则的开始批次（级联更新策略）
  void _updateRuleAndAdjustSubsequent(int index, BatchSplitRule newRule) {
    setState(() {
      _batchSplitRules[index] = newRule;
      
      // 级联更新后续所有规则
      for (int i = index + 1; i < _batchSplitRules.length; i++) {
        final previousRule = _batchSplitRules[i - 1];
        final currentRule = _batchSplitRules[i];
        
        // 计算新的起始批次
        int? newStart;
        if (previousRule.endBatch != null) {
          newStart = previousRule.endBatch! + 1;
        }
        
        // 如果前一个规则有明确的结束批次，则更新当前规则的起始批次
        if (newStart != null) {
          // 智能调整结束批次：如果当前结束批次小于新的起始批次，则设为null（到结束）
          int? newEnd = currentRule.endBatch;
          if (newEnd != null && newEnd < newStart) {
            newEnd = null; // 设为"到结束"
          }
          
          _batchSplitRules[i] = BatchSplitRule(
            startBatch: newStart,
            endBatch: newEnd,
            size: currentRule.size,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _excludeController.dispose();
    _fixedSplitSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('邮箱分割工具'),
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
            
            // 文件选择和分隔符设置
            _buildFileAndSeparatorSection(),
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
            
            // 分割设置
            _buildSplitSettingsSection(),
            const SizedBox(height: 24),
            
            // 操作按钮
            _buildActionButtons(),
            const SizedBox(height: 24),
            
            // 处理统计
            if (_result.isNotEmpty) _buildStatisticsSection(),
            
            // 结果展示
            if (_result.isNotEmpty) _buildResultSection(),
            
            // 分割结果展示
            if (_splitResults.isNotEmpty) _buildSplitResultSection(),
          ],
        ),
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
                '排除邮箱输入',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _excludeController,
            minLines: 6,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '请输入需要排除的邮箱，多个请用分隔符分开\n支持格式：\nemail1@example.com, email2@example.com\nemail3@example.com; email4@example.com\nemail5@example.com email6@example.com',
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
            runSpacing: 8,
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
          
          _buildSettingItem(
            title: '跳过空邮箱',
            subtitle: '忽略文件中的空行',
            value: _skipEmptyEmails,
            onChanged: (value) {
              setState(() {
                _skipEmptyEmails = value;
              });
            },
          ),
          
          _buildSettingItem(
            title: '忽略无效邮箱',
            subtitle: '过滤掉格式不正确的邮箱地址',
            value: _ignoreInvalidEmails,
            onChanged: (value) {
              setState(() {
                _ignoreInvalidEmails = value;
              });
            },
          ),
          
          _buildSettingItem(
            title: '去除重复邮箱',
            subtitle: '自动去除重复的邮箱地址',
            value: _removeDuplicates,
            onChanged: (value) {
              setState(() {
                _removeDuplicates = value;
              });
            },
          ),
          
          _buildSettingItem(
            title: '去除空白字符',
            subtitle: '自动去除邮箱前后的空格',
            value: _trimWhitespace,
            onChanged: (value) {
              setState(() {
                _trimWhitespace = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue[600],
            activeTrackColor: Colors.blue[200],
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
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
                  onPressed: _excludeController.text.trim().isEmpty ? null : _splitEmails,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildFileAndSeparatorSection() {
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
          // 文件选择部分
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
                    '支持 TXT、CSV、Excel 格式',
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
                        if (_fileType != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '文件类型: ${_fileType!.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _fileType = null;
                        _fileColumns = null;
                        _fileColumnCount = null;
                        _selectedEmailColumnIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
          
          // 邮箱列选择（仅当文件为CSV或Excel且有多列时显示）
          if (_selectedFile != null && 
              (_fileType == 'csv' || _fileType == 'excel') && 
              _fileColumnCount != null && 
              _fileColumnCount! > 1) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  '邮箱列选择',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '检测到文件包含 $_fileColumnCount 列，请选择包含邮箱地址的列：',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_fileColumnCount!, (index) {
                final isSelected = _selectedEmailColumnIndex == index;
                final columnName = _fileColumns != null && index < _fileColumns!.length 
                    ? _fileColumns![index] 
                    : '列 ${index + 1}';
                final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
                return FilterChip(
                  label: Text(columnName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedEmailColumnIndex = index;
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
        ],
            ),
    );
  }

  Widget _buildSplitSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scatter_plot, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '分割设置',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 分割模式选择
          Row(
            children: [
              const Text('分割模式:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'fixed',
                      groupValue: _splitMode,
                      onChanged: (value) {
                        setState(() {
                          _splitMode = value!;
                        });
                      },
                    ),
                    const Text('固定大小'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'custom',
                      groupValue: _splitMode,
                      onChanged: (value) {
                        setState(() {
                          _splitMode = value!;
                        });
                      },
                    ),
                    const Text('自定义规则'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 固定分割大小设置
          if (_splitMode == 'fixed') ...[
            Row(
              children: [
                const Text('分割大小:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _fixedSplitSizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '请输入分割大小（如：1000）',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // 自定义分割规则设置
          if (_splitMode == 'custom') ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '自定义分割规则（批次区间+数量）：',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(child: Text('起始批次', style: TextStyle(fontSize: 12, color: Colors.grey))),
                    SizedBox(width: 8),
                    Expanded(child: Text('结束批次', style: TextStyle(fontSize: 12, color: Colors.grey))),
                    SizedBox(width: 8),
                    Expanded(child: Text('数量', style: TextStyle(fontSize: 12, color: Colors.grey))),
                    SizedBox(width: 8),
                    SizedBox(width: 32),
                  ],
                ),
                ..._batchSplitRules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final rule = entry.value;
                  final startController = TextEditingController(text: rule.startBatch.toString());
                  final endController = TextEditingController(text: rule.endBatch == null ? '' : rule.endBatch.toString());
                  final sizeController = TextEditingController(text: rule.size.toString());
                  final continuityHint = _getBatchContinuityHint(index);
                  
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: startController,
                                keyboardType: TextInputType.number,
                                enabled: false, // 起始批次全部禁用
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                onChanged: (value) {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: endController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  hintText: '留空表示到结束',
                                ),
                                onChanged: (value) {
                                  int? newEnd;
                                  if (value.trim().isEmpty) {
                                    newEnd = null; // 留空表示到结束
                                  } else {
                                    newEnd = int.tryParse(value);
                                  }
                                  // 实时验证结束批次
                                  if (newEnd != null) {
                                    if (newEnd <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('结束批次必须大于0'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    if (newEnd < rule.startBatch) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('结束批次不能小于开始批次'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  final newRule = BatchSplitRule(
                                    startBatch: rule.startBatch,
                                    endBatch: newEnd,
                                    size: rule.size,
                                  );
                                  _updateRuleAndAdjustSubsequent(index, newRule);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: sizeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onChanged: (value) {
                                  final newSize = int.tryParse(value) ?? rule.size;
                                  if (newSize <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('数量必须大于0'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  final newRule = BatchSplitRule(
                                    startBatch: rule.startBatch,
                                    endBatch: rule.endBatch,
                                    size: newSize,
                                  );
                                  _updateRuleAndAdjustSubsequent(index, newRule);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _batchSplitRules.removeAt(index);
                                });
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                      // 显示连续性提示
                      if (continuityHint != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange[600], size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    continuityHint,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                // 添加新规则按钮
                TextButton.icon(
                  onPressed: () {
                    // 检查第一行规则是否有效
                    if (!_validateFirstRule()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请先完善第一行规则（开始批次、结束批次、数量都必须有效）'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final nextStart = _calculateNextStartBatch();
                    if (nextStart == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('当前规则已设置为留空（到结束），不能再添加新规则'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _batchSplitRules.add(BatchSplitRule(
                        startBatch: nextStart,
                        endBatch: null,
                        size: 1000,
                      ));
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加规则'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitResultSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scatter_plot, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '分割结果 (${_splitResults.length}个批次)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 分割批次列表
          ..._splitResults.asMap().entries.map((entry) {
            final index = entry.key;
            final batch = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '批次 ${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${batch.length}个邮箱',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: batch.join('\n')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已复制批次 ${index + 1} 到剪贴板'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: '复制此批次',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      child: Text(
                        batch.take(10).join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  if (batch.length > 10) ...[
                    const SizedBox(height: 4),
                    Text(
                      '... 还有 ${batch.length - 10} 个邮箱',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          
          // 复制所有批次按钮
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final allBatches = _splitResults.map((batch) => batch.join('\n')).join('\n\n--- 批次分割线 ---\n\n');
                    Clipboard.setData(ClipboardData(text: allBatches));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制所有批次到剪贴板'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all, size: 16),
                  label: const Text('复制所有批次'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 邮箱过滤器抽象类
abstract class EmailFilter {
  String get name;
  Future<List<String>> apply(List<String> emails);
}

// 空邮箱过滤器
class EmptyEmailFilter extends EmailFilter {
  @override
  String get name => '空邮箱过滤';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.where((email) => email.isNotEmpty).toList();
  }
}

// 无效邮箱过滤器
class InvalidEmailFilter extends EmailFilter {
  @override
  String get name => '无效邮箱过滤';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.where((email) => _isValidEmail(email)).toList();
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

// 重复邮箱过滤器
class DuplicateEmailFilter extends EmailFilter {
  @override
  String get name => '重复邮箱过滤';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.toSet().toList();
  }
}

// 排除邮箱过滤器
class ExcludeEmailFilter extends EmailFilter {
  final Set<String> excludeEmails;
  
  ExcludeEmailFilter(this.excludeEmails);
  
  @override
  String get name => '排除邮箱过滤';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.where((email) => !excludeEmails.contains(email)).toList();
  }
}

// 示例：如何添加新的过滤器
// 域名过滤器（示例）
class DomainFilter extends EmailFilter {
  final List<String> allowedDomains;
  
  DomainFilter(this.allowedDomains);
  
  @override
  String get name => '域名过滤';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.where((email) {
      final domain = email.split('@').last;
      return allowedDomains.contains(domain);
    }).toList();
  }
}

// 大小写不敏感过滤器（示例）
class CaseInsensitiveFilter extends EmailFilter {
  @override
  String get name => '大小写标准化';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.map((email) => email.toLowerCase()).toList();
  }
}

// 邮箱格式过滤器（示例）
class EmailFormatFilter extends EmailFilter {
  @override
  String get name => '邮箱格式标准化';
  
  @override
  Future<List<String>> apply(List<String> emails) async {
    return emails.map((email) {
      // 去除前后空格，转换为小写等
      return email.trim().toLowerCase();
    }).toList();
  }
}

// 区间分割规则类
class BatchSplitRule {
  final int startBatch;
  final int? endBatch; // null 表示到结束
  final int size;
  
  BatchSplitRule({
    required this.startBatch,
    this.endBatch,
    required this.size,
  });
  
  String get displayRange => endBatch == null
      ? '$startBatch~'
      : (startBatch == endBatch ? '$startBatch' : '$startBatch~$endBatch');
}