import 'package:flutter_test/flutter_test.dart';
import 'package:aliyun_edm_manager/services/background_receiver_service.dart';

void main() {
  group('BackgroundReceiverService 测试', () {
    test('单例模式应该正常工作', () {
      final instance1 = BackgroundReceiverService.instance;
      final instance2 = BackgroundReceiverService.instance;
      expect(instance1, same(instance2));
    });

    test('初始状态应该是未处理', () {
      final service = BackgroundReceiverService.instance;
      expect(service.isProcessing, false);
    });

    test('停止处理应该正常工作', () {
      final service = BackgroundReceiverService.instance;
      service.stopProcessing();
      expect(service.isProcessing, false);
    });
  });
} 