import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/config/global_config_provider.dart';
import 'widgets/main_layout.dart';
import 'theme/app_theme_extension.dart';

class EDMApp extends StatefulWidget {
  const EDMApp({super.key});

  @override
  State<EDMApp> createState() => _EDMAppState();
}

class _EDMAppState extends State<EDMApp> {
  @override
  void initState() {
    super.initState();
    // 在应用启动时初始化全局配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalConfig = context.read<GlobalConfigProvider>();
      globalConfig.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阿里云EDM管理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white, // 统一背景色
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 统一圆角
          ),
          // 可根据需要添加titleTextStyle, contentTextStyle等
        ),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(AppThemeExtension.light.elevatedButtonBackground),
            foregroundColor: MaterialStatePropertyAll(AppThemeExtension.light.elevatedButtonForeground),
            iconColor: MaterialStatePropertyAll(AppThemeExtension.light.elevatedButtonIconColor),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppThemeExtension.light.elevatedButtonRadius)),
              ),
            ),
            textStyle: const MaterialStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          AppThemeExtension.light,
        ],
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'CN'),
      home: const MainLayout(),
    );
  }
}