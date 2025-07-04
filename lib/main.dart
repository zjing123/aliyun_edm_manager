import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/global_config_provider.dart';
import 'providers/page_config_provider.dart';
import 'providers/receiver_list_provider.dart';
import 'providers/batch_send_task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        
        // 批量发送任务Provider - 依赖全局配置
        ChangeNotifierProxyProvider<GlobalConfigProvider, BatchSendTaskProvider>(
          create: (_) => BatchSendTaskProvider(),
          update: (_, globalConfig, batchSendTask) {
            batchSendTask ??= BatchSendTaskProvider();
            
            // 设置全局配置
            if (globalConfig.isInitialized && globalConfig.configService != null) {
              batchSendTask.setGlobalConfigProvider(globalConfig);
            }
            
            return batchSendTask;
          },
        ),
      ],
      child: const EDMApp(),
    ),
  );
}