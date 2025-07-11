import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aliyun_edm_manager/app.dart';
import 'package:aliyun_edm_manager/services/di/service_locator.dart';
import 'package:aliyun_edm_manager/providers/config/global_config_provider.dart';
import 'package:aliyun_edm_manager/providers/config/page_config_provider.dart';
import 'package:aliyun_edm_manager/providers/receiver/receiver_list_provider.dart';
import 'package:aliyun_edm_manager/providers/task/scheduled_email_task_provider.dart';
import 'package:aliyun_edm_manager/providers/task/mail_task_provider.dart';
import 'package:aliyun_edm_manager/providers/template/template_provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_address_provider.dart';
import 'package:aliyun_edm_manager/providers/sender/sender_name_provider.dart';
import 'package:aliyun_edm_manager/providers/sender_statistics/sender_statistics_provider.dart';
import 'package:aliyun_edm_manager/providers/tag/tag_provider.dart';
import 'package:aliyun_edm_manager/providers/track/track_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务定位器
  final serviceLocator = ServiceLocator();
  await serviceLocator.initialize();
  
  runApp(MyApp(serviceLocator: serviceLocator));
}

class MyApp extends StatelessWidget {
  final ServiceLocator serviceLocator;
  
  const MyApp({super.key, required this.serviceLocator});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 使用服务定位器提供的Provider实例
        ChangeNotifierProvider.value(value: serviceLocator.globalConfigProvider),
        ChangeNotifierProvider.value(value: serviceLocator.pageConfigProvider),
        ChangeNotifierProvider.value(value: serviceLocator.receiverListProvider),
        ChangeNotifierProvider.value(value: serviceLocator.scheduledEmailTaskProvider),
        ChangeNotifierProvider.value(value: serviceLocator.mailTaskProvider),
        ChangeNotifierProvider.value(value: serviceLocator.templateProvider),
        ChangeNotifierProvider.value(value: serviceLocator.senderAddressProvider),
        ChangeNotifierProvider.value(value: serviceLocator.senderNameProvider),
        ChangeNotifierProvider.value(value: serviceLocator.senderStatisticsProvider),
        ChangeNotifierProvider.value(value: serviceLocator.tagProvider),
        ChangeNotifierProvider.value(value: serviceLocator.trackProvider),
      ],
             child: const EDMApp(),
    );
  }
}