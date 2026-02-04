import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../utils/colors.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path, int durationMs) onRecordingComplete;
  final VoidCallback? onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await AudioService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      HapticFeedback.mediumImpact();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _pauseRecording() async {
    await AudioService.pauseRecording();
    setState(() {
      _isPaused = true;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _resumeRecording() async {
    await AudioService.resumeRecording();
    setState(() {
      _isPaused = false;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final result = await AudioService.stopRecording();

    if (result != null) {
      widget.onRecordingComplete(
        result.path,
        result.duration.inMilliseconds,
      );
    }

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
    HapticFeedback.heavyImpact();
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await AudioService.cancelRecording();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
    });

    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            _isRecording ? 'Đang ghi âm' : 'Ghi âm',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 32),

          // Timer
          Text(
            AudioService.formatDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: _isRecording ? AppColors.error : Colors.grey,
            ),
          ),

          const SizedBox(height: 32),

          // Recording indicator
          if (_isRecording)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 16 + (_pulseController.value * 8),
                  height: 16 + (_pulseController.value * 8),
                  decoration: BoxDecoration(
                    color: _isPaused
                        ? Colors.grey
                        : AppColors.error
                            .withOpacity(0.5 + _pulseController.value * 0.5),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),

          const SizedBox(height: 32),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel button
              if (_isRecording)
                _buildControlButton(
                  icon: Icons.close,
                  label: 'Hủy',
                  color: Colors.grey,
                  onTap: _cancelRecording,
                ),

              // Main button
              _buildMainButton(),

              // Pause/Resume button
              if (_isRecording)
                _buildControlButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  label: _isPaused ? 'Tiếp tục' : 'Tạm dừng',
                  color: AppColors.primary,
                  onTap: _isPaused ? _resumeRecording : _pauseRecording,
                ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _isRecording ? AppColors.error : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? AppColors.error : AppColors.primary)
                  .withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
