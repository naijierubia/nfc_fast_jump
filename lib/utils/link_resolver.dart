import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LinkResolver {
  /// 解析网易云音乐链接，支持短链、歌曲链接和歌单链接
  static Future<List<String>?> resolveNeteaseMusicIds(String text) async {
    debugPrint('开始解析文本: $text');

    // 从文本中提取链接
    final link = _extractLinkFromText(text);
    if (link == null) {
      debugPrint('未能从文本中提取链接');
      return null;
    }

    debugPrint('提取到链接: $link');

    // 判断链接类型
    if (_isPlaylistLink(link)) {
      debugPrint('检测到歌单链接');
      return await _resolvePlaylist(link);
    } else if (_isShortLink(link)) {
      debugPrint('检测到短链接，开始展开');
      // 展开短链接获取真实链接
      final expandedLink = await _expandShortLink(link);
      if (expandedLink != null) {
        debugPrint('短链接展开成功: $expandedLink');
        // 判断展开后的链接类型
        if (_isPlaylistLink(expandedLink)) {
          debugPrint('展开后为歌单链接');
          return await _resolvePlaylist(expandedLink);
        } else {
          // 从展开的链接中提取歌曲ID
          final id = _extractIdFromExpandedLink(expandedLink);
          if (id != null) {
            return [id];
          }
        }
      } else {
        debugPrint('短链接展开失败');
      }
    } else {
      debugPrint('处理长链接');
      // 判断是否为歌单链接
      if (_isPlaylistLink(link)) {
        debugPrint('检测到歌单链接');
        return await _resolvePlaylist(link);
      } else {
        // 直接从长链接中提取歌曲ID
        final id = _extractIdFromLongLink(link);
        if (id != null) {
          return [id];
        }
      }
    }

    return null;
  }

  /// 解析网易云音乐链接，支持短链和长链（兼容旧版本）
  static Future<String?> resolveNeteaseMusicId(String text) async {
    final ids = await resolveNeteaseMusicIds(text);
    return ids != null && ids.isNotEmpty ? ids[0] : null;
  }

  /// 从文本中提取链接 (公开方法，供测试使用)
  static String? extractLinkFromText(String text) {
    return _extractLinkFromText(text);
  }

  /// 判断是否是短链接 (公开方法，供测试使用)
  static bool isShortLink(String link) {
    return _isShortLink(link);
  }

  /// 判断是否是歌单链接 (公开方法，供测试使用)
  static bool isPlaylistLink(String link) {
    return _isPlaylistLink(link);
  }

  /// 展开短链接 (公开方法，供测试使用)
  static Future<String?> expandShortLink(String shortLink) async {
    return _expandShortLink(shortLink);
  }

  /// 从展开的链接中提取ID (公开方法，供测试使用)
  static String? extractIdFromExpandedLink(String expandedLink) {
    return _extractIdFromExpandedLink(expandedLink);
  }

  /// 从长链接中提取ID (公开方法，供测试使用)
  static String? extractIdFromLongLink(String link) {
    return _extractIdFromLongLink(link);
  }

  /// 从文本中提取链接
  static String? _extractLinkFromText(String text) {
    // 匹配常见的链接格式
    final linkPattern = RegExp(r'https?://[^\s]+');
    final match = linkPattern.firstMatch(text);
    return match?.group(0);
  }

  /// 判断是否是短链接
  static bool _isShortLink(String link) {
    return link.contains('163cn.tv');
  }

  /// 判断是否是歌单链接
  static bool _isPlaylistLink(String link) {
    return link.contains('playlist') || link.contains('album');
  }

  /// 解析歌单链接，获取其中的歌曲ID列表
  static Future<List<String>?> _resolvePlaylist(String playlistLink) async {
    try {
      debugPrint('开始解析歌单链接: $playlistLink');

      // 提取歌单ID
      String? playlistId;
      final playlistPattern = RegExp(r'(?:playlist|album)\?id=(\d+)');
      final match = playlistPattern.firstMatch(playlistLink);

      if (match != null) {
        playlistId = match.group(1);
        debugPrint('提取到歌单ID: $playlistId');
      } else {
        // 尝试从其他格式中提取
        final otherPattern = RegExp(r'/(playlist|album)/(\d+)');
        final otherMatch = otherPattern.firstMatch(playlistLink);
        if (otherMatch != null) {
          playlistId = otherMatch.group(2);
          debugPrint('通过其他格式提取到歌单ID: $playlistId');
        }
      }

      if (playlistId == null) {
        debugPrint('未能提取到歌单ID');
        return null;
      }

      // 调用API获取歌单详情
      final dio = Dio();

      // 使用正确的API地址，不添加限制参数
      final response = await dio.get(
        'https://163api.qijieya.cn/playlist/track/all?id=$playlistId',
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('歌单API响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> &&
            data['code'] == 200 &&
            data['songs'] is List) {
          final songs = data['songs'] as List;
          final ids = <String>[];

          for (final song in songs) {
            if (song is Map<String, dynamic> && song['id'] != null) {
              ids.add(song['id'].toString());
              debugPrint('提取到歌曲ID: ${song['id']}');
            }
          }

          debugPrint('总共提取到 ${ids.length} 首歌曲');
          return ids.isNotEmpty ? ids : null;
        }
      }
    } catch (e, stack) {
      debugPrint('解析歌单时发生错误: $e\n堆栈信息: $stack');
    }

    return null;
  }

  /// 展开短链接
  static Future<String?> _expandShortLink(String shortLink) async {
    try {
      final dio = Dio();
      // 设置请求头，模拟手机浏览器
      final options = Options(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Sec-Fetch-User': '?1',
        },
        followRedirects: false,
        // 接受重定向状态码，避免Dio抛出异常
        validateStatus: (status) {
          return status != null && status >= 200 && status < 400;
        },
      );

      final response = await dio.get(shortLink, options: options);
      debugPrint('短链接请求状态码: ${response.statusCode}');

      // 获取重定向地址
      String? location = response.headers['location']?.last;
      debugPrint('Location头: $location');

      if (location != null) {
        // 如果location是相对路径，需要拼接成完整URL
        if (location.startsWith('/')) {
          final uri = Uri.parse(shortLink);
          location = '${uri.scheme}://${uri.host}$location';
        }
        debugPrint('处理后的重定向地址: $location');
        return location;
      }

      // 如果没有location头，返回最终的URL
      final finalUrl = response.realUri.toString();
      debugPrint('最终URL: $finalUrl');
      return finalUrl;
    } catch (e, stack) {
      debugPrint('展开短链接时发生错误: $e\n堆栈信息: $stack');
      // 出错时返回null
      return null;
    }
  }

  /// 从展开的链接中提取ID
  static String? _extractIdFromExpandedLink(String expandedLink) {
    try {
      debugPrint('从展开链接中提取ID: $expandedLink');
      // 从类似 https://y.music.163.com/m/song?id=26201899&... 的链接中提取ID
      final uri = Uri.parse(expandedLink);
      final id = uri.queryParameters['id'];
      debugPrint('提取到的ID: $id');
      return id;
    } catch (e, stack) {
      debugPrint('从展开链接提取ID时发生错误: $e\n堆栈信息: $stack');
      return null;
    }
  }

  /// 从长链接中提取ID
  static String? _extractIdFromLongLink(String link) {
    try {
      debugPrint('从长链接中提取ID: $link');
      // 匹配网易云音乐链接中的歌曲ID
      final idPattern = RegExp(r'(?:song|track)\?id=(\d+)');
      final match = idPattern.firstMatch(link);

      if (match != null) {
        debugPrint('通过模式1提取ID: ${match.group(1)}');
        return match.group(1);
      }

      // 尝试从其他格式的链接中提取ID
      final otherPattern = RegExp(r'/(\d+)(?:\?|$)');
      final otherMatch = otherPattern.firstMatch(link);

      if (otherMatch != null) {
        debugPrint('通过模式2提取ID: ${otherMatch.group(1)}');
        return otherMatch.group(1);
      }

      debugPrint('未能从长链接中提取ID');
    } catch (e, stack) {
      debugPrint('从长链接提取ID时发生错误: $e\n堆栈信息: $stack');
    }

    return null;
  }
}
