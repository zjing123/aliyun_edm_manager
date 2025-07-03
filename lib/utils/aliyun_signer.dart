import 'dart:convert';
import 'package:crypto/crypto.dart';

class AliyunSigner {
  static String percentEncode(String s) {
    return Uri.encodeComponent(s)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }

  static String sign(Map<String, String> params, String secret, [String method = 'GET']) {
    final keys = params.keys.toList()..sort();
    final query = keys
        .map((k) => '${percentEncode(k)}=${percentEncode(params[k]!)}')
        .join('&');

    final toSign = '$method&%2F&${percentEncode(query)}';
    final key = utf8.encode('$secret&');
    final msg = utf8.encode(toSign);

    final hmac = Hmac(sha1, key);
    return base64Encode(hmac.convert(msg).bytes);
  }
}