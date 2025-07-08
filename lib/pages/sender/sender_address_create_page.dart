import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_address_provider.dart';

class SenderAddressCreatePage extends StatefulWidget {
  const SenderAddressCreatePage({super.key});

  @override
  State<SenderAddressCreatePage> createState() => _SenderAddressCreatePageState();
}

class _SenderAddressCreatePageState extends State<SenderAddressCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _replyAddressController = TextEditingController();
  String _selectedSendType = 'batch';
  bool _isLoading = false;

  @override
  void dispose() {
    _accountNameController.dispose();
    _replyAddressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<SenderAddressProvider>().createAddress(
        accountName: _accountNameController.text.trim(),
        replyAddress: _replyAddressController.text.trim().isEmpty 
            ? null 
            : _replyAddressController.text.trim(),
        sendType: _selectedSendType,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('发信地址创建成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('发信地址创建失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('新建发信地址'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 页面标题
              const Text(
                '新建发信地址',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '创建新的发信地址，用于发送邮件',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 发信邮箱地址
                      _buildFormField(
                        label: '发信邮箱地址',
                        hint: '请输入发信邮箱地址，如：service@example.com',
                        controller: _accountNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入发信邮箱地址';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                              .hasMatch(value.trim())) {
                            return '请输入有效的邮箱地址';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      
                      // 回信地址
                      _buildFormField(
                        label: '回信地址（可选）',
                        hint: '请输入回信地址，留空则使用发信地址',
                        controller: _replyAddressController,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value.trim())) {
                              return '请输入有效的邮箱地址';
                            }
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      
                      // 发信类型
                      _buildSendTypeSelector(),
                      const SizedBox(height: 32),
                      
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
                                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '说明',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• 发信邮箱地址：用于发送邮件的邮箱地址，需要先在阿里云控制台完成域名验证',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• 回信地址：接收退信和回信的邮箱地址，如不填写则使用发信地址',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• 发信类型：批量邮件用于营销邮件，触发邮件用于系统通知',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 操作按钮
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('创建'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
              borderSide: BorderSide(color: Colors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSendTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '发信类型',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.send, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text('批量邮件'),
                  ],
                ),
                subtitle: Text(
                  '用于营销邮件，支持大量发送',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: 'batch',
                groupValue: _selectedSendType,
                onChanged: (value) {
                  setState(() {
                    _selectedSendType = value!;
                  });
                },
                activeColor: Colors.blue,
              ),
              Divider(height: 1, color: Colors.grey[300]),
              RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text('触发邮件'),
                  ],
                ),
                subtitle: Text(
                  '用于系统通知，需要单独申请',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: 'trigger',
                groupValue: _selectedSendType,
                onChanged: (value) {
                  setState(() {
                    _selectedSendType = value!;
                  });
                },
                activeColor: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }
}