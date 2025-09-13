import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  bool _isEnabled = false;
  bool _isAvailable = false;
  NfcTag? _lastTag;

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isAvailable => _isAvailable;
  NfcTag? get lastTag => _lastTag;

  // 初始化NFC服务
  Future<void> init() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
    } catch (e) {
      _isAvailable = false;
    }
  }

  // 启用NFC会话
  Future<void> startNfcSession(Function(NfcTag) onTagDiscovered) async {
    if (!await NfcManager.instance.isAvailable()) {
      throw Exception('NFC is not available');
    }

    _isEnabled = true;
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        _lastTag = tag;
        onTagDiscovered(tag);
      },
    );
  }

  // 停止NFC会话
  Future<void> stopNfcSession() async {
    _isEnabled = false;
    NfcManager.instance.stopSession();
  }

  // 检查NFC是否可用
  Future<bool> checkAvailability() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }
}