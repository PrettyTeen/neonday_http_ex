part of neonday_http_ex;

class _HttpRequestResultImpl<T> extends HttpRequestResult<T> {
  @override
  final NetworkTimes timings;

  @override
  bool get connected          => connectedState.value!;

  @override
  bool get protoDone          => protoDoneState.value!;

  @override
  bool get incorrectResponse  => incorrectResponseState.value!;

  @override
  bool get apiDone            => apiDoneState.value!;



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
  late Uint8List data;

  @override
  T? result;

  _HttpRequestResultImpl({
    required this.timings,
  });


  @override
  final Notifier<bool> onComplete   = new Notifier();

  @override
  Future<bool> waitForComplete()
    => onComplete.value == null ? onComplete.asFuture() : Future.value(onComplete.value);
}