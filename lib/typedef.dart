part of truecollaboration_http_ex;


typedef void HttpOnHeaderFunction(HttpClientRequest request, HttpClientResponse response, int statusCode, Map<String, String> headers);
typedef void HttpOnDataFunction(Uint8List data);