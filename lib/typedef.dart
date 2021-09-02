part of neonday_http_ex;


typedef void HttpOnHeaderFunction(int statusCode, Map<String, String> headers);
typedef void HttpOnDataFunction(Uint8List data);