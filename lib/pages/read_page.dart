import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../services/nfc_service.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  final NfcService _nfcService = NfcService();
  String _nfcStatus = '等待NFC标签...';
  Map<String, dynamic>? _tagData;
  List<String> _ndefMessages = [];

  @override
  void initState() {
    super.initState();
    _initNfc();
  }

  _initNfc() async {
    try {
      await _nfcService.init();
      if (_nfcService.isAvailable) {
        setState(() {
          _nfcStatus = 'NFC已就绪，请触碰标签';
        });
        _startNfcSession();
      } else {
        setState(() {
          _nfcStatus = 'NFC不可用';
        });
      }
    } catch (e) {
      setState(() {
        _nfcStatus = 'NFC初始化失败: $e';
      });
    }
  }

  _startNfcSession() {
    _nfcService.startNfcSession((tag) async {
      setState(() {
        // 清除之前的数据
        _ndefMessages.clear();
        _nfcStatus = '读取到标签';
        _tagData = tag.data;
      });

      // 尝试读取NDEF数据
      try {
        final ndef = Ndef.from(tag);
        if (ndef != null) {
          await ndef.read();
          setState(() {
            if (ndef.cachedMessage != null) {
              for (var record in ndef.cachedMessage!.records) {
                String message = '';

                // 解析记录数据
                if (record.payload.isNotEmpty) {
                  try {
                    String payload = String.fromCharCodes(record.payload);
                    message = 'Payload: $payload\n';
                  } catch (e) {
                    message =
                        'Payload: (binary data, ${record.payload.length} bytes)\n';
                  }
                }

                message += 'Type: ${record.typeNameFormat.toString()}\n';
                _ndefMessages.add(message);
              }
              _nfcStatus =
                  '读取到NFC标签，包含${ndef.cachedMessage!.records.length}条记录';
            } else {
              _nfcStatus = '读取到NFC标签（无NDEF消息）';
            }
          });
        } else {
          setState(() {
            _nfcStatus = '读取到NFC标签（不支持NDEF）';
          });
        }
      } catch (e) {
        setState(() {
          _nfcStatus = '读取NDEF数据时出错: $e';
        });
      }
    });
  }

  @override
  void dispose() {
    _nfcService.stopNfcSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.nfc,
            size: 100,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 20),
          const Text(
            'NFC 读取功能',
            style: TextStyle(fontSize: 24),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _nfcStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          if (_tagData != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '标签基本信息:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'ID: ${_tagData?['id'] != null ? _bytesToHex(_tagData?['id']) : 'N/A'}'),
                  Text(
                      'ID类型: ${_tagData?['id'] != null ? _getIdType(_tagData?['id']) : 'N/A'}'),
                  Text('技术类型: ${_tagData?['techTypes']?.join(', ') ?? 'N/A'}'),
                  Text(
                      '数据大小: ${_tagData?['ndef']?['cachedSize'] ?? 'N/A'} bytes'),
                  Text('最大大小: ${_tagData?['ndef']?['maxSize'] ?? 'N/A'} bytes'),
                  const SizedBox(height: 8),
                  const Text(
                    'NDEF信息:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '可写: ${_tagData?['ndef']?['isWritable']?.toString() ?? 'N/A'}'),
                  Text(
                      '格式化能力: ${_tagData?['ndef']?['canMakeReadOnly']?.toString() ?? 'N/A'}'),
                ],
              ),
            ),
          if (_ndefMessages.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NDEF记录:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  for (var message in _ndefMessages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(message),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startNfcSession,
            child: const Text('重新开始NFC读取'),
          ),
        ],
      ),
    );
  }

  String _bytesToHex(List<int>? bytes) {
    if (bytes == null) return 'N/A';
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }

  String _getIdType(List<int>? id) {
    if (id == null) return 'N/A';
    switch (id.length) {
      case 4:
        return 'MIFARE Classic®';
      case 7:
        return 'ISO 14443-4 (7 bytes)';
      case 10:
        return 'ISO 14443-4 (10 bytes)';
      default:
        return 'Unknown (${id.length} bytes)';
    }
  }
}
