import 'dart:async';

import 'package:flutter/material.dart';
import 'package:senses/components/primary_button.dart';
import 'package:senses/constants.dart';
import 'package:senses/classes/model.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? _filePath;
  List<Map<String, dynamic>> predictions = [];
  String? currentJobId;
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    if (await _requestMicrophonePermission()) {
      await _recorder.openRecorder();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content:
            const Text('Microphone permission is required to record audio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    if (await _requestMicrophonePermission()) {
      setState(() {
        isRecording = true;
      });
      _recordInChunks();
    }
  }

  Future<void> _recordInChunks() async {
    while (isRecording) {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(toFile: filePath);

      // Wait for 4 seconds before stopping the recorder
      await Future.delayed(const Duration(seconds: 4));
      await _recorder.stopRecorder();

      // Upload the audio file in the background
      _uploadAudioFile(File(filePath));
    }
  }

  Future<void> _uploadAudioFile(File audioFile) async {
    final uri = Uri.parse(
      // 'https://4tnwcv11y4.execute-api.ap-south-1.amazonaws.com/predict?job_id=${currentJobId}',
        'http://192.168.8.183:5000/upload'
    );

    var request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('file', audioFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        _handleResponse(jsonData);
      } else {
        print('Failed to upload audio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }

  void _handleResponse(Map<String, dynamic> data) {
    if (data['status'] == 'success') {
      final displayData = {
        'name': data['display_names_for_training_classes']['display_name'],
        'icon': data['display_names_for_training_classes']['icon'],
        'color': data['display_names_for_training_classes']['color'],
      };

      setState(() {
        predictions.add(displayData);
      });
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      isRecording = false;
    });
    await _recorder.stopRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

// Formats recording time
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
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
                            isRecording
                                ? "Recording: ${_formatDuration(_duration)}"
                                : _filePath != null
                                    ? "Recorded: ${_formatDuration(_duration)}"
                                    : "Tap Mic button to Record",
                            style: kSubHeadingTextStyle,
                          ),
                          PrimaryButton(
                              title: isRecording
                                  ? "Stop Recording"
                                  : "Start Recording",
                              process: isRecording
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
