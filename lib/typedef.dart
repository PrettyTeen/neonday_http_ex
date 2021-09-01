part of dev.neonday.libs.http_ex;


typedef void HttpOnHeaderFunction(int statusCode, Map<String, String> headers);
typedef void HttpOnDataFunction(Uint8List data);