import 'dart:io';
import 'dart:convert';

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
      final request = HttpClient();
      // 设置请求头，模拟手机浏览器
      final url = Uri.parse(shortLink);
      final response = await request.getUrl(url)
        ..headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 13; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36')
        ..headers.set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8')
        ..headers.set('Accept-Language', 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7')
        ..headers.set('Accept-Encoding', 'gzip, deflate, br')
        ..headers.set('Connection', 'keep-alive')
        ..headers.set('Upgrade-Insecure-Requests', '1')
        ..headers.set('Sec-Fetch-Dest', 'document')
        ..headers.set('Sec-Fetch-Mode', 'navigate')
        ..headers.set('Sec-Fetch-Site', 'none')
        ..headers.set('Sec-Fetch-User', '?1');
      
      final httpResponse = await response.close();
      
      // 返回最终重定向的URL
      return httpResponse.redirects.isNotEmpty 
        ? httpResponse.redirects.last.location.toString() 
        : httpResponse.headers.value('location');
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