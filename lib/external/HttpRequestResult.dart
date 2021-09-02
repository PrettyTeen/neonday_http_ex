part of neonday_http_ex;

abstract class HttpRequestResult<T> extends IRequestResult {
  @override
  bool get connected;

  bool get protoDone;

  bool get incorrectResponse;

  bool get apiDone;


  @override
  INotifier<bool> get connectedState;

  INotifier<bool> get protoDoneState;

  INotifier<bool> get incorrectResponseState;

  INotifier<bool> get apiDoneState;




  int? get statusCode;

  Map<String, String>? get headers;

  Uint8List get data;
  
  T? get result;


  Object? error;
  
  StackTrace? stackTrace;



  INotifier<bool> get onComplete;

  Future<bool> waitForComplete();
}