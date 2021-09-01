part of dev.neonday.libs.http_ex;

abstract class IResponseEx<T> {
  /// connection successful ? true : false
  bool    get connected;

  /// protocol done ? true : false
  /// 
  /// Example:
  ///   - http: (statusCode >= 200 && statusCode <= 299) ? true : false
  bool    get protoDone;

  /// response received ? true : false
  bool    get hasResponse;

  /// response correct ? true : false
  /// 
  /// Example:
  ///   - we are waiting for JSON,
  ///     but received something else(XML..) - false, otherwise true
  bool    get isResponseCorrect;

  /// api successfully ? true : false
  /// 
  /// Example:
  ///   - JSON: `{"error":"Wrong login or password"} or {"response":{"access_token":"abcdef"}}`
  bool    get isApiDone;

  /// true if everything is ok
  bool    get isDone;

  /// status of received data
  /// 
  /// Example:
  /// - http: 200 or 404
  int?    get statusCode;

  /// received data
  T?      get data;

  /// errors encountered when requesting
  List<IError> get errors;

  void copyTo(ResponseEx response);
}


class IError {
  final Object error;
  final StackTrace stackTrace;
  const IError(this.error, this.stackTrace);
}

class ResponseEx<T> extends IResponseEx<T> {
  @override
  bool connected    = false;

  @override
  bool protoDone    = false;

  @override
  bool hasResponse        = false;

  @override
  bool isResponseCorrect  = false;

  @override
  bool isApiDone          = false;

  @override
  bool get isDone         =>
    connected && protoDone && hasResponse && isResponseCorrect && isApiDone;


  @override
  int? statusCode;

  @override
  T? data;

  @override
  List<IError> errors = [];

  @override
  void copyTo(ResponseEx response) {
    response.connected   = connected;
    response.protoDone    = protoDone;
    response.hasResponse  = hasResponse;
    response.isResponseCorrect  = isResponseCorrect;
    response.isApiDone    = isApiDone;
    response.statusCode   = statusCode;
    response.errors.addAll(errors);
  }






  // bool    _connection;
  // bool    _protoDone;
  // bool    _hasResponse;
  // bool    _isResponseCorrect;
  // bool    _isApiDone;

  // int     _statusCode;

  // T       _data;
  
  // List<Object>  _errors;


  // @override
  // bool get connection         => _connection;

  // @override
  // bool get protoDone          => _protoDone;

  // @override
  // bool get hasResponse        => _hasResponse;

  // @override
  // bool get isResponseCorrect  => _isResponseCorrect;

  // @override
  // bool get isApiDone          => _isApiDone;


  // @override
  // int get statusCode          => _statusCode;

  // @override
  // T get data                  => _data;

  // @override
  // List<Object> get errors     => _errors;
}


// abstract class IResponse<T> {
//   //----------------------------------------------------------------------------
//   ///Is connection successful ? true : false
//   static const int STATUS_TYPE_CONNECTION       = 1;

//   ///Is http-result ok ? true : false
//   static const int STATUS_TYPE_PROTO            = 2;

//   ///Is response received ? true : false
//   static const int STATUS_TYPE_RESPONSE         = 3;

//   ///Is response correct ? true : false
//   static const int STATUS_TYPE_RESPONSE_CORRECT = 4;

//   ///Is API error ? true : false
//   static const int STATUS_TYPE_RESPONSE_API     = 5;


//   static const int RESULT_OK                  = 0;
//   static const int RESULT_ERROR               = 1;


//   static const int RESULT_CONNECTION_DONE         = RESULT_OK;
//   static const int RESULT_CONNECTION_ERROR        = RESULT_ERROR;


//   static const int RESULT_RESPONSE_DONE           = RESULT_OK;
//   static const int RESULT_RESPONSE_ERROR          = RESULT_ERROR;

//   static const int RESULT_RESPONSE_CORRECT_DONE   = RESULT_OK;
//   static const int RESULT_RESPONSE_CORRECT_ERROR  = RESULT_ERROR;

