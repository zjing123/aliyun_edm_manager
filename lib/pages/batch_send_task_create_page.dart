import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/batch_send_task_model.dart';
import '../models/receiver_list_model.dart';
import '../models/template_model.dart';
import '../models/sender_address_model.dart';
import '../providers/batch_send_task_provider.dart';
import '../providers/receiver_list_provider.dart';
import '../providers/global_config_provider.dart';
import '../services/aliyun_edm_service.dart';

// 发信地址类型常量
class SenderTypeConstants {
  static const String RANDOM = '0';  // 随机地址
  static const String FIXED = '1';   // 发信地址
  
  static const Map<String, String> TYPE_LABELS = {
    RANDOM: '随机地址',
    FIXED: '发信地址',
  };
  
  static const List<DropdownMenuItem<String>> DROPDOWN_ITEMS = [
    DropdownMenuItem(value: RANDOM, child: Text('随机地址')),
    DropdownMenuItem(value: FIXED, child: Text('发信地址')),
  ];
}

class BatchSendTaskCreatePage extends StatefulWidget {
  const BatchSendTaskCreatePage({super.key});

  @override
  State<BatchSendTaskCreatePage> createState() => _BatchSendTaskCreatePageState();
}

class _BatchSendTaskCreatePageState extends State<BatchSendTaskCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _senderAddressController = TextEditingController();
  final _templateSearchController = TextEditingController();
  final _senderAddressSearchController = TextEditingController();
  final _sendIntervalController = TextEditingController();

  String? _selectedTemplateId;
  String? _selectedTemplateName;
  List<String> _selectedReceiverIds = [];
  Map<String, String> _selectedReceiverNames = {};
  String? _selectedSenderType;
  bool _enableScheduledSend = false;
  DateTime? _startSendTime;
  int? _sendIntervalValue;
  String _sendIntervalUnit = 'minute';

  String? _selectedEmailTag;
  bool _enableTracking = false;
  bool _showReceiverDropdown = false;
  bool _showValidationError = false;

  // 模板数据
  List<TemplateModel> _templates = [];
  List<TemplateModel> _filteredTemplates = [];
  bool _isLoadingTemplates = false;
  String? _templateError;
  bool _templatesLoaded = false;
  bool _showTemplateDropdown = false;

  // 发信地址数据
  String? _selectedSenderAddress;
  List<SenderAddressModel> _senderAddresses = [];
  List<SenderAddressModel> _filteredSenderAddresses = [];
  bool _isLoadingSenderAddresses = false;
  String? _senderAddressError;
  bool _senderAddressesLoaded = false;
  bool _showSenderAddressDropdown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiverListProvider>().loadReceivers();
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _senderAddressController.dispose();
    _templateSearchController.dispose();
    _senderAddressSearchController.dispose();
    _sendIntervalController.dispose();
    super.dispose();
  }

  // 懒加载模板数据
  Future<void> _loadTemplates() async {
    if (_templatesLoaded) return;

    setState(() {
      _isLoadingTemplates = true;
      _templateError = null;
    });

    try {
      final globalConfig = context.read<GlobalConfigProvider>();
      final edmService = AliyunEdmService();
      edmService.setGlobalConfigProvider(globalConfig);

      if (!edmService.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }

      final templates = await edmService.getAllTemplates(pageSize: 100);
      setState(() {
        _templates = templates;
        _filteredTemplates = templates;
        _isLoadingTemplates = false;
        _templatesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _templateError = e.toString();
        _isLoadingTemplates = false;
      });
      print('加载模板失败: $e');
    }
  }

  // 过滤模板
  void _filterTemplates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTemplates = _templates;
      } else {
        _filteredTemplates = _templates
            .where((template) =>
                template.templateName.toLowerCase().contains(query.toLowerCase()) ||
                template.templateSubject.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // 懒加载发信地址数据
  Future<void> _loadSenderAddresses() async {
    if (_senderAddressesLoaded) return;

    setState(() {
      _isLoadingSenderAddresses = true;
      _senderAddressError = null;
    });

    try {
      final globalConfig = context.read<GlobalConfigProvider>();
      final edmService = AliyunEdmService();
      edmService.setGlobalConfigProvider(globalConfig);

      if (!edmService.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }

      final addresses = await edmService.getAvailableSenderAddresses(pageSize: 100);
      setState(() {
        _senderAddresses = addresses;
        _filteredSenderAddresses = addresses;
        _isLoadingSenderAddresses = false;
        _senderAddressesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _senderAddressError = e.toString();
        _isLoadingSenderAddresses = false;
      });
      print('加载发信地址失败: $e');
    }
  }

  // 过滤发信地址
  void _filterSenderAddresses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSenderAddresses = _senderAddresses;
      } else {
        _filteredSenderAddresses = _senderAddresses
            .where((address) =>
                address.mailAddress.toLowerCase().contains(query.toLowerCase()) ||
                address.accountName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('新建批量发送任务'),
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
                child: Column(
                  children: [
                    _buildBasicInfoCard(),
                    const SizedBox(height: 24),
                    _buildTemplateCard(),
                    const SizedBox(height: 24),
                    _buildSenderConfigCard(),
                    const SizedBox(height: 24),
                    _buildScheduledSendCard(),
                    const SizedBox(height: 24),
                    _buildAdvancedSettingsCard(),
                  ],
                ),
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
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
            _buildReceiverListField(),
            const SizedBox(height: 20),
            _buildTaskNameField(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverListField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            children: const [
              TextSpan(
                text: '收件人列表',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Consumer<ReceiverListProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Container(
                height: 56,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReceiverDropdown = !_showReceiverDropdown;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedReceiverIds.isEmpty
                                ? '请选择收件人列表'
                                : '已选择 ${_selectedReceiverIds.length} 个收件人列表',
                            style: TextStyle(
                              color: _selectedReceiverIds.isNotEmpty ? Colors.black : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          _showReceiverDropdown ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showReceiverDropdown)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                '可选择多个收件人列表',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: provider.receivers.length,
                            itemBuilder: (context, index) {
                              final receiver = provider.receivers[index];
                              final isSelected = _selectedReceiverIds.contains(receiver.receiverId);
                              
                              return CheckboxListTile(
                                value: isSelected,
                                                                 onChanged: (bool? value) {
                                   setState(() {
                                     if (value == true) {
                                       _selectedReceiverIds.add(receiver.receiverId);
                                       _selectedReceiverNames[receiver.receiverId] = receiver.receiversName;
                                     } else {
                                       _selectedReceiverIds.remove(receiver.receiverId);
                                       _selectedReceiverNames.remove(receiver.receiverId);
                                     }
                                     // 隐藏验证错误提示
                                     if (_selectedReceiverIds.isNotEmpty) {
                                       _showValidationError = false;
                                     }
                                   });
                                 },
                                title: Text(
                                  receiver.receiversName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.blue[700] : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  '${receiver.count}个收件人',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: Colors.blue[600],
                                checkColor: Colors.white,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectedReceiverIds.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已选择的收件人列表：',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _selectedReceiverIds.map((id) {
                            final name = _selectedReceiverNames[id] ?? '';
                            return Chip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 11),
                              ),
                                                             onDeleted: () {
                                 setState(() {
                                   _selectedReceiverIds.remove(id);
                                   _selectedReceiverNames.remove(id);
                                   // 隐藏验证错误提示
                                   if (_selectedReceiverIds.isNotEmpty) {
                                     _showValidationError = false;
                                   }
                                 });
                               },
                              deleteIcon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.blue[300]!),
                            );
                          }).toList(                          ),
                        ),
                      ],
                    ),
                  ),
               ],
             );
           },
         ),
         // 添加自定义验证提示
         if (_selectedReceiverIds.isEmpty && _showValidationError)
           Container(
             margin: const EdgeInsets.only(top: 8),
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: Colors.red[50],
               borderRadius: BorderRadius.circular(4),
               border: Border.all(color: Colors.red[200]!),
             ),
             child: Row(
               children: [
                 Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                 const SizedBox(width: 8),
                 Text(
                   '请选择至少一个收件人列表',
                   style: TextStyle(
                     color: Colors.red[600],
                     fontSize: 12,
                   ),
                 ),
               ],
             ),
           ),
       ],
     );
   }

  Widget _buildTaskNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            children: const [
              TextSpan(
                text: '任务名称',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _taskNameController,
          decoration: InputDecoration(
            hintText: '请输入任务名称',
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入任务名称';
            }
            if (value.length > 50) {
              return '任务名称不能超过50个字符';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard() {
    return Container(
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
                  child: Icon(Icons.email, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '邮件模板',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTemplateSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            children: const [
              TextSpan(
                text: '选择模板',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _showTemplateDropdown = !_showTemplateDropdown;
            });
            if (!_templatesLoaded && _showTemplateDropdown) {
              _loadTemplates();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedTemplateName ?? '请选择邮件模板',
                    style: TextStyle(
                      color: _selectedTemplateName != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  _showTemplateDropdown ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_showTemplateDropdown) 
          _buildTemplateDropdown(),
      ],
    );
  }

  Widget _buildTemplateDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _templateSearchController,
              decoration: InputDecoration(
                hintText: '搜索模板名称或主题',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: _filterTemplates,
            ),
          ),
          const Divider(height: 1),
          _buildTemplateList(),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    if (_isLoadingTemplates) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_templateError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _templateError!,
              style: TextStyle(
                color: Colors.red[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _templatesLoaded = false;
                _loadTemplates();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredTemplates.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          '未找到匹配的模板',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredTemplates.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final template = _filteredTemplates[index];
          final isSelected = _selectedTemplateId == template.templateId;
          
          return ListTile(
            onTap: () {
              setState(() {
                _selectedTemplateId = template.templateId;
                _selectedTemplateName = template.templateName;
                _showTemplateDropdown = false;
              });
            },
            leading: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.email,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                size: 16,
              ),
            ),
            title: Text(
              template.templateName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue[700] : Colors.black,
              ),
            ),
            subtitle: Text(
              template.templateSubject,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Colors.blue[600],
                    size: 20,
                  )
                : null,
            tileColor: isSelected ? Colors.blue[50] : null,
          );
        },
      ),
    );
  }

  Widget _buildSenderConfigCard() {
    return Container(
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
                  child: Icon(Icons.send, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '发送配置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSenderAddressField(),
            const SizedBox(height: 20),
            _buildSenderTypeField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            children: const [
              TextSpan(
                text: '发信地址',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _showSenderAddressDropdown = !_showSenderAddressDropdown;
            });
            if (!_senderAddressesLoaded && _showSenderAddressDropdown) {
              _loadSenderAddresses();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.alternate_email, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedSenderAddress ?? '请选择发信地址',
                    style: TextStyle(
                      color: _selectedSenderAddress != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  _showSenderAddressDropdown ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_showSenderAddressDropdown) 
          _buildSenderAddressDropdown(),
      ],
    );
  }

  Widget _buildSenderAddressDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _senderAddressSearchController,
              decoration: InputDecoration(
                hintText: '搜索发信地址或账户名',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onChanged: _filterSenderAddresses,
            ),
          ),
          const Divider(height: 1),
          _buildSenderAddressList(),
        ],
      ),
    );
  }

  Widget _buildSenderAddressList() {
    if (_isLoadingSenderAddresses) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_senderAddressError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _senderAddressError!,
              style: TextStyle(
                color: Colors.red[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                _senderAddressesLoaded = false;
                _loadSenderAddresses();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_filteredSenderAddresses.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          '未找到匹配的发信地址',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredSenderAddresses.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[200],
        ),
        itemBuilder: (context, index) {
          final address = _filteredSenderAddresses[index];
          final isSelected = _selectedSenderAddress == address.mailAddress;
          
          return ListTile(
            onTap: () {
              setState(() {
                _selectedSenderAddress = address.mailAddress;
                _showSenderAddressDropdown = false;
                // 更新控制器的值以便表单验证
                _senderAddressController.text = address.mailAddress;
              });
            },
            leading: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.alternate_email,
                color: isSelected ? Colors.blue[600] : Colors.grey[600],
                size: 16,
              ),
            ),
            title: Text(
              address.mailAddress,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue[700] : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '账户: ${address.accountName}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  '类型: ${SenderTypeConstants.TYPE_LABELS[address.sendType] ?? "未知类型"}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Colors.blue[600],
                    size: 20,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildSenderTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
            children: const [
              TextSpan(
                text: '发信地址类型',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '请选择发信地址类型',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _selectedSenderType,
            items: SenderTypeConstants.DROPDOWN_ITEMS,
            onChanged: (value) {
              setState(() {
                _selectedSenderType = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请选择发信地址类型';
              }
              if (!SenderTypeConstants.TYPE_LABELS.containsKey(value)) {
                return '无效的发信地址类型';
              }
              return null;
            },
            dropdownColor: Colors.white,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            iconEnabledColor: Colors.grey[600],
            itemHeight: 48,
            menuMaxHeight: 200,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
    }

  Widget _buildStartTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '开始发送时间',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _startSendTime ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('zh', 'CN'),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue[600]!,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (pickedDate != null) {
              if (!mounted) return;
              
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startSendTime ?? DateTime.now()),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.blue[600]!,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              
              if (pickedTime != null) {
                setState(() {
                  _startSendTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _startSendTime != null
                        ? '${_startSendTime!.year}-${_startSendTime!.month.toString().padLeft(2, '0')}-${_startSendTime!.day.toString().padLeft(2, '0')} ${_startSendTime!.hour.toString().padLeft(2, '0')}:${_startSendTime!.minute.toString().padLeft(2, '0')}'
                        : '请选择开始发送时间',
                    style: TextStyle(
                      color: _startSendTime != null ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendIntervalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '发送间隔',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 输入框
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _sendIntervalController,
                decoration: InputDecoration(
                  hintText: '请输入数值',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入发送间隔';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue <= 0) {
                    return '请输入有效的正整数';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _sendIntervalValue = int.tryParse(value);
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // 单位下拉框
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  value: _sendIntervalUnit,
                  items: const [
                    DropdownMenuItem(value: 'second', child: Text('秒')),
                    DropdownMenuItem(value: 'minute', child: Text('分钟')),
                    DropdownMenuItem(value: 'hour', child: Text('小时')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sendIntervalUnit = value!;
                    });
                  },
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  iconEnabledColor: Colors.grey[600],
                  itemHeight: 48,
                  menuMaxHeight: 200,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        // 显示计算后的总时间
        if (_sendIntervalValue != null && _sendIntervalValue! > 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  '间隔时间：${_getIntervalDisplayText()}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getIntervalDisplayText() {
    if (_sendIntervalValue == null || _sendIntervalValue! <= 0) {
      return '';
    }
    
    final value = _sendIntervalValue!;
    switch (_sendIntervalUnit) {
      case 'second':
        if (value >= 60) {
          final minutes = value ~/ 60;
          final seconds = value % 60;
          return seconds > 0 ? '$minutes分钟$seconds秒' : '$minutes分钟';
        }
        return '$value秒';
      case 'minute':
        if (value >= 60) {
          final hours = value ~/ 60;
          final minutes = value % 60;
          return minutes > 0 ? '$hours小时$minutes分钟' : '$hours小时';
        }
        return '$value分钟';
      case 'hour':
        return '$value小时';
      default:
        return '';
    }
  }

  Widget _buildScheduledSendCard() {
    return Container(
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
                  child: Icon(Icons.schedule, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '定时发送',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildScheduledSendSwitch(),
            if (_enableScheduledSend) ...[
              const SizedBox(height: 20),
              _buildStartTimeField(),
              // 只有选择了多个收件人列表时才显示发送间隔
              if (_selectedReceiverIds.length > 1) ...[
                const SizedBox(height: 20),
                _buildSendIntervalField(),
              ] else if (_selectedReceiverIds.length == 1) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '单个收件人列表无需设置发送间隔',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledSendSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _enableScheduledSend ? Colors.blue[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.schedule,
              color: _enableScheduledSend ? Colors.blue[600] : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启用定时发送',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _enableScheduledSend ? '将在指定时间开始发送邮件' : '立即发送邮件',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enableScheduledSend,
            onChanged: (value) {
              setState(() {
                _enableScheduledSend = value;
                if (!value) {
                  // 关闭定时发送时清空相关字段
                  _startSendTime = null;
                  _sendIntervalValue = null;
                  _sendIntervalController.clear();
                }
              });
            },
            activeColor: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return Container(
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
                  child: Icon(Icons.settings, color: Colors.blue[600], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '高级设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildEmailTagField(),
            const SizedBox(height: 20),
            _buildTrackingSwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTagField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '邮件标签',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: '请选择邮件标签',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _selectedEmailTag,
            items: const [
              DropdownMenuItem(value: 'promotion', child: Text('推广邮件')),
              DropdownMenuItem(value: 'notification', child: Text('通知邮件')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedEmailTag = value;
              });
            },
            dropdownColor: Colors.white,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            iconEnabledColor: Colors.grey[600],
            itemHeight: 48,
            menuMaxHeight: 200,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _enableTracking ? Colors.green[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.track_changes,
              color: _enableTracking ? Colors.green[600] : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '邮件跟踪',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '跟踪邮件的打开、点击等行为',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enableTracking,
            onChanged: (value) {
              setState(() {
                _enableTracking = value;
              });
            },
            activeColor: Colors.green[600],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _createTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                '创建任务',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTask() async {
    // 重置验证错误状态
    setState(() {
      _showValidationError = false;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择邮件模板'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    if (_selectedReceiverIds.isEmpty) {
      setState(() {
        _showValidationError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择收件人列表'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    if (_selectedSenderAddress == null || _selectedSenderAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请选择发信地址'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    try {
      final task = BatchSendTaskModel(
        taskId: DateTime.now().millisecondsSinceEpoch.toString(),
        taskName: _taskNameController.text,
        templateId: _selectedTemplateId!,
        templateName: _selectedTemplateName!,
        receiverLists: _selectedReceiverIds.map((id) => ReceiverListConfig(
          receiverId: id,
          receiverName: _selectedReceiverNames[id] ?? '',
          intervalMinutes: 5,
          emailCount: 0,
        )).toList(),
        senderAddress: _selectedSenderAddress!,
        senderName: '',
        tag: _selectedEmailTag,
        enableTracking: _enableTracking,
        createdAt: DateTime.now(),
      );

      await context.read<BatchSendTaskProvider>().addTask(task);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('任务创建成功'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建任务失败: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }
} 