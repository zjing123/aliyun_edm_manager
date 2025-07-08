import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/models/template/template_model.dart';
import 'package:aliyun_edm_manager/models/template/template_request_response.dart';

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
  final _templateNickNameController = TextEditingController();
  final _templateTextController = TextEditingController();

  int _selectedTemplateType = 1;
  int _selectedFromType = 0;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  DescTemplateResponse? _templateDetail;

  @override
  void initState() {
    super.initState();
    _loadTemplateDetail();
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _templateSubjectController.dispose();
    _templateNickNameController.dispose();
    _templateTextController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplateDetail() async {
    try {
      final templateDetail = await context.read<TemplateProvider>().getTemplateDetail(
        templateId: int.parse(widget.template.templateId),
      );

      if (templateDetail != null) {
        setState(() {
          _templateDetail = templateDetail;
          _templateNameController.text = templateDetail.templateName;
          _templateSubjectController.text = templateDetail.templateSubject;
          _templateNickNameController.text = templateDetail.templateNickName;
          _templateTextController.text = templateDetail.templateText;
          _selectedTemplateType = int.parse(templateDetail.templateType);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '获取模板详情失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
      final success = await context.read<TemplateProvider>().modifyTemplate(
        templateId: int.parse(widget.template.templateId),
        templateName: _templateNameController.text.trim(),
        templateSubject: _templateSubjectController.text.trim(),
        templateNickName: _templateNickNameController.text.trim(),
        templateText: _templateTextController.text.trim(),
        fromType: _selectedFromType,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('编辑模板'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 页面标题
                        const Text(
                          '编辑邮件模板',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // 表单内容
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 模板类型
                              const Text(
                                '模板类型 *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedTemplateType,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('HTML模板')),
                                  DropdownMenuItem(value: 2, child: Text('文本模板')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTemplateType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // 模板名称
                              const Text(
                                '模板名称 *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _templateNameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '请输入模板名称',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入模板名称';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 邮件标题
                              const Text(
                                '邮件标题',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _templateSubjectController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '请输入邮件标题',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 发送人名称
                              const Text(
                                '发送人名称',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _templateNickNameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '请输入发送人名称',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 变量说明
                              const Text(
                                '变量说明',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Text(
                                  '{EAddr}替换收件人邮箱地址；{UserName}替换收件人真实姓名；{NickName}替换收件人昵称；{Gender}替换收件人称呼（先生，女士）；{Birthday}替换收件人生日；{Mobile}替换收件人电话。',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 邮件正文
                              const Text(
                                '邮件正文',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _templateTextController,
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '请输入邮件正文内容，支持HTML格式',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // FromType
                              const Text(
                                '发信类型',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedFromType,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('默认')),
                                  DropdownMenuItem(value: 1, child: Text('类型1')),
                                  DropdownMenuItem(value: 2, child: Text('类型2')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFromType = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 提交按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 