import 'package:flutter/material.dart';
import 'pages/main_layout_page.dart';
import 'pages/template_management_page.dart';
import 'pages/receiver_list_page.dart';
import 'pages/send_data_page.dart';
import 'pages/send_details_page.dart';
import 'pages/config_page.dart';

class EDMApp extends StatelessWidget {
  const EDMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阿里云EDM管理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/template-management',
      onGenerateRoute: (settings) {
        Widget page;
        
        switch (settings.name) {
          case '/template-management':
            page = const TemplateManagementPage();
            break;
          case '/receiver-list':
            page = const ReceiverListPage();
            break;
          case '/send-data':
            page = const SendDataPage();
            break;
          case '/send-details':
            page = const SendDetailsPage();
            break;
          case '/config':
            return MaterialPageRoute(
              builder: (context) => const ConfigPage(),
              settings: settings,
            );
          default:
            page = const TemplateManagementPage();
        }

        // 包装在主布局中
        return MaterialPageRoute(
          builder: (context) => MainLayoutPage(
            currentRoute: settings.name ?? '/template-management',
            child: page,
          ),
          settings: settings,
        );
      },
    );
  }
}