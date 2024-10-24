import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:senses/components/primary_button.dart';
import 'package:senses/components/response_tile.dart';
import 'package:senses/constants.dart';
import 'package:senses/classes/responses.dart';

class AudioUploader extends StatefulWidget {
  @override
  _AudioUploaderState createState() => _AudioUploaderState();
}

class _AudioUploaderState extends State<AudioUploader> {
  // final RecorderController _recorderController = RecorderController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  List<String> _displayNames = [];
  final String _awsEndpoint =
      // 'https://4tnwcv11y4.execute-api.ap-south-1.amazonaws.com/predict?job_id=420297i39v92930'
      'http://192.168.8.101:5000/upload';
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    // _recorderController.start();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = Duration(seconds: _duration.inSeconds + 1);
      });
    });
  }

// Stops counting time
  void _stopTimer() {
    _timer?.cancel();
  }

// Formats recording time
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();

    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future<String> _getTemporaryDirectoryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<void> _startRecording() async {
    if (!_recorder.isRecording) {
      _isRecording = true;
      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
      });
      _startTimer();

      // Start the first recording chunk
      _recordChunk();
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      _stopTimer();
    }
  }

  Future<void> _recordChunk() async {
    while (_isRecording) {
      final recordingPath =
          '${await _getDocumentsDirectoryPath()}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: recordingPath,
        codec: Codec.pcm16WAV,
      );

      await Future.delayed(
          const Duration(seconds: 10)); // Record for 10 seconds

      await _recorder.stopRecorder();

      final audioFile = File(recordingPath);
      print('Recording saved at: ${audioFile.path}');
      print('File exists: ${audioFile.existsSync()}');

      // Upload the recorded chunk
      _uploadAudio(audioFile);
    }
  }

  Future<String> _getDocumentsDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _uploadAudio(File audioFile) async {
    try {
      final uri = Uri.parse(_awsEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Make sure the file path is correct and check if the file exists
      print('Uploading file: ${audioFile.path}');
      print('File exists: ${audioFile.existsSync()}');

      // Add audio file to request
      request.files.add(await http.MultipartFile.fromPath(
        'file', // This is the name the API expects
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
      ));

      // Log that request is being sent
      print(
          'Sending request to $_awsEndpoint with audio file ${audioFile.path}');

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Log response for debugging
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data['status'] == 'success') {
          final displayName =
              data['display_names_for_training_classes']['display_name'];
          setState(() {
            _displayNames.add(displayName);
          });
        } else {
          print('Error from API: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    // _recorderController.stop();
    // _recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Communication Analyzer',
          style: kSubHeadingTextStyle.copyWith(color: kDeepBlueColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.navigate_before,
            color: kDeepBlueColor,
          ),
        ),
        flexibleSpace: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background/noise_image.webp',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/images/background/noise_image.webp'),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: kOceanBlueColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _isRecording
                                  ? "Listening: ${_formatDuration(_duration)}"
                                  : "Tap on Start",
                              style: kSubHeadingTextStyle,
                            ),
                          ),
                          PrimaryButton(
                            process:
                                _isRecording ? _stopRecording : _startRecording,
                            title: _isRecording ? 'Stop' : 'Start',
                            color: _isRecording?kWarningRedColor:kSuccessGreenColor,
                            screenWidth: width / 3,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Image(
                          image: AssetImage(_isRecording
                              ? "assets/gif/recording.webp"
                              : "assets/gif/not_recording.webp"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Listen to your surrounding\'s Melody',
                style: kSubTitleTextStyle,
              ),
            ),
            Expanded(
              flex: 3,
              child: ListView.builder(
                itemCount: responses.length,
                itemBuilder: (context, index) {
                  final tileData = responses[index];
                  return  ResponseTile(
                    title: tileData["title"]!,
                    iconName: tileData["iconName"]!,
                    hexColor: tileData["hexColor"]!,
                    accuracy: tileData["accuracy"]!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
