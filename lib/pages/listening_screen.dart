import 'dart:async';

import 'package:flutter/material.dart';
import 'package:senses/components/primary_button.dart';
import 'package:senses/constants.dart';
import 'package:senses/classes/model.dart';
import 'dart:io';
import 'dart:convert';
// import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

class ListeningScreen extends StatefulWidget {
  // final Model selectedModel;

  const ListeningScreen({
    super.key,
    // required this.selectedModel,
  });

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  // final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _filePath;
  List<Map<String, dynamic>> predictions = [];
  String? currentJobId;
  Timer? _timer;
  Duration _duration = Duration.zero;

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    // await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    // Directory tempDir = await getTemporaryDirectory();
    // _filePath = '${tempDir.path}/audio.wav';
    // await _recorder.startRecorder(toFile: _filePath, codec: Codec.pcm16WAV);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    // await _recorder.stopRecorder();
    setState(() => _isRecording = false);
    if (_filePath != null) {
      await _uploadAudio(_filePath!);
    }
  }

  Future<void> _uploadAudio(String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://4tnwcv11y4.execute-api.ap-south-1.amazonaws.com/predict?job_id=$currentJobId'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('audio_file', filePath));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      _handlePredictionResponse(responseData);
    } else {
      print('Failed to upload audio: ${response.statusCode}');
    }
  }

  void _handlePredictionResponse(String responseData) {
    final data = jsonDecode(responseData);
    if (data['status'] == 'success') {
      predictions.add({
        'display_name': data['display_names_for_training_classes']
            ['display_name'],
        'icon': data['display_names_for_training_classes']['icon'],
        'color': data['display_names_for_training_classes']['color'],
      });
      setState(() {});
    } else {
      print('Failed to get predictions');
    }
  }

  // Starts counting time
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

  @override
  void dispose() {
    // _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // currentJobId = widget.selectedModel.jobId;
    _initializeRecorder();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Communication Analyzer",
            style: kSubHeadingTextStyle,
          ),
          elevation: 4.0,
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
        body: Center(
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/background/noise_image.webp'),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kDarkGreyColor, // Border color
                        width: 1.0, // Border width
                      ),
                      borderRadius:
                          BorderRadius.circular(12), // Border radius (optional)
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _isRecording
                                ? "Recording: ${_formatDuration(_duration)}"
                                : _filePath != null
                                    ? "Recorded: ${_formatDuration(_duration)}"
                                    : "Tap Mic button to Record",
                            style: kSubHeadingTextStyle,
                          ),
                          PrimaryButton(
                              title: _isRecording
                                  ? "Stop Recording"
                                  : "Start Recording",
                              process: _isRecording
                                  ? _stopRecording
                                  : _startRecording),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
