import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_name_selection_provider.dart';

class TemplateCreatePage extends StatefulWidget {
  const TemplateCreatePage({super.key});

  @override
  State<TemplateCreatePage> createState() => _TemplateCreatePageState();
}

class _TemplateCreatePageState extends State<TemplateCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _templateNameController = TextEditingController();
  final _templateSubjectController = TextEditingController();
  final _templateNickNameController = TextEditingController();
  final _templateTextController = TextEditingController();

  String? _selectedSenderNameId;
  bool _isSubmitting = false;
  bool _showSenderDropdown = false;
  bool _senderNamesLoaded = false;
  String? _senderNameError;

  @override
  void dispose() {
    _templateNameController.dispose();
    _templateSubjectController.dispose();
    _templateNickNameController.dispose();
    _templateTextController.dispose();
    super.dispose();
  }

  Future<void> _loadSenderNames() async {
    if (_senderNamesLoaded) return;
    try {
      await context.read<SenderNameSelectionProvider>().loadSenderNames();
      setState(() {
        _senderNamesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _senderNameError = e.toString();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final senderName = _templateNickNameController.text.trim();
      final success = await context.read<TemplateProvider>().createTemplate(
        templateType: 1, // 默认HTML
        templateName: _templateNameController.text.trim(),
        templateSubject: _templateSubjectController.text.trim(),
        templateNickName: senderName,
        templateText: _templateTextController.text.trim(),
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板创建成功')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板创建失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
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
        if (senderProvider.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (!senderProvider.isLoading && !senderOptions.isEmpty)
          GestureDetector(
            onTap: () async {
              await _loadSenderNames();
              setState(() {
                _showSenderDropdown = !_showSenderDropdown;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSenderNameId == null
                        ? (_templateNickNameController.text.isNotEmpty ? _templateNickNameController.text : '请选择或输入发送人名称')
                        : senderOptions.firstWhere((e) => e.id == _selectedSenderNameId).name,
                      style: TextStyle(
                        color: _selectedSenderNameId != null || _templateNickNameController.text.isNotEmpty ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                  ),
                  Icon(_showSenderDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        if (_showSenderDropdown && !senderOptions.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: senderOptions.length,
              itemBuilder: (context, index) {
                final sender = senderOptions[index];
                return ListTile(
                  title: Text(sender.name),
                  onTap: () {
                    setState(() {
                      _selectedSenderNameId = sender.id;
                      _templateNickNameController.text = sender.name;
                      _showSenderDropdown = false;
                    });
                  },
                );
              },
            ),
          ),
        if (!senderProvider.isLoading && senderOptions.isEmpty)
          TextFormField(
            controller: _templateNickNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '请输入发送人名称',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入发送人名称';
              }
              if (value.trim().length < 1 || value.trim().length > 30) {
                return '长度需为1-30个字符';
              }
              return null;
            },
          ),
        if (_senderNameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_senderNameError!, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('新建邮件模板'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
      body: Form(
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
                              child: Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '基本信息',
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        : const Text('创建模板', style: TextStyle(fontSize: 15)),
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