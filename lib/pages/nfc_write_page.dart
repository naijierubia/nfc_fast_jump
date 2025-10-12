import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class NfcWritePage extends StatefulWidget {
  final List<Map<String, dynamic>> musicLinks;
  final String title;

  const NfcWritePage({
    super.key,
    required this.musicLinks,
    required this.title,
  });

  @override
  State<NfcWritePage> createState() => _NfcWritePageState();
}

class _NfcWritePageState extends State<NfcWritePage> {
  late List<Map<String, dynamic>> _musicLinks;
  int _currentIndex = 0;
  String _status = '准备写入第一个链接';
  bool _isWriting = false;
  bool _isCooldown = false; // 写入冷却状态标志
  bool _isLoading = false; // 歌曲信息加载状态

  // 写入后的冷却时间（毫秒），可配置
  static const int WRITE_COOLDOWN_TIME = 1000;

  @override
  void initState() {
    super.initState();
    _musicLinks = List.from(widget.musicLinks);
    _currentIndex = 0;
    _status = '准备写入第一个链接';

    // 获取歌曲信息
    _fetchSongInfo();
  }

  // 获取歌曲信息
  void _fetchSongInfo() async {
    setState(() {
      _isLoading = true;
    });

    // 构建ID列表用于批量请求
    List<String> ids = _musicLinks.map((link) => link['id'] as String).toList();

    try {
      // 使用新的API获取歌曲信息
      final dio = Dio();
      final response = await dio.get(
        'https://163api.qijieya.cn/song/detail?ids=${ids.join(',')}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['songs'] != null) {
          List songs = data['songs'];

          // 更新每个歌曲的信息
          for (int i = 0; i < songs.length && i < _musicLinks.length; i++) {
            var song = songs[i];
            setState(() {
              _musicLinks[i] = {
                'id': _musicLinks[i]['id'],
                'url': _musicLinks[i]['url'],
                'title': song['name'] ?? '未知歌曲',
                'artist': (song['ar'] != null && song['ar'].isNotEmpty)
                    ? song['ar'][0]['name'] ?? '未知歌手'
                    : '未知歌手',
              };
            });
          }
        }
      }
    } catch (e) {
      // 如果发生异常，设置为获取失败
      debugPrint('获取歌曲信息失败: $e');
      for (int i = 0; i < _musicLinks.length; i++) {
        setState(() {
          _musicLinks[i] = {
            'id': _musicLinks[i]['id'],
            'url': _musicLinks[i]['url'],
            'title': '获取失败',
            'artist': '获取失败',
          };
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 写入当前链接到NFC标签
  void _writeCurrentLink() async {
    if (_musicLinks.isEmpty || _currentIndex >= _musicLinks.length) {
      return;
    }

    setState(() {
      _isWriting = true;
      _status = '请将NFC标签靠近设备...';
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // 获取NDEF实例
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              setState(() {
                _status = '标签不支持NDEF格式';
                _isWriting = false;
              });
              await NfcManager.instance.stopSession();
              return;
            }

            // 写入当前链接和应用包名
            String link = _musicLinks[_currentIndex]['url'];
            final uriRecord = NdefRecord.createUri(Uri.parse(link));

            // 创建应用记录，指定网易云音乐包名
            final appRecord = NdefRecord(
              typeNameFormat: NdefTypeNameFormat.nfcExternal,
              type: Uint8List.fromList('android.com:pkg'.codeUnits),
              identifier: Uint8List.fromList([]),
              payload: Uint8List.fromList('com.netease.cloudmusic'.codeUnits),
            );

            // 创建包含URI记录和应用记录的消息
            final message = NdefMessage([uriRecord, appRecord]);
            await ndef.write(message);

            // 显示成功提示
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('NFC标签写入成功！'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            setState(() {
              _status = '录入成功: $link';
              _isWriting = false;
              _isCooldown = true; // 启动写入冷却状态
            });

            // 启动冷却计时器
            Future.delayed(Duration(milliseconds: WRITE_COOLDOWN_TIME), () {
              if (mounted) {
                setState(() {
                  _isCooldown = false;
                });
              }
            });

            // 如果还有下一个链接，自动切换到下一个
            if (_currentIndex < _musicLinks.length - 1) {
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  _currentIndex++;
                  _status = '准备写入下一个链接';
                });
              });
            } else {
              // 所有链接写入完成
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  _status = '所有链接录入完成';
                  _isWriting = false;
                });
              });
            }
          } catch (e) {
            setState(() {
              _status = '写入失败: $e';
              _isWriting = false;
            });
          } finally {
            // 写入完成后延迟关闭会话
            Future.delayed(Duration(milliseconds: WRITE_COOLDOWN_TIME),
                () async {
              await NfcManager.instance.stopSession();
            });
          }
        },
        onError: (e) {
          setState(() {
            _status = 'NFC会话错误: $e';
            _isWriting = false;
          });
          return Future<void>.value();
        },
      );
    } catch (e) {
      setState(() {
        _status = '启动NFC会话失败: $e';
        _isWriting = false;
      });
    }
  }

  // 切换到上一个链接
  void _previousLink() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _status = '准备写入链接';
      });
    }
  }

  // 切换到下一个链接
  void _nextLink() {
    if (_currentIndex < _musicLinks.length - 1) {
      setState(() {
        _currentIndex++;
        _status = '准备写入链接';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (_musicLinks.isNotEmpty && !_isWriting && !_isCooldown) {
            if (details.velocity.pixelsPerSecond.dx > 0) {
              // 右滑，切换到上一个
              _previousLink();
            } else if (details.velocity.pixelsPerSecond.dx < 0) {
              // 左滑，切换到下一个
              _nextLink();
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_musicLinks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前写入链接 (${_currentIndex + 1}/${_musicLinks.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _musicLinks[_currentIndex]['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _musicLinks[_currentIndex]['artist'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _musicLinks[_currentIndex]['url'],
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: (_currentIndex > 0 &&
                                    !_isWriting &&
                                    !_isCooldown)
                                ? _previousLink
                                : null,
                            child: const Text('上一个'),
                          ),
                          ElevatedButton(
                            onPressed: (_isWriting || _isCooldown)
                                ? null
                                : _writeCurrentLink,
                            child: Text(_isWriting
                                ? '写入中...'
                                : (_isCooldown ? '稍候...' : '开始录入')),
                          ),
                          ElevatedButton(
                            onPressed:
                                (_currentIndex < _musicLinks.length - 1 &&
                                        !_isWriting &&
                                        !_isCooldown)
                                    ? _nextLink
                                    : null,
                            child: const Text('下一个'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '所有链接列表:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _musicLinks.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (!_isWriting && !_isCooldown) {
                            setState(() {
                              _currentIndex = index;
                              _status = '准备写入链接';
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Colors.deepPurple.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              if (index == _currentIndex)
                                const Icon(Icons.arrow_right,
                                    color: Colors.deepPurple)
                              else
                                const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // 显示歌曲标题
                                        Expanded(
                                          child: Text(
                                            _musicLinks[index]['title'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // 如果正在加载，显示加载指示器
                                        (_isLoading &&
                                                _musicLinks[index]['title'] ==
                                                    '加载中...')
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.grey),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
                                    Text(
                                      _musicLinks[index]['artist'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _musicLinks[index]['url'],
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
