part of truecollaboration_http_ex;

class HttpRequestResultImpl<T> extends HttpRequestResult<T> {
  @override
  final NetworkTimes timings;

  @override
  bool get connected          => connectedState.value;

  @override
  bool get protoDone          => protoDoneState.value;

  @override
  bool get incorrectResponse  => incorrectResponseState.value;

  @override
  bool get apiDone            => apiDoneState.value;



  @override
  final Notifier<bool> connectedState = new Notifier(value: false);

  @override
  final Notifier<bool> protoDoneState = new Notifier(value: false);

  @override
  final Notifier<bool> incorrectResponseState = new Notifier(value: false);

  @override
  final Notifier<bool> apiDoneState   = new Notifier(value: false);
  


  @override
  int? statusCode;

  @override
  Map<String, String>? headers;

  @override
  Uint8List? rawData;

  @override
  T? response;

  HttpRequestResultImpl({
    required this.timings,
  });


  @override
  final Notifier<bool?> onComplete   = new Notifier(value: null);

  @override
  Future<bool> waitForComplete() async {
    if(onComplete.value == null)
      return (await onComplete.asFuture())!;
    return Future.value(onComplete.value);
  }
}