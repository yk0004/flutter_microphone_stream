import 'dart:convert';

import 'package:microphone_stream_example/.env/config.dart';

import 'package:flutter/material.dart';
import 'package:microphone_stream/microphone_stream.dart';
import 'package:googleapis/speech/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

final _credentials = new ServiceAccountCredentials.fromJson(config);

const _SCOPES = const [SpeechApi.CloudPlatformScope];

class Recorder extends StatefulWidget {
  static const String tag = 'RecorderScreen';

  @override
  _RecorderState createState() => _RecorderState();
}

class _RecorderState extends State<Recorder> {
  List<int> sampleData = List();
  var channel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void sampleSubscriber(List<int> samples) {
    sampleData.addAll(samples);
    print(sampleData.length);
    channel.sink.add(samples);
  }

  void startListening() {
    print('Starting to listen...');
    channel = IOWebSocketChannel.connect('ws://10.0.2.2:8000/');
    // channel = IOWebSocketChannel.connect('ws://13.234.92.107:5001/score');
    channel.stream.listen((msg) {
      debugPrint('socket ${json.decode(msg)}');
    }, onDone: () {
      print('socket done!!!!');
    });
    // var config = {
    //   "user_id": "5c6a13034b6f2f5f2f515b99",
    //   "document_id": "5ca5cca7fdad7696efcc4ca2",
    //   "chunk_id": "5ca5ccb3fdad766d36cc4ca3"
    // };

    var config = {"rate": 16000, "format": "LINEAR16", "language": "en-US"};
    channel.sink.add(json.encode(config));
    MicrophoneStream.addSubscriber(sampleSubscriber);
    MicrophoneStream.startListening();
  }

  void stopListening() {
    print('Not listening anymore');
    MicrophoneStream.removeSubscriber(sampleSubscriber);
    MicrophoneStream.stopListening();
    channel.sink.add('stop');
  }

  void saveRecording() async {
    final String path =
        await MicrophoneUtility.buildFilePath('recordings/sample.wav');
    WavCodec.encode(path, sampleData);
    print('Recording saved to $path');
  }

  // @override
  // void initState() {
  //   MicrophoneUtility.buildFilePath('dir1/dir2/dir3/test.txt').then((value) => print(value));
  //   super.initState();
  // }

  void _play() async {
    clientViaServiceAccount(_credentials, _SCOPES).then((http_client) {
      var speech = new SpeechApi(http_client);
      print(sampleData);
      final _json = {
        "audio": {"content": base64Encode(sampleData)},
        "config": {
          "encoding": "LINEAR16",
          "sampleRateHertz": 16000,
          "languageCode": "en-US"
        }
      };
      final _recognizeRequest = RecognizeRequest.fromJson(_json);
      speech.speech.recognize(_recognizeRequest).then((response) {
        for (var result in response.results) {
          print(result.toJson());
        }
      });
    });
  }

  Widget buildButton({String text, Function callback}) {
    return MaterialButton(
      minWidth: 200.0,
      height: 42.0,
      color: Colors.blue,
      child: Text(text),
      onPressed: callback,
    );
  }

  @override
  Widget build(BuildContext cxt) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Recorder'),
      ),
      body: ListView(
        children: [
          SizedBox(height: 15.0),
          buildButton(text: 'Start', callback: startListening),
          SizedBox(height: 15.0),
          buildButton(text: 'Stop', callback: stopListening),
          SizedBox(height: 15.0),
          buildButton(text: 'Save', callback: _play),
        ],
      ),
    );
  }
}
