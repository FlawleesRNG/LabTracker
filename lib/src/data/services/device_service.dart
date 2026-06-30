part of '../../../main.dart';

abstract final class DeviceService {
  static const String prefsKeyDeviceId = 'labtrackerDeviceId';

  static Future<String> obterOuCriarDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existente = prefs.getString(prefsKeyDeviceId);

    if (existente != null && existente.trim().isNotEmpty) {
      return existente;
    }

    final String novoDeviceId = gerarIdLocal('device');
    await prefs.setString(prefsKeyDeviceId, novoDeviceId);
    return novoDeviceId;
  }

  static Future<void> limparDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKeyDeviceId);
  }
}
