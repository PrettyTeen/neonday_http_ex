part of neonday_http_ex;

abstract class HttpConverter {
  static const String TAG = "HttpConverter";
  
  /// Returns headers in lower-case
  static Map<String, String> httpHeaders2Map(HttpHeaders headers) {
    var map = new Map<String, String>();
    headers.forEach((name, values) {
      map[name.toLowerCase()] = values.join(",");
    });
    return map;
  }


  /// https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Range
  static HttpRange extractRange(String header, int defaultStart, int defaultEnd) {
    var ranges = extractRanges(header, defaultStart, defaultEnd);
    return ranges.length > 0 ? ranges[0] : new HttpRange(defaultStart, defaultEnd, -1);
  }

  static List<HttpRange> extractRanges(String header, int defaultStart, int defaultEnd) {
    List<String> sRanges;
    String sStart, sEnd;
    header = header.replaceFirst(RegExp("bytes="), "");

    sRanges = header.split(", ");

    List<HttpRange> ranges = [];

    for(var string in sRanges) {
      string.replaceAllMapped(RegExp("([0-9]*)-([0-9]*)"), (match) {
        for(int i = 1; i < match.groupCount + 1; i ++) {
          Logger.e(TAG, "extractRanges; match[$i] = ${match[i]}");
        } sStart = match.group(1) ?? "";
        sEnd = match.group(2) ?? "";
        ranges.add(new HttpRange(
          int.tryParse(sStart) ?? defaultStart,
          int.tryParse(sEnd) ?? defaultEnd,
          -1,
        ));
        return "";
      });
    } return ranges;
  }


  /// https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range
  static HttpRange extractContentRange(
    String? header,
    int defaultStart,
    int defaultEnd,
    int defaultTotal,
  ) {
    if(header == null)
      return new HttpRange(defaultStart, defaultEnd, defaultTotal);
    String? sStart, sEnd, sTotal;
    header = header.replaceFirst(RegExp("bytes "), "");

    header.replaceAllMapped(RegExp("(.*)/(.*)"), (m1) {
      // for(int i = 1; i < m1.groupCount + 1; i ++) {
      //   Log.e(TAG, "extractContentRange; match[$i] = ${m1[i]}");
      // }
      if((m1.group(1) ?? "") != "*") {
        m1.group(1)!.replaceAllMapped(RegExp("([0-9]*)-([0-9]*)"), (m2) {
          sStart = m2.group(1);
          sEnd = m2.group(2);
          return "";
        });
      } sTotal = m1.group(2)!;
      return "";
    });
    return new HttpRange(
      int.tryParse(sStart ?? "") ?? defaultStart,
      int.tryParse(sEnd ?? "") ?? defaultEnd,
      int.tryParse(sTotal ?? "") ?? defaultTotal,
    );
  }
}