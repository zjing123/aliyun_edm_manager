import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/services/aliyun/aliyun_service_manager.dart';

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

  int _selectedTemplateType = 1; // 默认选择HTML模板
  int _selectedFromType = 0; // 默认选择0

  bool _isSubmitting = false;

  @override
  void dispose() {
    _templateNameController.dispose();
    _templateSubjectController.dispose();
    _templateNickNameController.dispose();
    _templateTextController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await context.read<TemplateProvider>().createTemplate(
        templateType: _selectedTemplateType,
        templateName: _templateNameController.text.trim(),
        templateSubject: _templateSubjectController.text.trim(),
        templateNickName: _templateNickNameController.text.trim(),
        templateText: _templateTextController.text.trim(),
        fromType: _selectedFromType,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('新建模板'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              const Text(
                '新建邮件模板',
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
                          '创建模板',
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