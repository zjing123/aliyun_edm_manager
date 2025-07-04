// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:aliyun_edm_manager/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EDM应用启动测试', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EDMApp());

    // Verify that our app shows the main title
    expect(find.text('邮件推送控制台'), findsOneWidget);
    
    // Verify that the navigation menu is present
    expect(find.text('概览'), findsWidgets);
    expect(find.text('邮件设置'), findsWidgets);
    expect(find.text('发送邮件'), findsWidgets);
    expect(find.text('数据统计'), findsWidgets);
    expect(find.text('系统配置'), findsWidgets);
  });
}
