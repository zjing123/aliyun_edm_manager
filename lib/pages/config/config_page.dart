import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/global_config_provider.dart';
import 'filter_emails_config_page.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _accessKeyIdController = TextEditingController();
  final _accessKeySecretController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscureSecret = true;
  
  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }
  
  @override
  void dispose() {
    _accessKeyIdController.dispose();
    _accessKeySecretController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExistingConfig() async {
    final globalConfig = context.read<GlobalConfigProvider>();
    
    // 等待全局配置初始化完成
    if (!globalConfig.isInitialized) {
      await globalConfig.initialize();
    }
    
    setState(() {
      _accessKeyIdController.text = globalConfig.accessKeyId ?? '';
      _accessKeySecretController.text = globalConfig.accessKeySecret ?? '';
    });
  }
  
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final globalConfig = context.read<GlobalConfigProvider>();
      final success = await globalConfig.saveConfig(
        _accessKeyIdController.text.trim(),
        _accessKeySecretController.text.trim(),
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置保存成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // 返回true表示配置已更新
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置保存失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _clearConfig() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final globalConfig = context.read<GlobalConfigProvider>();
      final success = await globalConfig.clearConfig();
      
      if (success) {
        setState(() {
          _accessKeyIdController.clear();
          _accessKeySecretController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置已清除'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置清除失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('阿里云配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '阿里云AccessKey配置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请输入您的阿里云AccessKey信息以使用EDM服务',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accessKeyIdController,
                        decoration: const InputDecoration(
                          labelText: 'Access Key ID',
                          border: OutlineInputBorder(),
                          helperText: '请输入阿里云Access Key ID',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入Access Key ID';
                          }
                          if (value.trim().length < 10) {
                            return 'Access Key ID长度不能少于10位';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accessKeySecretController,
                        obscureText: _obscureSecret,
                        decoration: InputDecoration(
                          labelText: 'Access Key Secret',
                          border: const OutlineInputBorder(),
                          helperText: '请输入阿里云Access Key Secret',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureSecret ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureSecret = !_obscureSecret;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入Access Key Secret';
                          }
                          if (value.trim().length < 20) {
                            return 'Access Key Secret长度不能少于20位';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 过滤邮箱配置卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '过滤邮箱配置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '配置默认的过滤邮箱列表，在批量创建收件人时自动应用',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FilterEmailsConfigPage(),
                              ),
                            );
                            if (result == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('过滤邮箱配置已更新'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('配置过滤邮箱'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveConfig,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? '保存中...' : '保存配置'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _clearConfig,
                      icon: const Icon(Icons.clear),
                      label: const Text('清除配置'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何获取AccessKey'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. 登录阿里云控制台'),
              SizedBox(height: 8),
              Text('2. 点击右上角头像，选择"AccessKey管理"'),
              SizedBox(height: 8),
              Text('3. 创建AccessKey或查看现有的AccessKey'),
              SizedBox(height: 8),
              Text('4. 复制Access Key ID和Access Key Secret'),
              SizedBox(height: 16),
              Text(
                '注意：请妥善保管您的AccessKey信息，不要泄露给他人。',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}