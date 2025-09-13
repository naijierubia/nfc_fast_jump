import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class OtherPage extends StatefulWidget {
  const OtherPage({super.key});

  @override
  State<OtherPage> createState() => _OtherPageState();
}

class _OtherPageState extends State<OtherPage> {
  String _status = '就绪';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.more,
            size: 100,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 20),
          const Text(
            '其他功能',
            style: TextStyle(fontSize: 24),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '在此页面可以访问其他NFC相关功能',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NFC格式化工具',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _formatNfcTag,
                    child: Text(_isProcessing ? '等待标签...' : '格式化NFC标签为NDEF'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '警告: 此操作将擦除标签上的所有数据并将其格式化为NDEF格式',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _formatNfcTag() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认格式化'),
          content: const Text('您确定要格式化此NFC标签吗？此操作将擦除标签上的所有数据。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('确认'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        setState(() {
          _isProcessing = true;
          _status = '请将NFC标签靠近设备...';
        });

        await NfcManager.instance.startSession(
          onDiscovered: (NfcTag tag) async {
            try {
              // 检查标签是否支持格式化
              final ndef = Ndef.from(tag);
              if (ndef == null) {
                setState(() {
                  _status = '标签不支持NDEF格式';
                  _isProcessing = false;
                });
                await NfcManager.instance.stopSession();
                return;
              }

              // 尝试格式化标签
              await ndef.write(NdefMessage([])); // 写入空消息以格式化标签
              
              setState(() {
                _status = '标签格式化成功';
              });
            } catch (e) {
              setState(() {
                _status = '格式化过程中发生错误: $e';
              });
            } finally {
              _isProcessing = false;
              await NfcManager.instance.stopSession();
            }
          },
          onError: (e) {
            setState(() {
              _status = 'NFC会话错误: $e';
              _isProcessing = false;
            });
            return Future<void>.value();
          },
        );
      } catch (e) {
        setState(() {
          _status = '启动NFC会话失败: $e';
          _isProcessing = false;
        });
      }
    }
  }
}