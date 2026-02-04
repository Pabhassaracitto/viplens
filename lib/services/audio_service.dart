import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'media_service.dart';

enum AudioState {
  idle,
  recording,
  paused,
  playing,
  stopped,
}

class AudioService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();
  static const _uuid = Uuid();

  static AudioState _state = AudioState.idle;
  static String? _currentRecordingPath;
  static String? _currentPlayingPath;
  static Duration _currentPosition = Duration.zero;
  static Duration _totalDuration = Duration.zero;

  // Stream controllers
  static final _stateController = StreamController<AudioState>.broadcast();
  static final _positionController = StreamController<Duration>.broadcast();
  static final _durationController = StreamController<Duration>.broadcast();

  // Getters
  static AudioState get state => _state;
  static Duration get currentPosition => _currentPosition;
  static Duration get totalDuration => _totalDuration;
  static Stream<AudioState> get stateStream => _stateController.stream;
  static Stream<Duration> get positionStream => _positionController.stream;
  static Stream<Duration> get durationStream => _durationController.stream;

  /// Khởi tạo
  static Future<void> initialize() async {
    _player.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    _player.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      _durationController.add(duration);
    });

    _player.onPlayerComplete.listen((_) {
      _state = AudioState.stopped;
      _stateController.add(_state);
      _currentPosition = Duration.zero;
      _positionController.add(_currentPosition);
    });
  }

  /// Kiểm tra quyền ghi âm
  static Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  /// Bắt đầu ghi âm
  static Future<bool> startRecording() async {
    try {
      if (!await checkPermission()) {
        return false;
      }

      final audioDir = await MediaService.getAudioDirectory();
      final fileName = '${_uuid.v4()}.m4a';
      _currentRecordingPath = '${audioDir.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _state = AudioState.recording;
      _stateController.add(_state);
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Tạm dừng ghi âm
  static Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
      _state = AudioState.paused;
      _stateController.add(_state);
    } catch (e) {
      debugPrint('Error pausing recording: $e');
    }
  }

  /// Tiếp tục ghi âm
  static Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
      _state = AudioState.recording;
      _stateController.add(_state);
    } catch (e) {
      debugPrint('Error resuming recording: $e');
    }
  }

  /// Dừng ghi âm và trả về đường dẫn file
  static Future<RecordingResult?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _state = AudioState.idle;
      _stateController.add(_state);

      if (path == null) return null;

      // Lấy thời lượng
      await _player.setSourceDeviceFile(path);
      final duration = await _player.getDuration();
      await _player.stop();

      return RecordingResult(
        path: path,
        duration: duration ?? Duration.zero,
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Hủy ghi âm
  static Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _state = AudioState.idle;
      _stateController.add(_state);

      // Xóa file đã ghi
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  /// Phát audio
  static Future<void> play(String path) async {
    try {
      if (_state == AudioState.playing && _currentPlayingPath == path) {
        // Đang phát file này, tạm dừng
        await _player.pause();
        _state = AudioState.paused;
        _stateController.add(_state);
        return;
      }

      if (_state == AudioState.paused && _currentPlayingPath == path) {
        // Tiếp tục phát
        await _player.resume();
        _state = AudioState.playing;
        _stateController.add(_state);
        return;
      }

      // Phát file mới
      _currentPlayingPath = path;
      await _player.play(DeviceFileSource(path));
      _state = AudioState.playing;
      _stateController.add(_state);
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// Tạm dừng phát
  static Future<void> pause() async {
    try {
      await _player.pause();
      _state = AudioState.paused;
      _stateController.add(_state);
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  /// Dừng phát
  static Future<void> stop() async {
    try {
      await _player.stop();
      _state = AudioState.stopped;
      _stateController.add(_state);
      _currentPosition = Duration.zero;
      _positionController.add(_currentPosition);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Seek đến vị trí
  static Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  /// Format duration thành string
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Dispose
  static Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}

class RecordingResult {
  final String path;
  final Duration duration;

  RecordingResult({
    required this.path,
    required this.duration,
  });
}