//   static const int RESULT_RESPONSE_API_DONE       = RESULT_OK;
//   static const int RESULT_RESPONSE_API_ERROR      = RESULT_ERROR;
//   //----------------------------------------------------------------------------




//   bool _bConnection     = false;
//   bool _bProtoDone      = false;
//   bool _hasResponse;
//   bool _bResponseCorrect;
//   bool _bResponseApi;

//   int _statusCode       = 0;

//   T _data;



//   bool isConnected()          { return _bConnection       ?? false; }
//   bool isProtoDone()          { return _bProtoDone        ?? false; }
//   bool hasResponse()          { return _hasResponse       ?? false; }
//   bool isResponseCorrect()    { return _bResponseCorrect  ?? false; }
//   bool isApiDone()            { return _bResponseApi      ?? false; }
//   bool isDone()               {
//     if(!_bConnection)
//       return false;
//     if(!_bProtoDone)
//       return false;
//     if(!_returnTrueIfNull(_hasResponse))
//       return false;
//     if(!_returnTrueIfNull(_bResponseCorrect))
//       return false;
//     if(!_returnTrueIfNull(_bResponseApi))
//       return false;
//     return true;
//   }

//   ///returns Http status code 
//   int statusCode()  { return _statusCode; }

//   T data()      { return _data; }




//   bool _returnTrueIfNull(bool v) {
//     if(v == null)
//       return true;
//     return v;
//   }
// }




// class _Response<T> extends IResponse<T> {}



// class ResponseBuilder<T> {
//   IResponse<T> _response = new _Response<T>();
//   ResponseBuilder();
//   ResponseBuilder<T> setStatus(int type, int code) {
//     switch(type) {
//       case IResponse.STATUS_TYPE_CONNECTION:
//         if(code == IResponse.RESULT_CONNECTION_DONE)
//           _response._bConnection = true;
//         else _response._bConnection = false;
//         break;

//       case IResponse.STATUS_TYPE_PROTO:
//         if(code == IResponse.RESULT_OK)
//           _response._bProtoDone = true;
//         else _response._bProtoDone = false;
//         break;

//       case IResponse.STATUS_TYPE_RESPONSE:
//         if(code == IResponse.RESULT_RESPONSE_DONE)
//           _response._hasResponse = true;
//         else _response._hasResponse = false;
//         break;

//       case IResponse.STATUS_TYPE_RESPONSE_CORRECT:
//         if(code == IResponse.RESULT_RESPONSE_CORRECT_DONE)
//           _response._bResponseCorrect = true;
//         else _response._bResponseCorrect = false;
//         break;
        
//       case IResponse.STATUS_TYPE_RESPONSE_API:
//         if(code == IResponse.RESULT_RESPONSE_API_DONE)
//           _response._bResponseApi = true;
//         else _response._bResponseApi = false;
//         break;
//       default: throw(new Exception("Unknown type"));
//     } return this;
//   }

//   ResponseBuilder<T> setStatusCode(int code) { _response._statusCode = code; return this; }
//   ResponseBuilder<T> setData(T data)      { _response._data = data; return this; }


//   IResponse<T> response() { return _response; }
//   IResponse<T> build() {
//     while(true) {
//       if(!_response._bConnection) {
//         _response._bProtoDone         = false;
//         _response._bResponseApi       = false;
//         _response._bResponseCorrect   = false;
//         break;
//       }

//       // if(_response._bProtoDone == null) {
//       //   if(_response._bResponseCorrect == null) {
//       //     if(_response.
//       //   }
//       // }

//       break;
//     }
//     return _response;
//   }


//   ///returns same object without next values:
//   /// - response()
//   static ResponseBuilder<OUT> from<OUT>(IResponse res) {
//     ResponseBuilder<OUT> out = new ResponseBuilder();
//     out._response._bConnection          = res._bConnection;
//     out._response._bProtoDone           = res._bProtoDone;
//     out._response._hasResponse          = res._hasResponse;
//     out._response._bResponseCorrect     = res._bResponseCorrect;
//     out._response._bResponseApi         = res._bResponseApi;
//     out._response._statusCode           = res._statusCode;
//     // out._response._data                 = res._data;
//     return out;
//   }
// }