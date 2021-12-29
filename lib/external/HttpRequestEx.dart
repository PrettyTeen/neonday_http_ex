part of truecollaboration_http_ex;

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
  bool    debugIgnoreCertificate = false;

  String  debugProxy = "";

  Object?     get lastError;
  StackTrace? get stacktrace;

  bool        get requesting;
  bool        get closed;

  /// [input] can be Stream<Uint8List>, Uint8List
  Future<bool> raw(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      Object? input,
      required HttpOnHeaderFunction onHeader,
      required HttpOnDataFunction onData,
  });

  HttpRequestResult<void> parsedRaw(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      Object? input,
      required HttpOnDataFunction onData,
  });

  HttpRequestResult<T> json<T extends INeonJson>(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      Object? input,
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
  bool debugIgnoreCertificate = false;

  @override
  String debugProxy = "";


  
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
      Object? input,
      required HttpOnHeaderFunction onHeader,
      required HttpOnDataFunction onData,
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

    

    late HttpClientRequest httpRequest;
    late HttpClientResponse httpResponse;

    final NotifierStorage streamListener = new NotifierStorage();

    RenewableTimer idleTimer, receiveTimer;
    TimedTask task;
    bool timeouted = false;

    Profiler profiler = new Profiler();

    StreamController<Uint8List> inputStream = new StreamController();
    int contentLength = -1;
    while(true) {
      try {
        if(input is Uint8List)
          contentLength = input.length;
        




        // SENDING HEADERS
        //----------------------------------------------------------------------
        profiler.start();
        task = new TimedTask(timeouts.connection, Future(() async {
          httpRequest = await switchMethod(client, uri, method);
        }));
        timeouted = (await task.run(false, true))!;
        if(timeouted || closed) {
          lastError = new TimeoutException("NetworkTimeouts.connection", timeouts.connection);
          stacktrace = StackTrace.current;
          break;
        } timings?.connection = new Duration(milliseconds: profiler.time(TimeUnits.MILLISECONDS));

        headers.forEach((name, value) {
          httpRequest.headers.set(name, value);
        });
        httpRequest.contentLength = contentLength;
        //----------------------------------------------------------------------


        // SENDING BODY
        //----------------------------------------------------------------------
        timings?.beginRequest = new Duration(milliseconds: profiler.time(TimeUnits.MILLISECONDS));
        if(input != null) {
          if(input is Stream<Uint8List>) {
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
          } else if(input is Uint8List) {
            httpRequest.add(input);
          } else {
            lastError = new Exception("Unkown input type ${input.runtimeType}");
            stacktrace = StackTrace.current;
            break;
          } 
        }
        //----------------------------------------------------------------------
        
        

        // WAITING FOR SERVER RESPONSE
        //----------------------------------------------------------------------
        task = new TimedTask(timeouts.response, Future(() async {
          httpResponse = await httpRequest.close();
        }));
        timeouted = (await task.run(false, true))!;
        if(timeouted || closed) {
          lastError = new TimeoutException("NetworkTimeouts.response", timeouts.response);
          stacktrace = StackTrace.current;
          break;
        } timings?.beginResponse = new Duration(milliseconds: profiler.time(TimeUnits.MILLISECONDS));
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
        onHeader(httpRequest, httpResponse, httpResponse.statusCode, HttpConverter.httpHeaders2Map(httpResponse.headers));
        
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
        timings?.close = new Duration(milliseconds: profiler.time(TimeUnits.MILLISECONDS));
        idleTimer.cancel();
        receiveTimer.cancel();
        break;
      } catch(e, s) {
        lastError = e;
        stacktrace = s;
      } break;
    } inputStream.close();
    closed = true;
    if(!cOnClose.isCompleted)
      cOnClose.complete(false);
    return result;
  }

  @override
  HttpRequestResult<void> parsedRaw(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      Object? input,
      required HttpOnDataFunction onData,
  }) {
    var reqResult = _rawRequest<void>(
      timeouts,
      method,
      uri,
      headers,
      input: input,
      onData: onData,
    ) as HttpRequestResultImpl<void>;
    return reqResult;
  }

  @override
  HttpRequestResult<T> json<T extends INeonJson>(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      Object? input,
  }) {
    final List<int> received = [];
    var reqResult = _rawRequest<T>(
      timeouts,
      method,
      uri,
      headers,
      timings: timings,
      input: input,
      onData: (chunk) => received.addAll(chunk),
    ) as HttpRequestResultImpl<T>;
    
    var stacktrace = StackTrace.current;
    reqResult.onComplete.bind((result) {
      if(!result!)
        return;
      bool unknownImplementation = false;
      try {
        String data = Convert.utf8.decoder.convert(received);
        if(T == NeonJsonObject)
          reqResult.response = NeonJsonObject.fromJson(data) as T;
        else if(T == NeonJsonArray)
          reqResult.response = NeonJsonArray.fromJson(data) as T;
        else {
          unknownImplementation = true;
          throw(new Exception("Unknown implementation of INeonJson"));
        }
      } catch(e, s) {
        reqResult.incorrectResponseState.value = true;
        reqResult.error = e;
        reqResult.stackTrace = unknownImplementation ? stacktrace : s;
      }
    });
    return reqResult;
  }























  HttpRequestResult<T> _rawRequest<T>(
    NetworkTimeouts timeouts,
    HttpMethod method,
    Uri uri,
    Map<String, String> headers, {
      NetworkTimes? timings,
      Object? input,
      required HttpOnDataFunction onData,
  }) {
    var _timings = timings ?? new HttpNetworkTimes();
    var reqResult = new HttpRequestResultImpl<T>(timings: _timings);
    
    Future(() async {
      var result = await raw(
        timeouts,
        method,
        uri,
        headers,
        timings: _timings,
        input: input,
        onHeader: (rawRequest, rawResponse, statusCode, headers) {
          reqResult.rawRequest = rawRequest;
          reqResult.rawResponse = rawResponse;
          
          reqResult.protoDoneState.value = true;
          reqResult.statusCode = statusCode;
          reqResult.headers = headers;
        },
        onData: (data) {
          onData(data);
        },
      );
      reqResult.connectedState.value = _timings.connection != null;
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