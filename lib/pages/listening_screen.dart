import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class AudioUploader extends StatefulWidget {
  @override
  _AudioUploaderState createState() => _AudioUploaderState();
}

class _AudioUploaderState extends State<AudioUploader> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  List<String> _displayNames = [];
  final String _awsEndpoint =
      'https://4tnwcv11y4.execute-api.ap-south-1.amazonaws.com/predict?job_id=420297i39v92930'
      // 'https://4tnwcv11y4.execute-api.ap-south-1.amazonaws.com/predict?job_id=420297i39v92930'
  ;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();

    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(Duration(milliseconds: 500));
  }

  Future<String> _getTemporaryDirectoryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<void> _startRecording() async {
    if (!_recorder.isRecording) {
      _isRecording = true;
      setState(() {});

      // Start the first recording chunk
      _recordChunk();
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder.isRecording) {
      _isRecording = false;
      await _recorder.stopRecorder();
      setState(() {});
    }
  }

  Future<void> _recordChunk() async {
    while (_isRecording) {
      final recordingPath = '${await _getTemporaryDirectoryPath()}/chunk_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: recordingPath,
        codec: Codec.pcm16WAV,
      );

      // Wait for 10 seconds before stopping the recorder
      await Future.delayed(Duration(seconds: 10));

      // Stop the recording
      await _recorder.stopRecorder();

      // Log the file path and check its existence
      final audioFile = File(recordingPath);
      print('Recording saved at: ${audioFile.path}');
      print('File exists: ${audioFile.existsSync()}');

      // Upload the recorded chunk
      _uploadAudio(audioFile);
    }
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
        'audio_file',  // This is the name the API expects
        audioFile.path,
        // contentType: MediaType('audio', 'wav'),  // Explicitly mention content type
      ));

      // Log that request is being sent
      print('Sending request to $_awsEndpoint with audio file ${audioFile.path}');

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Log response for debugging
      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data['status'] == 'success') {
          final displayName = data['display_names_for_training_classes']['display_name'];
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sound Classification')),
      body: Column(
        children: [
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _displayNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_displayNames[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
