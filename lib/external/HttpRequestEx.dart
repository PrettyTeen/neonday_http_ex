part of neonday_http_ex;

///TODO add Timings
abstract class HttpRequestEx {
  // CONSTRUCTORS
  //----------------------------------------------------------------------------
  factory HttpRequestEx.client(HttpClient client) => new _HttpRequestEx(
    client: client,
  );

  factory HttpRequestEx() => new _HttpRequestEx(
    client: new HttpClient(),
  );
  //----------------------------------------------------------------------------




  // EXTERNAL
  //----------------------------------------------------------------------------
  Object?     get lastError;
  StackTrace? get stacktrace;

  bool        get requesting;
  bool        get closed;

  Future<bool> raw(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      required HttpOnHeaderFunction onHeader,
      required HttpOnDataFunction onData,
      bool debugIgnoreCertificate = false,
      String debugProxy = "",
  });

  HttpRequestResult json(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      bool debugIgnoreCertificate = false,
      String debugProxy = "",
  });

  Future<void> close();
  //----------------------------------------------------------------------------
}




class _HttpRequestEx implements HttpRequestEx {
  final HttpClient client;
  _HttpRequestEx({
    required this.client,
  });
  
  @override
  Object? lastError;

  @override
  StackTrace? stacktrace;


  @override
  bool requesting = false;

  @override
  bool closed = false;

  @override
  Future<void> close() {
    closed = true;
    return onClose;
  }



  Future<void> get onClose => cOnClose.future;
  final cOnClose = new Completer<bool>();

