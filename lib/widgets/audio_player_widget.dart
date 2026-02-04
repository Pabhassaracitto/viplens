import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../utils/colors.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final int? durationMs;
  final bool compact;
  final VoidCallback? onDelete;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.durationMs,
    this.compact = false,
    this.onDelete,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = Duration(milliseconds: widget.durationMs ?? 0);

    AudioService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == AudioState.playing;
        });
      }
    });

    AudioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    AudioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  void _togglePlay() {
    AudioService.play(widget.audioPath);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Icon(
              _isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AudioService.formatDuration(_isPlaying ? _position : _duration),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onDelete,
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Progress
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: AppColors.primary,
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds /
                                _duration.inMilliseconds
                            : 0,
                        onChanged: (value) {
                          final position = Duration(
                            milliseconds:
                                (value * _duration.inMilliseconds).toInt(),
                          );
                          AudioService.seek(position);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AudioService.formatDuration(_position),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          AudioService.formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              if (widget.onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  onPressed: widget.onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
