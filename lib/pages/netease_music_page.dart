import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// 导入链接解析工具
import '../utils/link_resolver.dart';

class NeteaseMusicPage extends StatefulWidget {
  const NeteaseMusicPage({super.key});

  @override
  State<NeteaseMusicPage> createState() => _NeteaseMusicPageState();
}

class _NeteaseMusicPageState extends State<NeteaseMusicPage> {
  final TextEditingController _linkController = TextEditingController();
  String _status = '请输入网易云音乐分享链接';
  bool _isLoading = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  // 解析网易云音乐链接
  void _parseLinks() async {
    String text = _linkController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _status = '请输入链接内容';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '正在解析链接...';
    });

    // 支持多行输入，每行一个链接或包含链接的文本
    List<String> lines = text.split('\n');
    List<Map<String, dynamic>> validLinks = [];

    for (String line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        // 使用新的工具类解析链接
        String? id = await LinkResolver.resolveNeteaseMusicId(line);
        if (id != null) {
          validLinks.add({
            'id': id,
            'url': 'orpheus://song/$id/?autoplay=1', // 保持正确的写入内容
            'title': '加载中...',
            'artist': '加载中...',
          });
        }
      }
    }

    if (validLinks.isEmpty) {
      setState(() {
        _status = '未找到有效的网易云音乐链接';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _status = '解析完成，准备跳转到录入界面';
      _isLoading = false;
    });

    // 跳转到录入页面
    Future.delayed(const Duration(milliseconds: 500), () {
      context.push('/nfc-write', extra: {
        'musicLinks': validLinks,
        'title': '网易云音乐链接写入',
      });
    });
  }

  // 清空文本框
  void _clearText() {
    _linkController.clear();
    setState(() {
      _status = '请输入网易云音乐分享链接';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网易云音乐写入'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '网易云音乐链接写入',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _linkController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '网易云音乐分享链接',
                alignLabelWithHint: true,
                hintText:
                    '支持多行输入，自动识别文本中的链接\n支持长链接和短链接\n例如：\n放課後ティータイム的单曲《ふわふわ時間》: https://163cn.tv/JUot0mE (来自@网易云音乐)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _parseLinks,
                  child: Text(_isLoading ? '解析中...' : '解析链接'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearText,
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
