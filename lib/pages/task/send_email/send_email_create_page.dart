import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mail_task_model.dart';
import '../models/template_model.dart';
import '../models/sender_address_model.dart';
import '../models/email_tag_model.dart';
import '../providers/mail_task_provider.dart';
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

class SendEmailCreatePage extends StatefulWidget {
  const SendEmailCreatePage({super.key});

  @override
  State<SendEmailCreatePage> createState() => _SendEmailCreatePageState();
}

class _SendEmailCreatePageState extends State<SendEmailCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _replyToController = TextEditingController();
  final _templateSearchController = TextEditingController();
  final _senderAddressSearchController = TextEditingController();

  String? _selectedReceiver;
  String? _selectedTemplate;
  String? _selectedSender;
  String? _selectedAddressType;
  String? _selectedTagName;
  bool _enableClickTrace = false;
  bool _showValidationError = false;

  // 收件人列表数据
  List<String> _receiverNames = [];
  bool _isLoadingReceivers = false;
  String? _receiverError;

  // 模板数据
  List<TemplateModel> _templates = [];
  List<TemplateModel> _filteredTemplates = [];
  bool _isLoadingTemplates = false;
  String? _templateError;
  bool _templatesLoaded = false;
  bool _showTemplateDropdown = false;

  // 发信地址数据
  List<SenderAddressModel> _senderAddresses = [];
  List<SenderAddressModel> _filteredSenderAddresses = [];
  bool _isLoadingSenderAddresses = false;
  String? _senderAddressError;
  bool _senderAddressesLoaded = false;
  bool _showSenderAddressDropdown = false;

  // 邮件标签数据
  List<EmailTagModel> _emailTags = [];
  List<EmailTagModel> _filteredEmailTags = [];
  bool _isLoadingEmailTags = false;
  String? _emailTagError;
  bool _emailTagsLoaded = false;
  bool _showEmailTagDropdown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceivers();
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _replyToController.dispose();
    _templateSearchController.dispose();
    _senderAddressSearchController.dispose();
    super.dispose();
  }

  // 加载收件人列表
  Future<void> _loadReceivers() async {
    setState(() {
      _isLoadingReceivers = true;
      _receiverError = null;
    });

    try {
      final receiverProvider = context.read<ReceiverListProvider>();
      await receiverProvider.loadReceivers();
      setState(() {
        _receiverNames = receiverProvider.receivers.map((r) => r.receiversName).toList();
        _isLoadingReceivers = false;
      });
    } catch (e) {
      setState(() {
        _receiverError = e.toString();
        _isLoadingReceivers = false;
      });
      print('加载收件人列表失败: $e');
    }
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

  // 懒加载邮件标签数据
  Future<void> _loadEmailTags() async {
    if (_emailTagsLoaded) return;

    setState(() {
      _isLoadingEmailTags = true;
      _emailTagError = null;
    });

    try {
      final globalConfig = context.read<GlobalConfigProvider>();
      final edmService = AliyunEdmService();
      edmService.setGlobalConfigProvider(globalConfig);

      if (!edmService.isConfigured()) {
        throw Exception('阿里云AccessKey未配置，请先配置');
      }

      final emailTags = await edmService.getAllEmailTags(pageSize: 100);
      setState(() {
        _emailTags = emailTags;
        _filteredEmailTags = emailTags;
        _isLoadingEmailTags = false;
        _emailTagsLoaded = true;
      });
    } catch (e) {
      setState(() {
        _emailTagError = e.toString();
        _isLoadingEmailTags = false;
      });
      print('加载邮件标签失败: $e');
    }
  }

  // 过滤邮件标签
  void _filterEmailTags(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmailTags = _emailTags;
      } else {
        _filteredEmailTags = _emailTags
            .where((tag) =>
                tag.tagName.toLowerCase().contains(query.toLowerCase()) ||
                (tag.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  // 获取选中的邮件标签名称
  String? _getSelectedEmailTagName() {
    if (_selectedTagName == null) return null;
    final selectedTag = _emailTags.firstWhere(
      (tag) => tag.tagId == _selectedTagName,
      orElse: () => EmailTagModel(
        tagId: _selectedTagName!,
        tagName: _selectedTagName!,
        createTime: '',
      ),
    );
    return selectedTag.tagName;
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
        title: const Text('新建邮件发送'),
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
            _buildTaskNameField(),
            const SizedBox(height: 20),
            _buildReceiverListField(),
            const SizedBox(height: 20),
            _buildTemplateSelector(),
            const SizedBox(height: 20),
            _buildSenderAddressField(),
            const SizedBox(height: 20),
            _buildSenderTypeField(),
            const SizedBox(height: 20),
            _buildEmailTagField(),
          ],
        ),
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
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.tune, color: Colors.orange[600], size: 20),
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
            _buildReplyToField(),
            const SizedBox(height: 20),
            _buildClickTraceSwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '任务名称',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _taskNameController,
          decoration: InputDecoration(
            hintText: '请输入任务名称（可选）',
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
        ),
      ],
    );
  }

  Widget _buildReceiverListField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '收件人列表',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedReceiver,
          decoration: InputDecoration(
            hintText: '请选择收件人列表',
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
          items: _receiverNames.map((name) {
            return DropdownMenuItem(
              value: name,
              child: Text(name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedReceiver = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请选择收件人列表';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '邮件模板',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _loadTemplates();
            setState(() {
              _showTemplateDropdown = !_showTemplateDropdown;
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
                    _selectedTemplate ?? '请选择邮件模板',
                    style: TextStyle(
                      color: _selectedTemplate != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(
                  _showTemplateDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_showTemplateDropdown) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _templateSearchController,
                    onChanged: _filterTemplates,
                    decoration: InputDecoration(
                      hintText: '搜索模板...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _isLoadingTemplates
                      ? const Center(child: CircularProgressIndicator())
                      : _templateError != null
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '加载失败: $_templateError',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredTemplates.length,
                              itemBuilder: (context, index) {
                                final template = _filteredTemplates[index];
                                return ListTile(
                                  title: Text(template.templateName),
                                  subtitle: Text(template.templateSubject),
                                  onTap: () {
                                    setState(() {
                                      _selectedTemplate = template.templateName;
                                      _showTemplateDropdown = false;
                                      _templateSearchController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
        if (_showValidationError && _selectedTemplate == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '请选择邮件模板',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSenderAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '发信地址',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _loadSenderAddresses();
            setState(() {
              _showSenderAddressDropdown = !_showSenderAddressDropdown;
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
                    _selectedSender ?? '请选择发信地址',
                    style: TextStyle(
                      color: _selectedSender != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(
                  _showSenderAddressDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_showSenderAddressDropdown) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _senderAddressSearchController,
                    onChanged: _filterSenderAddresses,
                    decoration: InputDecoration(
                      hintText: '搜索发信地址...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _isLoadingSenderAddresses
                      ? const Center(child: CircularProgressIndicator())
                      : _senderAddressError != null
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '加载失败: $_senderAddressError',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredSenderAddresses.length,
                              itemBuilder: (context, index) {
                                final address = _filteredSenderAddresses[index];
                                return ListTile(
                                  title: Text(address.accountName),
                                  subtitle: Text(address.mailAddress),
                                  onTap: () {
                                    setState(() {
                                      _selectedSender = address.accountName;
                                      _showSenderAddressDropdown = false;
                                      _senderAddressSearchController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
        if (_showValidationError && _selectedSender == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '请选择发信地址',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSenderTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '发信类型',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedAddressType,
          decoration: InputDecoration(
            hintText: '请选择发信类型',
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
          items: SenderTypeConstants.DROPDOWN_ITEMS,
          onChanged: (value) {
            setState(() {
              _selectedAddressType = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请选择发信类型';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailTagField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '邮件标签',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _loadEmailTags();
            setState(() {
              _showEmailTagDropdown = !_showEmailTagDropdown;
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
                    _getSelectedEmailTagName() ?? '请选择邮件标签（可选）',
                    style: TextStyle(
                      color: _getSelectedEmailTagName() != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(
                  _showEmailTagDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (_showEmailTagDropdown) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: _filterEmailTags,
                    decoration: InputDecoration(
                      hintText: '搜索邮件标签...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _isLoadingEmailTags
                      ? const Center(child: CircularProgressIndicator())
                      : _emailTagError != null
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '加载失败: $_emailTagError',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredEmailTags.length,
                              itemBuilder: (context, index) {
                                final tag = _filteredEmailTags[index];
                                return ListTile(
                                  title: Text(tag.tagName),
                                  subtitle: tag.description != null ? Text(tag.description!) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedTagName = tag.tagId;
                                      _showEmailTagDropdown = false;
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReplyToField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '回复地址',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _replyToController,
          decoration: InputDecoration(
            hintText: '请输入回复地址（可选）',
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
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                return '请输入有效的邮件地址';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildClickTraceSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '启用点击追踪',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '追踪邮件的点击和打开情况',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enableClickTrace,
            onChanged: (value) {
              setState(() {
                _enableClickTrace = value;
              });
            },
            activeColor: Colors.blue,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              '发送邮件',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _showValidationError = true;
      });
      return;
    }
    
    if (_selectedReceiver == null || _selectedTemplate == null || 
        _selectedSender == null || _selectedAddressType == null) {
      setState(() {
        _showValidationError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请完整填写所有必填字段'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final request = BatchSendMailRequest(
        receiversName: _selectedReceiver!,
        templateName: _selectedTemplate!,
        accountName: _selectedSender!,
        clickTrace: _enableClickTrace ? '1' : '0',
        addressType: _selectedAddressType!,
        tagName: _selectedTagName ?? '',
        replyToAddress: _replyToController.text,
        taskName: _taskNameController.text.isNotEmpty ? _taskNameController.text : null,
      );
      
      final provider = context.read<MailTaskProvider>();
      final success = await provider.sendMail(request);
      
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('邮件发送成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('邮件发送失败: ${provider.error ?? '未知错误'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('邮件发送失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 