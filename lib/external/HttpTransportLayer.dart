part of truecollaboration_http_ex;


typedef OnReceiveHeader = Future<void> Function(int statusCode, Map<String, String> headers);
typedef OnReceiveBody   = Future<void> Function(List<int> bytes);

@deprecated
/// TODO REPLACE
class HttpTimeouts {
  /// Connect timeout
  Duration connection;

  /// Timeout between receiving data
  Duration receive;

  /// Timeout from socket-open to socket-close connection
  Duration receiveTotal;
  HttpTimeouts({
    this.connection = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 30),
    this.receiveTotal = const Duration(minutes: 2),
  });
}


@deprecated
/// TODO REPLACE
class HttpTransportLayer {
  static const String TAG = "HttpTransportLayer";
  static const String DEFAULT_AGENT = "HttpTransportLayer 1.0";

  static const Duration TIMEOUT_CON       = const Duration(seconds: 10);
  static const Duration TIMEOUT_REC       = const Duration(seconds: 30);
  static const Duration TIMEOUT_REC_TOTAL = const Duration(minutes: 2);


  static Future<IResponseEx<HttpClientResponse>> get(
    String url, {
      Map<String, String> headers = const {},
      bool ignoreSertificate = false,
      String? proxy,
      required HttpTimeouts timeouts,
  }) async {
    ResponseEx<HttpClientResponse> result = new ResponseEx();

    timeouts = _fixTimeouts(timeouts);
    
    HttpClient client = _buildHttpClient(
      url,
      headers: headers,
      ignoreSertificate: ignoreSertificate,
      proxy: proxy,
      timeouts: timeouts,
    );

    
    // (uri)  {
    //   return HttpClient.findProxyFromEnvironment(uri, environment: {
    //     "https_proxy": "assets.cdn-prime.net:443",
    //     // "no_proxy": ...
    //     },
    //   );
    // };
    
    // bool bDebug = !url.contains("ping.txt");
    bool bDebug = false; //TODO


    late HttpClientRequest req;
    late HttpClientResponse res;

    var operation = _OperationWithTimeout();
    operation.then(timeouts.connection, () async {
      // if(bDebug)
      //   Log.d(TAG, "get; GETTING URL");
      req = await client.getUrl(Uri.parse(url));
      // if(bDebug)
      //   Log.d(TAG, "get; GETTED URL");
    }).then(timeouts.receiveTotal, () async {
      // if(bDebug)
      //   Log.d(TAG, "get; CLOSING URL");
      res = await req.close();
      // if(bDebug)
      //   Log.d(TAG, "get; CLOSED URL");
      if(operation.expired)
        return;
      result.hasResponse = true;
    });
    
    try {
      await operation.run();
    } on SocketException catch(e, s) {
      result.errors.add(new IError(e, s));
      return result;
    } catch(e, s) {
      result.errors.add(new IError(e, s));
      return result;
    } result.connected = true;

    // 400 and 500
    if(res.statusCode > 399 && res.statusCode < 600)
      result.protoDone = false;
    else result.protoDone = true;
    result.statusCode = res.statusCode;
    result.data = res;
    return result;
  }


  static Future<IResponseEx<NeonJsonObject>> getJson(
    String url, {
      Map<String, String> headers = const {},
      bool ignoreSertificate = false,
      String? proxy,
      required HttpTimeouts timeouts,
  }) async {
    ResponseEx<NeonJsonObject> result = new ResponseEx();

    var out = await get(
      url,
      headers: headers,
      ignoreSertificate: ignoreSertificate,
      proxy: proxy,
      timeouts: timeouts,
    ) as ResponseEx<HttpClientResponse>;
    out.copyTo(result);
    

    NeonJsonObject json;
    bool jsonError = false;
    if(out.connected) {
      try {
        json = await _response2json(out.data!);
        result.data = json;
      } catch(e, s) {
        result.errors.add(new IError(e, s));
        jsonError = true;
      } if(jsonError) {
        result.isResponseCorrect = false;
        return result;
      } else {
        result.isResponseCorrect = true;
      } 
    } return result;
  }























  static Future<IResponseEx<HttpClientResponse>> head(
    String url, {
      Map<String, String> headers = const {},
      bool ignoreSertificate = false,
      String? proxy,
      required HttpTimeouts timeouts,
    }) async {
    var result = new ResponseEx<HttpClientResponse>();

    timeouts = _fixTimeouts(timeouts);
    
    HttpClient client = _buildHttpClient(
      url,
      headers: headers,
      ignoreSertificate: ignoreSertificate,
      proxy: proxy,
      timeouts: timeouts,
    );

    HttpClientResponse res;
    try {
      HttpClientRequest req = await client.headUrl(Uri.parse(url)).timeout(timeouts.connection);
      res = await req.close().timeout(timeouts.connection);
      result.hasResponse = true;
    } on SocketException catch(e, s) {
      result.errors.add(new IError(e, s));
      return result;
    } catch(e, s) {
      result.errors.add(new IError(e, s));
      return result;
    } result.connected = true;
    
    if(res.statusCode >= 400 || res.statusCode >= 500)
      result.protoDone = false;
    else result.protoDone = true;
    result.statusCode = res.statusCode;
    result.data = res;
    return result;
  }






