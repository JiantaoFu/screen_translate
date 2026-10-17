import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/app_flavor.dart';

void main() {
  tearDown(() => AppFlavorConfig.debugSet(AppFlavor.paid));

  test('default (no dart-define) is paid', () {
    expect(AppFlavorConfig.dartDefine, 'paid');
    expect(AppFlavorConfig.parse(null), AppFlavor.paid);
    expect(AppFlavorConfig.parse('lite'), AppFlavor.lite);
    expect(AppFlavorConfig.parse(' LITE '), AppFlavor.lite);
  });

  test('either the dart-define or the APK flavor saying lite makes it lite', () {
    expect(AppFlavorConfig.combine(dartDefine: 'paid', native: 'paid'), AppFlavor.paid);
    expect(AppFlavorConfig.combine(dartDefine: 'paid', native: null), AppFlavor.paid);
    expect(AppFlavorConfig.combine(dartDefine: 'paid', native: 'lite'), AppFlavor.lite);
    expect(AppFlavorConfig.combine(dartDefine: 'lite', native: 'paid'), AppFlavor.lite);
  });

  test('resolve reads the native flavor and survives a missing channel', () async {
    await AppFlavorConfig.resolve(nativeFlavor: () async => 'lite');
    expect(AppFlavorConfig.isLite, isTrue);
    await AppFlavorConfig.resolve(nativeFlavor: () async => throw Exception('no channel'));
    expect(AppFlavorConfig.current, AppFlavor.paid);
  });
}
