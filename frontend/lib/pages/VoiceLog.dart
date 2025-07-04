import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceLog extends StatefulWidget {
  final Function(String) onResult;
  const VoiceLog({required this.onResult, Key? key}) : super(key: key);

  @override
  State<VoiceLog> createState() => _VoiceLogState();
}

class _VoiceLogState extends State<VoiceLog> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            if (val.hasConfidenceRating && val.confidence > 0.5) {
              widget.onResult(val.recognizedWords);
              _stopListening();
            }
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    } else {
      _stopListening();
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.red),
      onPressed: _listen,
  );
  }
}