library easy_ntp_client;

import 'dart:math';
import 'package:ntp/ntp.dart';

String formatTime(DateTime time) {
  return time.toIso8601String().substring(11, 22);
}

Future<int> getNtpOffset({int attemptNum = 10}) async {
  List<int> offsetList = [], res;
  int garbage = 10;


  print("haha");

  int count = 0;
  while (count < attemptNum + garbage) {
    try {
      offsetList.add(await NTP.getNtpOffset(
        localTime: DateTime.now(),
        timeout: Duration(milliseconds: 300),
      ));
      count++;
      print(count);
    } catch (e) {
      print(e);
    }
  }

  print("get ntp offset done");
  print(offsetList);
  // offsetList.sort();
  // print("sort");
  // print(offsetList);

  res = offsetList.sublist(garbage);
  print(res);

  // if (offsetList.length >= 10) {
  //   int trim = (offsetList.length * 0.2).toInt();
  //   res = offsetList.sublist(trim, offsetList.length - trim);
  // } else {
  //   res = offsetList;
  // }

  return res.reduce((a, b) => a + b) ~/ res.length;

  // return offsetList.reduce(min);
  // return offsetList.reduce((a, b) => a + b) ~/ offsetList.length;
}
