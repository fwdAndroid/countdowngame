import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class CountdownScreen extends StatefulWidget {
  @override
  _CountdownScreenState createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  final TextEditingController _countdownController = TextEditingController(
    text: '50',
  );
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isCounting = false;
  bool _speechAvailable = false;
  bool _soundEnabled = true;

  int _currentCount = 0;

  Timer? _countdownTimer;
  Color _backgroundColor = Colors.white; // default background color

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTTS();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          _startListening();
        }
      },
    );
    setState(() {});
  }

  void _initTTS() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
  }

  void _startListening() async {
    if (!_speechAvailable) return;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final recognized = result.recognizedWords.toLowerCase();
          if (recognized.contains('ok') || recognized.contains('start')) {
            _startOrRestartCountdown();
          } else if (recognized.contains('stop')) {
            _stopCountdown();
          }
        }
      },
      listenFor: const Duration(seconds: 5),
      partialResults: false,
    );

    setState(() => _isListening = true);
  }

  void _stopListening() {
    _speech.stop();
    _stopCountdown();
    setState(() => _isListening = false);
  }

  void _startOrRestartCountdown() {
    final count = int.tryParse(_countdownController.text) ?? 50;

    // ✅ Ensure number is greater than 10
    if (count <= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a number greater than 10'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _countdownTimer?.cancel();

    setState(() {
      _currentCount = count;
      _isCounting = true;
      _backgroundColor = Colors.blue; // turn blue when starting
    });

    _startCountdown();
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCounting = false;
      _currentCount = 0;
      _backgroundColor = Colors.white; // reset to white
    });
    _flutterTts.stop();
  }

  Future<void> _speakNumber(int number) async {
    if (!_soundEnabled) return;
    await _flutterTts.stop();
    await _flutterTts.speak(number.toString());
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isCounting) {
        timer.cancel();
        return;
      }

      setState(() => _currentCount--);

      // ✅ Turn background red when hitting 10
      if (_currentCount == 10) {
        setState(() {
          _backgroundColor = Colors.red;
        });
      }

      // ✅ Speak every second from 10 down to 1
      if (_currentCount <= 10 && _currentCount > 0) {
        await _speakNumber(_currentCount);
      }

      // ✅ Stop countdown when it reaches 0
      if (_currentCount <= 0) {
        _isCounting = false;
        timer.cancel();
        setState(() {
          _backgroundColor = Colors.white; // Reset background after finish
        });
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _countdownController.dispose();
    _flutterTts.stop();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Voice Countdown Game'),
        actions: [
          IconButton(
            icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _countdownController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Countdown Start Number',
                border: OutlineInputBorder(),
              ),
              enabled: !_isCounting,
            ),
            const SizedBox(height: 40),
            Text(
              _isCounting ? '$_currentCount' : 'Ready',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: _isCounting ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  child: Text(
                    _isListening ? 'Stop Listening' : 'Start Listening',
                  ),
                ),
                const SizedBox(width: 20),
                if (!_speechAvailable)
                  const Text(
                    'Speech not available',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Say "OK" or "Start" to start/restart countdown\nSay "Stop" to stop',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
