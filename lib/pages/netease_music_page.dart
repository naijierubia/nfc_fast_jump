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
  // 0: 歌曲链接模式, 1: 歌单链接模式
  int _selectedMode = 0;

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
      _status = _selectedMode == 0 ? '正在解析歌曲链接...' : '正在解析歌单链接...';
    });

    if (_selectedMode == 0) {
      // 歌曲链接模式
      await _parseSongLinks(text);
    } else {
      // 歌单链接模式
      await _parsePlaylistLinks(text);
    }
  }

  // 解析歌曲链接
  Future<void> _parseSongLinks(String text) async {
    // 支持多行输入，每行一个链接或包含链接的文本
    List<String> lines = text.split('\n');
    List<Map<String, dynamic>> validLinks = [];
    List<String> errorMessages = [];

    for (String line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        try {
          // 使用新的工具类解析链接，支持歌曲和歌单
          List<String>? ids = await LinkResolver.resolveNeteaseMusicIds(line);
          if (ids != null && ids.isNotEmpty) {
            // 如果是歌单链接但在歌曲模式下，只取第一首歌曲
            String id = ids[0];
            validLinks.add({
              'id': id,
              'url': 'orpheus://song/$id/?autoplay=1', // 保持正确的写入内容
              'title': '加载中...',
              'artist': '加载中...',
            });
          } else {
            errorMessages.add('无法解析: $line');
          }
        } catch (e) {
          errorMessages.add('解析错误 ($line): $e');
        }
      }
    }

    if (validLinks.isEmpty) {
      String errorMessage = '未找到有效的网易云音乐链接';
      if (errorMessages.isNotEmpty) {
        errorMessage += '\n错误详情:\n${errorMessages.join('\n')}';
      }
      setState(() {
        _status = errorMessage;
        _isLoading = false;
      });
      return;
    }

    String successMessage = '成功解析 ${validLinks.length} 个链接';
    if (errorMessages.isNotEmpty) {
      successMessage += '\n${errorMessages.length} 个链接解析失败';
    }

    setState(() {
      _status = '$successMessage\n准备跳转到录入界面';
      _isLoading = false;
    });

    // 跳转到录入页面
    Future.delayed(const Duration(milliseconds: 500), () {
      context.push('/nfc-write', extra: {
        'musicLinks': validLinks,
        'title': '网易云音乐写入',
      });
    });
  }

  // 解析歌单链接
  Future<void> _parsePlaylistLinks(String text) async {
    List<String> lines = text.split('\n');
    List<Map<String, dynamic>> validLinks = [];
    List<String> errorMessages = [];

    for (String line in lines) {
      line = line.trim();
      if (line.isNotEmpty) {
        try {
          // 使用新的工具类解析链接，支持歌曲和歌单
          List<String>? ids = await LinkResolver.resolveNeteaseMusicIds(line);
          if (ids != null && ids.isNotEmpty) {
            // 如果是歌单链接，则添加所有歌曲
            for (String id in ids) {
              validLinks.add({
                'id': id,
                'url': 'orpheus://song/$id/?autoplay=1', // 保持正确的写入内容
                'title': '加载中...',
                'artist': '加载中...',
              });
            }
          } else {
            errorMessages.add('无法解析: $line');
          }
        } catch (e) {
          errorMessages.add('解析错误 ($line): $e');
        }
      }
    }

    if (validLinks.isEmpty) {
      String errorMessage = '未找到有效的网易云音乐链接';
      if (errorMessages.isNotEmpty) {
        errorMessage += '\n错误详情:\n${errorMessages.join('\n')}';
      }
      setState(() {
        _status = errorMessage;
        _isLoading = false;
      });
      return;
    }

    String successMessage = '成功解析 ${validLinks.length} 首歌曲';
    if (errorMessages.isNotEmpty) {
      successMessage += '\n${errorMessages.length} 个链接解析失败';
    }

    setState(() {
      _status = '$successMessage\n准备跳转到录入界面';
      _isLoading = false;
    });

    // 跳转到录入页面
    Future.delayed(const Duration(milliseconds: 500), () {
      context.push('/nfc-write', extra: {
        'musicLinks': validLinks,
        'title': '网易云音乐写入',
      });
    });
  }

  // 清空文本框
  void _clearText() {
    _linkController.clear();
    setState(() {
      _status = _selectedMode == 0 ? '请输入网易云音乐歌曲分享链接' : '请输入网易云音乐歌单分享链接';
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
            // 添加顶部菜单栏切换
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment(value: 0, label: Text('歌曲链接')),
                ButtonSegment(value: 1, label: Text('歌单链接')),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedMode = newSelection.first;
                  _status =
                      _selectedMode == 0 ? '请输入网易云音乐歌曲分享链接' : '请输入网易云音乐歌单分享链接';
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _linkController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: _selectedMode == 0 ? '网易云音乐歌曲分享链接' : '网易云音乐歌单分享链接',
                alignLabelWithHint: true, // 使标签与提示文本对齐
                hintText: _selectedMode == 0
                    ? '支持多行输入，每行可以是:\n1. 完整链接\n2. 包含链接的分享文本\n例如：\n放課後ティータイム的单曲《ふわふわ時間》: https://163cn.tv/JUot0mE (来自@网易云音乐)'
                    : '支持多行输入，每行一个歌单链接\n例如：\nhttps://music.163.com/playlist?id=14348070301\nhttps://music.163.com/#/album?id=34209',
                border: const OutlineInputBorder(),
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
