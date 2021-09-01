part of dev.neonday.libs.http_ex;

abstract class HttpUtil {
  static bool isCode200(int code) {
    return code >= 200 && code < 300;
  }
}

enum HttpMethod {
  HEAD,
  GET,
  POST,
  PUT,
  DELETE,
  OPTIONS,
}