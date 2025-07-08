import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/config/global_config_provider.dart';
import 'providers/config/page_config_provider.dart';
import 'providers/receiver/receiver_list_provider.dart';
import 'providers/task/scheduled_email_task_provider.dart';
import 'providers/task/mail_task_provider.dart';
import 'providers/template/template_provider.dart';
import 'providers/sender/sender_address_provider.dart';
import 'services/aliyun/aliyun_service_manager.dart';
import 'utils/time_formatter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化时间格式化工具
  TimeFormatter.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        // 全局配置Provider - 应用启动时初始化
        ChangeNotifierProvider(create: (_) => GlobalConfigProvider()),
        
        // 页面配置Provider - 依赖全局配置
        ChangeNotifierProxyProvider<GlobalConfigProvider, PageConfigProvider>(
          create: (_) => PageConfigProvider(),
          update: (_, globalConfig, pageConfig) {
            pageConfig ??= PageConfigProvider();
            // 当全局配置初始化完成后，初始化页面配置
            if (globalConfig.isInitialized && globalConfig.configService != null) {
              pageConfig.initialize(globalConfig.configService!);
            }
            return pageConfig;
          },
        ),
        
        // 收件人列表Provider - 依赖全局配置和页面配置
        ChangeNotifierProxyProvider2<GlobalConfigProvider, PageConfigProvider, ReceiverListProvider>(
          create: (_) => ReceiverListProvider(),
          update: (_, globalConfig, pageConfig, receiverList) {
            receiverList ??= ReceiverListProvider();
            
            // 设置依赖关系
            receiverList.setDependencies(globalConfig, pageConfig);
            
            return receiverList;
          },
        ),
        
        // 定时发送邮件Provider - 依赖全局配置
        ChangeNotifierProxyProvider<GlobalConfigProvider, ScheduledEmailTaskProvider>(
          create: (context) {
            final serviceManager = AliyunServiceManager();
            return ScheduledEmailTaskProvider(serviceManager, context.read<GlobalConfigProvider>());
          },
          update: (_, globalConfig, batchSendTask) {
            if (batchSendTask == null) {
              final serviceManager = AliyunServiceManager();
              batchSendTask = ScheduledEmailTaskProvider(serviceManager, globalConfig);
            }
            
            // 设置全局配置
            if (globalConfig.isInitialized && globalConfig.configService != null) {
              batchSendTask.setGlobalConfigProvider(globalConfig);
            }
            
            return batchSendTask;
          },
        ),
        
        // 邮件任务Provider - 依赖全局配置
        ChangeNotifierProxyProvider<GlobalConfigProvider, MailTaskProvider>(
          create: (context) {
            final serviceManager = AliyunServiceManager();
            return MailTaskProvider(serviceManager);
          },
          update: (_, globalConfig, mailTask) {
            if (mailTask == null) {
              final serviceManager = AliyunServiceManager();
              mailTask = MailTaskProvider(serviceManager);
            }
            
            // 设置全局配置
            if (globalConfig.isInitialized) {
              mailTask.setGlobalConfigProvider(globalConfig);
            }
            
            return mailTask;
          },
        ),
        
        // 模板管理Provider - 依赖全局配置
        ChangeNotifierProxyProvider<GlobalConfigProvider, TemplateProvider>(
          create: (context) {
            final serviceManager = AliyunServiceManager();
            return TemplateProvider(serviceManager);
          },
          update: (_, globalConfig, templateProvider) {
            if (templateProvider == null) {
              final serviceManager = AliyunServiceManager();
              templateProvider = TemplateProvider(serviceManager);
            }
            
            // 设置全局配置
            if (globalConfig.isInitialized) {
              templateProvider.setGlobalConfigProvider(globalConfig);
            }
            
            return templateProvider;
          },
        ),
        
        // 发信地址Provider - 依赖全局配置
        ChangeNotifierProxyProvider<GlobalConfigProvider, SenderAddressProvider>(
          create: (context) {
            final serviceManager = AliyunServiceManager();
            return SenderAddressProvider(serviceManager);
          },
          update: (_, globalConfig, senderAddressProvider) {
            if (senderAddressProvider == null) {
              final serviceManager = AliyunServiceManager();
              senderAddressProvider = SenderAddressProvider(serviceManager);
            }
            
            // 设置全局配置
            if (globalConfig.isInitialized) {
              senderAddressProvider.setGlobalConfigProvider(globalConfig);
            }
            
            return senderAddressProvider;
          },
        ),
      ],
      child: const EDMApp(),
    ),
  );
}