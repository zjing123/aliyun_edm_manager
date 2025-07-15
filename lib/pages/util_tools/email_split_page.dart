import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import 'package:aliyun_edm_manager/theme/app_theme_extension.dart';
import 'package:path/path.dart' as path;

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
  
  // 保存目录设置
  String? _saveDirectory;
  final TextEditingController _saveDirectoryController = TextEditingController();
  
  // 处理统计
  int _totalEmails = 0;
  int _validEmails = 0;
  int _invalidEmails = 0;
  int _duplicateEmails = 0;
  List<List<String>> _splitResults = []; // 分割结果
  
  // 进度条相关
  double _progress = 0.0;
  String _progressText = '';
  int _currentBatch = 0;
  int _totalBatches = 0;
  int _processedEmails = 0;
  int _totalEmailsToProcess = 0;

  @override
  void initState() {
    super.initState();
    // 初始化简化规则示例
    _batchSplitRules.addAll([
      BatchSplitRule(startBatch: 1, size: 1000),
      BatchSplitRule(startBatch: 4, size: 1500),
      BatchSplitRule(startBatch: 7, size: 2000),
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

  void _selectSaveDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择保存目录',
      );

      if (selectedDirectory != null) {
        setState(() {
          _saveDirectory = selectedDirectory;
          _saveDirectoryController.text = selectedDirectory;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目录选择失败: $e'),
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
      _progress = 0.0;
      _progressText = '开始处理...';
      _currentBatch = 0;
      _totalBatches = 0;
      _processedEmails = 0;
      _totalEmailsToProcess = 0;
    });

    try {
      // 1. 读取文件内容
      _updateProgress(0.1, '正在读取文件...');
      List<String> emails = await _readEmailsFromFile();

      // 2. 读取排除邮箱
      _updateProgress(0.2, '正在处理排除邮箱...');
      final Set<String> excludeEmails = await _readExcludeEmails();

      // 3. 处理主邮箱列表
      _updateProgress(0.3, '正在处理邮箱列表...');
      if (emails.isNotEmpty) {
        emails = await _processEmails(emails, excludeEmails);
      }

      // 4. 统计结果
      _totalEmails = emails.length;
      _validEmails = emails.where((e) => _isValidEmail(e)).length;
      _invalidEmails = emails.where((e) => !_isValidEmail(e)).length;

      // 5. 执行分割
      _updateProgress(0.5, '正在分割邮箱...');
      List<List<String>> splitResults = [];
      if (_splitMode == 'fixed') {
        // 固定分割大小模式
        final splitSize = int.tryParse(_fixedSplitSizeController.text) ?? 1000;
        splitResults = _splitWithFixedSize(emails, splitSize);
      } else {
        // 自定义分割规则模式
        splitResults = _splitWithCustomRules(emails);
      }

      // 6. 保存分割文件
      _updateProgress(0.7, '正在保存分割文件...');
      await _saveSplitFiles(splitResults);

      _updateProgress(1.0, '处理完成！');

      setState(() {
        _result = emails;
        _splitResults = splitResults;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('邮箱分割完成！共生成 ${splitResults.length} 个文件'),
            backgroundColor: Colors.green,
          ),
        );
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
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _updateProgress(double progress, String text) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _progressText = text;
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
      for (int i = 0; i < _batchSplitRules.length; i++) {
        final r = _batchSplitRules[i];
        final start = r.startBatch;
        final end = r.getEndBatch(_batchSplitRules, i);
        
        if (end != null) {
          // 有明确结束批次的规则
          if (batchNo >= start && batchNo <= end) {
            rule = r;
            break;
          }
        } else {
          // 最后一个规则（到结束）
          if (batchNo >= start) {
            rule = r;
            break;
          }
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
        BatchSplitRule(startBatch: 1, size: 1000),
        BatchSplitRule(startBatch: 4, size: 1500),
        BatchSplitRule(startBatch: 7, size: 2000),
      ]);
      _saveDirectory = null;
      _saveDirectoryController.clear();
      _progress = 0.0;
      _progressText = '';
    });
  }

  Future<void> _saveSplitFiles(List<List<String>> splitResults) async {
    if (_selectedFile == null || splitResults.isEmpty) return;

    try {
      // 确定保存目录
      String saveDir;
      if (_saveDirectory != null && _saveDirectory!.isNotEmpty) {
        saveDir = _saveDirectory!;
      } else {
        // 默认在文件上传目录下新建data目录
        final fileDir = path.dirname(_selectedFile!.path!);
        saveDir = path.join(fileDir, 'data');
      }

      // 创建保存目录
      final directory = Directory(saveDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 获取原始文件名（不含扩展名）
      final originalFileName = path.basenameWithoutExtension(_selectedFile!.name);

      // 保存每个分割批次
      for (int i = 0; i < splitResults.length; i++) {
        final batch = splitResults[i];
        final fileName = '${originalFileName}_${i + 1}.csv';
        final filePath = path.join(saveDir, fileName);

        // 创建CSV内容
        final csvData = [
          ['email'], // 标题行
          ...batch.map((email) => [email]), // 数据行
        ];

        final csvString = const ListToCsvConverter().convert(csvData);
        final file = File(filePath);
        await file.writeAsString(csvString, encoding: utf8);

        // 更新进度
        final batchProgress = 0.7 + (0.3 * (i + 1) / splitResults.length);
        _updateProgress(batchProgress, '正在保存第 ${i + 1}/${splitResults.length} 个文件...');
      }

      debugPrint('✅ [邮箱分割] 文件保存完成 - 保存目录: $saveDir, 文件数量: ${splitResults.length}');
    } catch (e) {
      debugPrint('❌ [邮箱分割] 文件保存失败: $e');
      throw Exception('保存分割文件失败: $e');
    }
  }



  // 自动计算下一个规则的开始批次
  int _calculateNextStartBatch() {
    if (_batchSplitRules.isEmpty) return 1;
    
    // 简化逻辑：返回最后一个规则的起始批次加1
    final lastRule = _batchSplitRules.last;
    return lastRule.startBatch + 1;
  }

  // 获取批次规则的连续性提示（简化版本）
  String? _getBatchContinuityHint(int ruleIndex) {
    if (ruleIndex == 0) return null; // 第一行不需要提示
    
    final previousRule = _batchSplitRules[ruleIndex - 1];
    final currentRule = _batchSplitRules[ruleIndex];
    
    // 检查当前起始批次是否大于上一行的起始批次
    if (currentRule.startBatch <= previousRule.startBatch) {
      return '起始批次必须大于上一行的起始批次';
    }
    
    return null;
  }

  // 更新规则时自动调整后续规则的开始批次（简化级联更新策略）
  void _updateRuleAndAdjustSubsequent(int index, BatchSplitRule newRule) {
    setState(() {
      _batchSplitRules[index] = newRule;
      
      // 验证起始批次的有效性
      if (index > 0) {
        final previousRule = _batchSplitRules[index - 1];
        if (newRule.startBatch <= previousRule.startBatch) {
          // 显示错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('起始批次必须大于上一行的起始批次'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
      
      // 级联更新后续所有规则（如果需要的话）
      // 在新的简化设计中，我们不需要自动调整后续规则的起始批次
      // 用户需要手动设置每个规则的起始批次
    });
  }

  @override
  void dispose() {
    _excludeController.dispose();
    _fixedSplitSizeController.dispose();
    _saveDirectoryController.dispose();
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
            
            // 保存目录设置
            _buildSaveDirectorySection(),
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
            
            // 进度条显示
            if (_isProcessing) _buildProgressSection(),
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
                // 规则列表
                ..._batchSplitRules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final rule = entry.value;
                  final startController = TextEditingController(text: rule.startBatch.toString());
                  final sizeController = TextEditingController(text: rule.size.toString());
                  final continuityHint = _getBatchContinuityHint(index);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 规则输入行
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 规则序号
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 起始批次输入框
                              Expanded(
                                child: TextField(
                                  controller: startController,
                                  keyboardType: TextInputType.number,
                                  enabled: index == 0 ? false : true,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: '起始批次',
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue[400]!),
                                    ),
                                    filled: index == 0,
                                    fillColor: index == 0 ? Colors.grey[100] : Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    hintText: index == 0 ? '1' : '请输入起始批次',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                  ),
                                  onChanged: (value) {
                                    if (index == 0) return;
                                    
                                    final newStart = int.tryParse(value);
                                    if (newStart == null || newStart <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('起始批次必须大于0'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    
                                    final newRule = BatchSplitRule(
                                      startBatch: newStart,
                                      size: rule.size,
                                    );
                                    _updateRuleAndAdjustSubsequent(index, newRule);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 数量输入框
                              Expanded(
                                child: TextField(
                                  controller: sizeController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: '数量',
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue[400]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    hintText: '请输入数量',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                                      size: newSize,
                                    );
                                    _updateRuleAndAdjustSubsequent(index, newRule);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 删除按钮
                              Container(
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.grey[100] : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: index == 0 ? Colors.grey[300]! : Colors.red[200]!),
                                ),
                                child: IconButton(
                                  onPressed: index == 0 ? null : () {
                                    setState(() {
                                      _batchSplitRules.removeAt(index);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: index == 0 ? Colors.grey[400] : Colors.red[600],
                                    size: 20,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 批次范围信息
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '批次范围: ${rule.getDisplayRange(_batchSplitRules, index)} (${rule.size}个)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 连续性提示
                        if (continuityHint != null)
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_outlined, color: Colors.orange[600], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    continuityHint,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                // 添加新规则按钮
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 检查第一行规则是否有效
                      if (_batchSplitRules.isEmpty || _batchSplitRules[0].size <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('请先完善第一行规则（数量必须大于0）'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      final nextStart = _calculateNextStartBatch();
                      setState(() {
                        _batchSplitRules.add(BatchSplitRule(
                          startBatch: nextStart,
                          size: 1000,
                        ));
                      });
                    },
                    icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                    label: const Text(
                      '添加规则',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.blue[200],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

// 简化分割规则类
class BatchSplitRule {
  final int startBatch; // 起始批次
  final int size;       // 分割数量
  
  BatchSplitRule({
    required this.startBatch,
    required this.size,
  });
  
  // 计算结束批次（下一个规则的起始批次减1，如果没有下一个规则则为null）
  int? getEndBatch(List<BatchSplitRule> allRules, int currentIndex) {
    if (currentIndex < allRules.length - 1) {
      return allRules[currentIndex + 1].startBatch - 1;
    }
    return null; // 最后一个规则表示到结束
  }
  
  String getDisplayRange(List<BatchSplitRule> allRules, int currentIndex) {
    final endBatch = getEndBatch(allRules, currentIndex);
    if (endBatch == null) {
      return '$startBatch~结束';
    } else if (startBatch == endBatch) {
      return '$startBatch';
    } else {
      return '$startBatch~$endBatch';
    }
  }
}

  // 保存目录设置UI
  Widget _buildSaveDirectorySection() {
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
              Icon(Icons.folder_open, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                '保存目录设置',
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
                child: TextField(
                  controller: _saveDirectoryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: '请选择保存目录（可选，默认在文件目录下创建data文件夹）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: IconButton(
                      onPressed: _selectSaveDirectory,
                      icon: const Icon(Icons.folder_open),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectSaveDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('选择目录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '如果不选择保存目录，系统将在上传文件所在目录下自动创建data文件夹来保存分割文件',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 进度条UI
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
          
          // 进度条
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            minHeight: 8,
          ),
          
          const SizedBox(height: 12),
          
          // 进度文本
          Text(
            _progressText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 进度百分比
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }