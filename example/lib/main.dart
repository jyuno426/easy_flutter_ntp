import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:easy_ntp_client/easy_ntp_client.dart' as ntp;

import 'src/materials/loading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Time Sync Demo using NTP',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Colors.white,
            backgroundColor: Colors.lightGreen,
            textStyle: TextStyle(fontSize: 24),
          ),
        ),
        primaryTextTheme: TextTheme(),
      ),
      home: MyHomePage(title: '오디오 가이드 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String message = '';
  String loadingMessage = '';
  AudioPlayer player;
  int ntpOffset;
  int serverNTP;
  int serverSync;
  int mediaNumber;
  bool isPlaying;
  bool isLoading;
  Timer timer;
  int customOffset;

  void initState() {
    super.initState();
    asyncInitState();
    subscribe();
  }

  void asyncInitState() async {
    setState(() {
      player = AudioPlayer();
      isPlaying = false;
      loadingMessage = "동기화 중 입니다. 잠시만 기다려주세요.";
      isLoading = true;
      customOffset = 100;
    });
    int res = await ntp.getNtpOffset();
    setState(() {
      ntpOffset = res;
      message = "미디어 번호를 골라주세요.";
      isLoading = false;
    });
  }

  void subscribe() {
    player.playerStateStream.listen((state) {
      print("state changed");
      print(state.playing ? "playing" : "not playing");
      switch (state.processingState) {
        case ProcessingState.idle:
          print("idle");
          break;
        case ProcessingState.loading:
          print("loading");
          break;
        case ProcessingState.buffering:
          print("buffering");
          break;
        case ProcessingState.ready:
          print("ready");
          break;
        case ProcessingState.completed:
          print("completed");
          pauseAudio();
        // if (state.playing) {
        //   setState(() {
        //     message = "Restarting audio ...";
        //   });
        //   player.seek(Duration.zero).then((_) {
        //     setState(() {
        //       message = "Playing back media $mediaNumber";
        //     });
        //   });
        // }
        // break;
      }
    });
  }

  Function onButtonPressed(number) {
    return () async {
      print(mediaNumber);
      print(number);
      bool prepare = (number != mediaNumber ||
          player.processingState == ProcessingState.completed);

      pauseAudio();

      setState(() {
        mediaNumber = number;
        loadingMessage = "$number번 미디어를 불러오는 중 입니다.";
        isLoading = true;
      });
      await Future.delayed(Duration(seconds: 1));
      if (prepare) await synchronize();
      await prepareAudio();
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        message = "$number번 미디어가 선택되었습니다.";
        isLoading = false;
      });
      playAudio();
    };
  }

  Future<void> synchronize() async {
    print("synchronize");
    var serverData = await _getServerSyncAndNTP(mediaNumber);

    // print("offset");
    // print(serverData['ntp'] - serverData['sync'] - 1613543420000);

    setState(() {
      serverNTP = serverData['ntp'].toInt();
      serverSync = serverData['sync'].toInt();
    });
  }

  Future<void> prepareAudio() async {
    String filename =
        'assets/audio_${mediaNumber.toString().padLeft(2, '0')}.mp3';
    print(filename);

    await player.setVolume(0);
    await player.setAsset(
      filename,
      initialPosition: Duration(milliseconds: getSync()),
    );
    // await player.setUrl(
    //   'http://115.144.82.214:3000/audio/$mediaNumber',
    //   initialPosition: Duration(milliseconds: getSync()),
    // );

    // print(player.sequence);

    print("wait until ready");
    await player.playerStateStream
        .firstWhere((e) => e.processingState == ProcessingState.ready);

    print("reached ready");
  }

  int getSync() {
    double offset = getClientNTP(ntpOffset) - serverNTP;
    double syncFinal = serverSync + offset;
    return syncFinal.toInt();
  }

  void playAudio() async {
    setState(() {
      isLoading = true;
      loadingMessage = "로딩중";
    });
    //
    // print("current index: ${player.currentIndex}");
    // print("all sequences: ${player.sequence}");
    //
    // await Future.delayed(Duration(seconds: 2));
    //
    player.play();
    await player.seek(Duration(milliseconds: getSync())).then((_) async {
      print("seek complete");

      await Future.delayed(Duration(seconds: 3));

      timer = Timer.periodic(Duration(milliseconds: 17), (_) {
        int position = player.position.inMilliseconds;
        // int syncOffset = position - getSync();
        // setState(() {
        //   message = "Sync Offset: $syncOffset";
        // });
        // print("syncOffset: $syncOffset");
        double cur = position * 0.001;
        setState(() {
          message = "$mediaNumber번 재생중 ${cur.toStringAsFixed(2)}";
        });
      });

      setState(() {
        isPlaying = true;
        isLoading = false;
      });

      int step = 60;
      int count = 20;

      double volX = -0.5 * pi;
      Timer volumeTimer = Timer.periodic(Duration(milliseconds: step), (timer) {
        volX += pi / count;
        player.setVolume(0.5 * (1 + sin(volX)));
      });
      await Future.delayed(Duration(milliseconds: step * count + 100));
      volumeTimer.cancel();
    }).catchError((e) {
      print(e);
    });
  }

  void pauseAudio() async {
    setState(() {
      isPlaying = false;
    });
    if (timer != null) timer.cancel();
    await player.setVolume(0);
    await player.pause();
  }

  Widget buildBody() {
    Widget buttonGrid() {
      Widget myButton(int number) {
        return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: TextButton(
              child: Text(number.toString(), style: TextStyle(fontSize: 30)),
              onPressed: onButtonPressed(number),
            ));
      }

      return SingleChildScrollView(
          child: Column(children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [1, 2, 3, 4].map((e) => myButton(e)).toList(),
        )
      ]));
    }

    if (isLoading) {
      return DefaultLoading(text1: loadingMessage);
    } else {
      return Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              child: buttonGrid(),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Text(message, style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      );
    }
  }

  Widget buildFloatingButton() {
    if (isLoading) {
      return null;
    } else {
      return FloatingActionButton(
        onPressed: () {
          if (isPlaying) {
            pauseAudio();
          } else {
            playAudio();
          }
        },
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      ),
      body: buildBody(),
      floatingActionButton: buildFloatingButton(),
    );
  }

  @override
  void dispose() async {
    await player.pause();
    await player.dispose();
    timer.cancel();
    super.dispose();
  }
}

Future<Map<String, dynamic>> _getServerSyncAndNTP(int number) async {
  final response = await http.get('http://115.144.82.214:3000/getsync/$number');

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, then parse the JSON.
    return jsonDecode(response.body);
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to fetch sync');
  }
}

double getClientNTP(int ntpOffset) {
  DateTime localTime = new DateTime.now();
  DateTime ntpTime = localTime.add(Duration(milliseconds: ntpOffset));
  return ntpTime.millisecondsSinceEpoch + .0;
}
