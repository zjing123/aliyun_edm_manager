import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_name_selection_provider.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';

class TemplateEditPage extends StatefulWidget {
  final TemplateModel template;

  const TemplateEditPage({super.key, required this.template});

  @override
  State<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends State<TemplateEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _templateSubjectController = TextEditingController();
  final _templateTextController = TextEditingController();
  String? _selectedSenderNameValue;
  final _customSenderNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSenderDropdown = false;
  bool _senderNamesLoaded = false;
  String? _senderNameError;
  String? _dropdownErrorText;
  String? _inputErrorText;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 加载发送人名称数据
    Future.microtask(() {
      if (mounted) {
        final provider = Provider.of<SenderNameSelectionProvider>(context, listen: false);
        provider.loadSenderNames();
      }
    });
    _customSenderNameController.addListener(_validateSenderNameField);
    
    // 加载模板详情
    _loadTemplateDetail();
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _templateSubjectController.dispose();
    _templateTextController.dispose();
    _customSenderNameController.removeListener(_validateSenderNameField);
    _customSenderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplateDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // 先确保发送人名称列表已加载
      await _loadSenderNames();
      
      // 使用DescTemplate API获取模板详情
      final templateDetail = await context.read<TemplateProvider>().getTemplateDetail(
        templateId: int.parse(widget.template.templateId),
      );

      // 打印API返回数据
      print('=== DescTemplate API 返回数据 ===');
      print('RequestId: ${templateDetail?.requestId}');
      print('TemplateName: ${templateDetail?.templateName}');
      print('TemplateSubject: ${templateDetail?.templateSubject}');
      print('TemplateNickName: ${templateDetail?.templateNickName}');
      print('TemplateStatus: ${templateDetail?.templateStatus}');
      print('TemplateType: ${templateDetail?.templateType}');
      print('CreateTime: ${templateDetail?.createTime}');
      print('TemplateText: ${templateDetail?.templateText}');
      print('================================');

