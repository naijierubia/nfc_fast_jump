import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

    List<String> links = text.split('\n');
    List<Map<String, dynamic>> validLinks = [];

    for (String link in links) {
      link = link.trim();
      if (link.isNotEmpty) {
        // 提取网易云音乐歌曲ID
        String? id = _extractMusicId(link);
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
      });
      return;
    }

    setState(() {
      _status = '解析完成，准备跳转到录入界面';
    });

    // 跳转到录入页面
    Future.delayed(const Duration(milliseconds: 500), () {
      context.push('/nfc-write', extra: {
        'musicLinks': validLinks,
        'title': '网易云音乐写入',
      });
    });
  }


  // 从链接中提取音乐ID
  String? _extractMusicId(String link) {
    // 匹配网易云音乐链接中的歌曲ID
    RegExp idPattern = RegExp(r'(?:song|track)\?id=(\d+)');
    RegExpMatch? match = idPattern.firstMatch(link);
    
    if (match != null) {
      return match.group(1);
    }
    
    // 尝试从短链接中提取ID
    RegExp shortPattern = RegExp(r'/(\d+)(?:\?|$)');
    match = shortPattern.firstMatch(link);
    
    if (match != null) {
      return match.group(1);
    }
    
    return null;
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
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '网易云音乐分享链接',
                hintText: '支持多行输入，每行一个链接\n例如：https://music.163.com/song?id=123456',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _parseLinks,
              child: Text(_isLoading ? '解析中...' : '解析链接'),
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