  @override
  Future<bool> raw(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      Stream<Uint8List>? input,
      required HttpOnHeaderFunction onHeader,
      required HttpOnDataFunction onData,
      bool debugIgnoreCertificate = false,
      String debugProxy = "",
  }) async {
    if(requesting || closed)
      throw(new Exception("Already have been used"));
    requesting = true;
    
    // PRE-INIT
    //--------------------------------------------------------------------------
    bool result = false;
    //--------------------------------------------------------------------------

    

    if(debugIgnoreCertificate) {
      client.badCertificateCallback = 
        ((X509Certificate cert, String host, int port) => true);
    }

    if(debugProxy.length > 0)
      client.findProxy = (uri) => debugProxy;
     
    client.connectionTimeout = timeouts.connection;
    client.idleTimeout = timeouts.idle;

    client.userAgent = headers["user-agent"];

    
    // Log.e("getUrl $uri");
    try {
      while(true) {
        late HttpClientRequest httpRequest;
        late HttpClientResponse httpResponse;

        final NotifierStorage streamListener = new NotifierStorage();

        RenewableTimer idleTimer, receiveTimer;
        TimedTask task;
        bool timeouted = false;


        // SENDING HEADERS
        //----------------------------------------------------------------------
        task = new TimedTask(timeouts.connection, Future(() async {
          httpRequest = await switchMethod(client, uri, method);
        }));
        timeouted = await task.run(false, true);
        if(timeouted || closed) {
          lastError = new TimeoutException("NetworkTimeouts.connection", timeouts.connection);
          stacktrace = StackTrace.current;
          break;
        }

        headers.forEach((name, value) {
          httpRequest.headers.set(name, value);
        });
        //----------------------------------------------------------------------


        // SENDING BODY
        //----------------------------------------------------------------------
        if(input != null) {
          var sub = input.listen((data) {
            httpRequest.add(data);
          });
          try {
            await sub.asFuture(true);
          } catch(e) {
            lastError = new Exception("Input ended unsuccessfully");
            stacktrace = StackTrace.current;
            break;
          } finally {
            sub.cancel();
          }
        }
        //----------------------------------------------------------------------
        
        

        // WAITING FOR SERVER RESPONSE
        //----------------------------------------------------------------------
        task = new TimedTask(timeouts.response, Future(() async {
          httpResponse = await httpRequest.close();
        }));
        timeouted = await task.run(false, true);
        if(timeouted || closed) {
          lastError = new TimeoutException("NetworkTimeouts.response", timeouts.response);
          stacktrace = StackTrace.current;
          break;
        }
        //----------------------------------------------------------------------
        










        




        idleTimer = new RenewableTimer(timeouts.idle, () {
          if(cOnClose.isCompleted)
            return;
          lastError = new TimeoutException("NetworkTimeouts.idle", timeouts.idle);
          stacktrace = StackTrace.current;
          cOnClose.complete(false);
        });

        receiveTimer = new RenewableTimer(timeouts.receiveTotal, () {
          if(cOnClose.isCompleted)
            return;
          lastError = new TimeoutException("NetworkTimeouts.receiveTotal", timeouts.receiveTotal);
          stacktrace = StackTrace.current;
          cOnClose.complete(false);
        });



        
        // RECEIVING DATA
        //----------------------------------------------------------------------
        onHeader(httpResponse.statusCode, HttpConverter.httpHeaders2Map(httpResponse.headers));
        
        streamListener.addStream(httpResponse.listen((bytes) {
          if(closed) {
            streamListener.clear();
            return;
          }
          // Log.e("listen");
          onData(Uint8List.fromList(bytes));
          
          idleTimer.renew();
        }, onError: (e, s) {
          if(cOnClose.isCompleted)
            return;
          cOnClose.completeError(e, s);
        },
        onDone: () {
          if(cOnClose.isCompleted)
            return;
          cOnClose.complete(true);
        }));
        //----------------------------------------------------------------------

        result = await cOnClose.future;
        idleTimer.cancel();
        receiveTimer.cancel();
        break;
      } closed = true;
      
    } catch(e, s) {
      lastError = e;
      stacktrace = s;
    } if(!cOnClose.isCompleted)
      cOnClose.complete(false);
    return result;
  }

  @override
  HttpRequestResult json(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      bool debugIgnoreCertificate = false,
      String debugProxy = "",
  }) {
    var reqResult = _rawRequest<NeonJsonObject>(
      timeouts,
      method,
      uri,
      headers,
      onData: (data) {},
      debugIgnoreCertificate: debugIgnoreCertificate,
      debugProxy: debugProxy,
    ) as _HttpRequestResultImpl;
    
    reqResult.onComplete.bind((result) {
      try {
        String data = Convert.utf8.decoder.convert(reqResult.data);
        reqResult.result = NeonJsonObject.fromJson(data);
      } catch(e, s) {
        reqResult.responseIncorrectState.value = true;
        reqResult.error = e;
        reqResult.stackTrace = s;
      }
    });
    return reqResult;
  }


  HttpRequestResult _rawRequest<T>(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      required HttpOnDataFunction onData,
      bool debugIgnoreCertificate = false,
      String debugProxy = "",
  }) {
    var timings = new HttpNetworkTimes();
    var reqResult = new _HttpRequestResultImpl<T>(timings: timings);
    
    Future(() async {
      List<int> received = [];
      var result = await raw(
        timeouts,
        method,
        uri,
        headers,
        onHeader: (statusCode, headers) {
          reqResult.statusCode = statusCode;
          reqResult.headers = headers;
        },
        onData: (data) {
          received.addAll(data);
          onData(data);
        },
        debugIgnoreCertificate: debugIgnoreCertificate,
        debugProxy: debugProxy,
      );
      reqResult.data = new Uint8List.fromList(received);
      reqResult.onComplete.value = result;
    });
    return reqResult;
  }



  static Future<HttpClientRequest> switchMethod(
    HttpClient client,
    Uri url,
    HttpMethod method,
  ) {
    switch(method) {
      case HttpMethod.HEAD:
        return client.headUrl(url);
      case HttpMethod.GET:
        return client.getUrl(url);
      case HttpMethod.POST:
        return client.postUrl(url);
      case HttpMethod.PUT:
        return client.putUrl(url);
      case HttpMethod.DELETE:
        return client.deleteUrl(url);
      case HttpMethod.OPTIONS:
        return client.openUrl("OPTIONS", url);
    }
  }

  // static Future<bool> _waitForSubscription(StreamSubscription sub) {
  //   var completer = new Completer<bool>();
  //   sub.onDone(() => completer.complete(true));
  //   sub.onError((Object error, StackTrace stackTrace) => completer.completeError(false));
  //   return completer.future;
  // }
}