      if (templateDetail != null) {
        setState(() {
          _templateNameController.text = templateDetail.templateName;
          _templateSubjectController.text = templateDetail.templateSubject;
          _templateTextController.text = templateDetail.templateText;
          
          // 处理发送人名称
          final senderName = templateDetail.templateNickName;
          if (senderName.isNotEmpty) {
            // 检查是否在发送人名称列表中
            final senderProvider = Provider.of<SenderNameSelectionProvider>(context, listen: false);
            final senderOptions = senderProvider.senderNames;
            
            if (senderOptions.any((e) => e.name == senderName)) {
              // 在列表中，直接选择
              _selectedSenderNameValue = senderName;
            } else {
              // 不在列表中，使用自定义输入
              _selectedSenderNameValue = 'custom';
              _customSenderNameController.text = senderName;
            }
          } else {
            // 如果没有发送人名称，默认选择空值
            _selectedSenderNameValue = '';
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '获取模板详情失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载模板详情失败: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _validateSenderNameField() {
    String? dropdownError;
    String? inputError;
    
    if (_selectedSenderNameValue == null || _selectedSenderNameValue!.isEmpty) {
      dropdownError = '请选择发送人名称';
    } else if (_selectedSenderNameValue == 'custom') {
      final value = _customSenderNameController.text;
      if (value.trim().isEmpty) {
        inputError = '请输入发送人名称';
      } else if (value.trim().length < 1 || value.trim().length > 30) {
        inputError = '长度需为1-30个字符';
      }
    }
    
    setState(() {
      _dropdownErrorText = dropdownError;
      _inputErrorText = inputError;
    });
  }

  Future<void> _loadSenderNames() async {
    if (_senderNamesLoaded) return;
    try {
      final provider = context.read<SenderNameSelectionProvider>();
      if (provider.senderNames.isEmpty) {
        await provider.loadSenderNames();
      }
      setState(() {
        _senderNamesLoaded = true;
        _senderNameError = null;
      });
    } catch (e) {
      print('加载发送人名称失败: $e');
      setState(() {
        _senderNameError = e.toString();
        _senderNamesLoaded = true; // 即使失败也标记为已尝试加载
      });
    }
  }

  Future<void> _submitForm() async {
    _validateSenderNameField();
    if (!_formKey.currentState!.validate() || _dropdownErrorText != null || _inputErrorText != null) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      String senderName;
      if (_selectedSenderNameValue == 'custom') {
        senderName = _customSenderNameController.text.trim();
      } else {
        senderName = _selectedSenderNameValue ?? '';
      }
      
      // 使用ModifyTemplate API修改模板
      final success = await context.read<TemplateProvider>().modifyTemplate(
        templateId: int.parse(widget.template.templateId),
        templateName: _templateNameController.text.trim(),
        templateSubject: _templateSubjectController.text.trim(),
        templateNickName: senderName,
        templateText: _templateTextController.text.trim(),
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板修改成功')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板修改失败')),
          );
        }
      }
    } catch (e) {
      print('修改模板失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildSenderNameField() {
    final senderProvider = context.watch<SenderNameSelectionProvider>();
    final senderOptions = senderProvider.senderNames;
    final hasOptions = senderOptions.isNotEmpty;
    final dropdownItems = [
      DropdownMenuItem<String>(
        value: '',
        child: const Text('请选择...', style: TextStyle(fontSize: 15, color: Colors.grey)),
      ),
      ...senderOptions.map((e) => DropdownMenuItem<String>(
        value: e.name,
        child: Text(e.name, style: const TextStyle(fontSize: 15)),
      )),
      DropdownMenuItem<String>(
        value: 'custom',
        child: Row(
          children: const [
            Icon(Icons.edit, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text('手动输入', style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Text('（自定义）', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    ];
    if (hasOptions && _selectedSenderNameValue != 'custom' && _selectedSenderNameValue != '' && !senderOptions.any((e) => e.name == _selectedSenderNameValue)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedSenderNameValue = '';
        });
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('发送人名称', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Theme(
                data: Theme.of(context).copyWith(
                  highlightColor: Colors.blue[50],
                  splashColor: Colors.blue[50],
                  hoverColor: Colors.blue[50],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedSenderNameValue,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _dropdownErrorText != null ? Colors.red : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _dropdownErrorText != null ? Colors.red : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _dropdownErrorText != null ? Colors.red : Colors.blue, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: dropdownItems,
                  onChanged: hasOptions ? (value) {
                    setState(() {
                      _selectedSenderNameValue = value;
                    });
                    _validateSenderNameField();
                  } : null,
                  validator: (value) => null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '如需自定义发送人名称，请选择"手动输入"并在右侧输入框填写',
              textStyle: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline, 
                size: 18, 
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            if (_selectedSenderNameValue == 'custom')
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _customSenderNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _inputErrorText != null ? Colors.red : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _inputErrorText != null ? Colors.red : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _inputErrorText != null ? Colors.red : Colors.blue, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: '请输入发送人名称',
                  ),
                  validator: (value) => null,
                  onChanged: (value) => _validateSenderNameField(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_dropdownErrorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(_dropdownErrorText!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        if (_inputErrorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(_inputErrorText!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('编辑邮件模板'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTemplateDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.edit, color: Colors.blue[600], size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '编辑模板信息',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // 模板名称
                                  Row(
                                    children: [
                                      Text('模板名称', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                      const Text(' *', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _templateNameController,
                                    decoration: InputDecoration(
                                      hintText: '请输入模板名称',
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
                                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return '请输入模板名称';
                                      }
                                      if (value.trim().length < 1 || value.trim().length > 30) {
                                        return '长度需为1-30个字符';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // 邮件标题
                                  Row(
                                    children: [
                                      Text('邮件标题', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                      const Text(' *', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _templateSubjectController,
                                    decoration: InputDecoration(
                                      hintText: '请输入邮件标题',
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
                                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return '请输入邮件标题';
                                      }
                                      if (value.trim().length < 1 || value.trim().length > 100) {
                                        return '长度需为1-100个字符';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // 发送人名称
                                  _buildSenderNameField(),
                                  const SizedBox(height: 20),
                                  // 邮件正文
                                  Row(
                                    children: [
                                      Text('邮件正文', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                                      const Text(' *', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _templateTextController,
                                    maxLines: 8,
                                    decoration: InputDecoration(
                                      hintText: '请输入邮件正文内容，支持HTML格式',
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
                                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return '请输入邮件正文';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // 变量说明
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: const Text(
                                      '{EAddr}替换收件人邮箱地址；{UserName}替换收件人真实姓名；{NickName}替换收件人昵称；{Gender}替换收件人称呼（先生，女士）；{Birthday}替换收件人生日；{Mobile}替换收件人电话。',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF1976D2)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 底部操作栏
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '取消',
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        '保存修改',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 