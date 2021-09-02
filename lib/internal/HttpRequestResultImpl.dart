part of neonday_http_ex;

class _HttpRequestResultImpl<T> extends HttpRequestResult<T> {
  @override
  final NetworkTimes timings;

  @override
  final Notifier<bool> connectedState = new Notifier(value: false);

  @override
  final Notifier<bool> protoDoneState = new Notifier(value: false);

  @override
  final Notifier<bool> responseIncorrectState = new Notifier(value: false);

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