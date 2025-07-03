import 'package:flutter/material.dart';
import '../services/config_service.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  late final TextEditingController _idController;
  late final TextEditingController _secretController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: ConfigService.accessKeyId ?? '');
    _secretController = TextEditingController(text: ConfigService.accessKeySecret ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = _idController.text.trim();
    final secret = _secretController.text.trim();
    if (id.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AccessKeyId 和 AccessKeySecret 均不能为空')));
      return;
    }
    await ConfigService.setAccessKey(accessKeyId: id, accessKeySecret: secret);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配置 AccessKey')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'AccessKeyId'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _secretController,
              decoration: const InputDecoration(labelText: 'AccessKeySecret'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}