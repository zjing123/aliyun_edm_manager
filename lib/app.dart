import 'package:flutter/material.dart';
import 'pages/receiver_list_page.dart';
import 'pages/invalid_address_page.dart';
import 'pages/statistics_page.dart';
import 'pages/send_email_page.dart';
import 'pages/config_page.dart';

class EDMApp extends StatelessWidget {
  const EDMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阿里云EDM管理',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/receivers',
      routes: {
        '/receivers': (context) => const ReceiverListPage(),
        '/invalid-address': (context) => const InvalidAddressPage(),
        '/statistics': (context) => const StatisticsPage(),
        '/send-email': (context) => const SendEmailPage(),
        '/config': (context) => const ConfigPage(),
      },
    );
  }
}