  static Future<IResponseEx<void>> getRaw(
    String url,
    OnReceiveHeader onHeader,
    OnReceiveBody   onBody,
    OnReceiveBody   onFullBody, {
      Map<String, String> headers = const {},
      bool ignoreSertificate = false,
      String? proxy,
      List<int>? range,
      required HttpTimeouts timeouts,
  }) async {
    var result = new ResponseEx<void>();

    timeouts = _fixTimeouts(timeouts);

    HttpClient client = _buildHttpClient(
      url,
      headers: headers,
      ignoreSertificate: ignoreSertificate,
      proxy: proxy,
      timeouts: timeouts,
    );

    HttpClientResponse res;
    try {
      HttpClientRequest req = await client.getUrl(Uri.parse(url)).timeout(timeouts.connection);
      if(range != null) {
        req.headers.add("Range", "bytes=${range[0]}-${range[1]}");
      }
      // req.headers.add("Connection", "keep-alive");
      // req.headers.add("Host", "2ip.mytrinity.com.ua");
      // req.headers.add("Origin", "https://2ip.ua");
      // req.headers.add("Referer", "https://2ip.ua/ru/myspeed");
      res = await req.close().timeout(timeouts.connection);

      await onHeader(res.statusCode, HttpConverter.httpHeaders2Map(res.headers));

      //TODO to realize timeouts
      // var timeoutTotal = new Timer(timeouts.receiveTotal, () {

      // });
      
      var completer = new Completer<void>();
      var stack = new SyncFunctionStack();
      bool bChunks = onFullBody != null;
      List<List<int>> chunks = [];
      res.listen((bytes) {
        if(bChunks)
          chunks.add(bytes);
        stack.add(() => onBody(bytes), true);
      },
      onError: (Object e, StackTrace s) {
        completer.completeError(e, s);
      },
      onDone: () {
        if(!completer.isCompleted)
          completer.complete();
      });
      
    
      await completer.future;
      await stack.waitForComplete();
      if(bChunks)
        await onFullBody(_chunks2chunk(chunks));
    } on SocketException catch(e, s) {
      result.errors.add(new IError(e, s));
      return result;
    } catch(e, s) {
      result.errors.add(new IError(e, s));
      return result;
    } result.connected = true;
    
    if(res.statusCode >= 400 || res.statusCode >= 500)
      result.protoDone = false;
    else result.protoDone = true;
    result.statusCode = res.statusCode;
    result.data = res;
    return result;
  }































  static HttpClient _buildHttpClient(
    String url, {
      Map<String, String> headers = const {},
      bool ignoreSertificate = false,
      String? proxy,
      required HttpTimeouts timeouts,
  }) {
    HttpClient client = HttpClient();
    client.userAgent          = _getUserAgent(headers);
    client.connectionTimeout  = timeouts.connection;
    client.idleTimeout        = timeouts.receive;
    if(proxy != null)
      client.findProxy = (uri) => proxy;
    client.badCertificateCallback = 
      ((X509Certificate cert, String host, int port) => ignoreSertificate);
    return client;
  }


  static String _getUserAgent(Map<String, String> headers)
      => headers["user-agent"] ?? DEFAULT_AGENT;



  static List<int> _chunks2chunk(List<List<int>> chunks) {
    int length = 0;
    int offset = 0;
    for(var chunk in chunks)
      length += chunk.length;
      
    var out = new Uint8List(length);
    for(var chunk in chunks) {
      _copyTo(chunk, out, offset);
      offset += chunk.length;
    } return out;
  }

  static void _copyTo(List<int> src, List<int> dst, int offset) {
    for(var byte in src)
      dst[offset++] = byte;
  }


  static HttpTimeouts _fixTimeouts(HttpTimeouts timeouts) {
    if(!_isCorrectDuration(timeouts.connection))
      timeouts.connection = TIMEOUT_CON;
    if(!_isCorrectDuration(timeouts.receive))
      timeouts.receive = TIMEOUT_REC;
    if(!_isCorrectDuration(timeouts.receiveTotal))
      timeouts.receiveTotal = TIMEOUT_REC_TOTAL;
    return timeouts;
  }

  static bool _isCorrectDuration(Duration d) => d.inMilliseconds > 0;









  static Future<NeonJsonObject> _response2json(HttpClientResponse response) async {
    Stream<String> stream = Convert.utf8.decoder.bind(response);
    StringBuffer sb = new StringBuffer();
    await stream.forEach((data) {
      sb.write(data);
    });
    return NeonJsonObject.fromJson(sb.toString());
  }
}



//TODO
class _OperationWithTimeout<T> {
  List<_Operation> _stack = [];
  _OperationWithTimeout();
  bool _bExpired = false;

  bool get expired => _bExpired;

  _OperationWithTimeout then(Duration timeout, Function f) {
    _stack.add(new _Operation(f, timeout));
    return this;
  }

  Future<T> run() async {
    var completer = Completer<T>(); 

    Future(() async {
      T? out;
      Timer timer;
      try {
        while(_stack.length > 0) {
          var op = _stack.removeAt(0);
          timer = new Timer(op.timeout, () {
            _bExpired = true;
            // Log.e("timeouted; bExpired = $_bExpired");
            if(!completer.isCompleted)
              completer.completeError(new TimeoutException(null, op.timeout));
          });
          // Log.e("await");
          out = await op.func();
          // Log.e("awaited; bExpired = $_bExpired");
          timer.cancel();
          if(_bExpired)
            break;
        } if(!completer.isCompleted)
          completer.complete(out);
      } catch(e, s) {
        _bExpired = true;
        if(!completer.isCompleted)
          completer.completeError(e, s);
      }
    });
    return completer.future;
  }
}


class _Operation {
  final Function func;
  final Duration timeout;
  _Operation(this.func, this.timeout);
}