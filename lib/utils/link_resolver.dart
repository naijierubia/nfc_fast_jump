import 'package:dio/dio.dart';

class LinkResolver {
  /// 解析网易云音乐链接，支持短链和长链
  static Future<String?> resolveNeteaseMusicId(String text) async {
    // 从文本中提取链接
    final link = _extractLinkFromText(text);
    if (link == null) {
      return null;
    }

    // 判断是否是短链接
    if (_isShortLink(link)) {
      // 展开短链接获取真实链接
      final expandedLink = await _expandShortLink(link);
      if (expandedLink != null) {
        // 从展开的链接中提取ID
        return _extractIdFromExpandedLink(expandedLink);
      }
    } else {
      // 直接从长链接中提取ID
      return _extractIdFromLongLink(link);
    }

    return null;
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

      // 返回最终重定向的URL
      String? location = response.headers['location']?.last;
      if (location != null) {
        // 如果location是相对路径，需要拼接成完整URL
        if (location.startsWith('/')) {
          final uri = Uri.parse(shortLink);
          location = '${uri.scheme}://${uri.host}$location';
        }
        return location;
      }

      // 如果没有location头，返回最终的URL
      return response.realUri.toString();
    } catch (e) {
      // 出错时返回null
      return null;
    }
  }

  /// 从展开的链接中提取ID
  static String? _extractIdFromExpandedLink(String expandedLink) {
    // 从类似 https://y.music.163.com/m/song?id=26201899&... 的链接中提取ID
    final uri = Uri.parse(expandedLink);
    final id = uri.queryParameters['id'];
    return id;
  }

  /// 从长链接中提取ID
  static String? _extractIdFromLongLink(String link) {
    // 匹配网易云音乐链接中的歌曲ID
    final idPattern = RegExp(r'(?:song|track)\?id=(\d+)');
    final match = idPattern.firstMatch(link);

    if (match != null) {
      return match.group(1);
    }

    // 尝试从其他格式的链接中提取ID
    final otherPattern = RegExp(r'/(\d+)(?:\?|$)');
    final otherMatch = otherPattern.firstMatch(link);

    if (otherMatch != null) {
      return otherMatch.group(1);
    }

    return null;
  }
}
