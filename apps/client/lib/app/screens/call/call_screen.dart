import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_client.dart';
import '../../services/call_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Sesli/goruntulu arama ekrani. Medya WebRTC, sinyal REST (`/v1/calls`).
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.apiClient,
    required this.callId,
    required this.peerName,
    required this.isVideo,
    required this.isCaller,
    this.initialCall,
    this.onEnded,
  });

  final ApiClientPort apiClient;
  final String callId;
  final String peerName;
  final bool isVideo;
  final bool isCaller;
  final Map<String, dynamic>? initialCall;
  final VoidCallback? onEnded;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallService _service;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  String _stateText = 'Hazırlanıyor…';
  bool _muted = false;
  bool _starting = true;
  bool _ended = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _service = CallService(apiClient: widget.apiClient);
    _boot();
  }

  Future<void> _boot() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _service.onRemoteStream = (stream) {
      if (!mounted) return;
      setState(() {
        _remoteRenderer.srcObject = stream;
        _stateText = 'Bağlı';
      });
      _startTimer();
    };
    _service.onState = (state) {
      if (!mounted || _ended) return;
      if (state.startsWith('ended:')) {
        final reason = state.split(':').last;
        _finish(silent: true, note: reason == 'DECLINED' ? 'Arama reddedildi.' : 'Arama sona erdi.');
        return;
      }
      setState(() => _stateText = _readableState(state));
    };
    try {
      await _requestPermissions();
      if (widget.isCaller) {
        setState(() => _stateText = 'Çalıyor…');
        await _service.startCall(widget.callId, widget.isVideo);
      } else {
        setState(() => _stateText = 'Bağlanıyor…');
        final call = widget.initialCall ?? {'id': widget.callId, 'kind': widget.isVideo ? 'VIDEO' : 'VOICE'};
        await _service.joinCall(call);
      }
      final local = _serviceLocalStream();
      if (mounted && local != null) setState(() => _localRenderer.srcObject = local);
    } on ApiException catch (e) {
      if (mounted) _finish(note: e.message ?? 'Arama başlatılamadı');
    } catch (_) {
      if (mounted) _finish(note: 'Arama başlatılamadı');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  MediaStream? _serviceLocalStream() => _service.localStreamForPreview;

  Future<void> _requestPermissions() async {
    try {
      await Permission.microphone.request();
      if (widget.isVideo) await Permission.camera.request();
    } catch (_) {}
  }

  String _readableState(String state) {
    switch (state) {
      case 'RTCPeerConnectionState.RTCPeerConnectionStateConnecting':
      case 'connecting':
        return 'Bağlanıyor…';
      case 'RTCPeerConnectionState.RTCPeerConnectionStateConnected':
      case 'connected':
        return 'Bağlı';
      case 'RTCPeerConnectionState.RTCPeerConnectionStateFailed':
      case 'failed':
        return 'Bağlantı kurulamadı (NAT).';
      default:
        return _stateText;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _elapsed {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _finish({bool silent = false, String? note}) async {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    if (!silent) {
      try {
        await _service.endCall();
      } catch (_) {}
    } else {
      await _service.dispose();
    }
    widget.onEnded?.call();
    if (!mounted) return;
    if (note != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(note)));
    }
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    if (!_ended) {
      _ended = true;
      _service.dispose();
      widget.onEnded?.call();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(widget.peerName),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            AvatarCircle(name: widget.peerName, size: 84, online: true),
            const SizedBox(height: 12),
            Text(
              widget.isVideo ? 'Görüntülü arama' : 'Sesli arama',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(_stateText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (_seconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_elapsed, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.isVideo
                  ? Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(24)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                          ),
                        ),
                        Positioned(
                          right: 28,
                          bottom: 16,
                          child: Container(
                            width: 110,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: RTCVideoView(_localRenderer, mirror: true),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.graphic_eq, color: Colors.white24, size: 120),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CallButton(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  label: _muted ? 'Ses aç' : 'Sessiz',
                  onPressed: _starting
                      ? null
                      : () async {
                          await _service.setMuted(!_muted);
                          if (mounted) setState(() => _muted = !_muted);
                        },
                ),
                const SizedBox(width: 20),
                if (widget.isVideo) ...[
                  _CallButton(
                    icon: Icons.cameraswitch_outlined,
                    label: 'Kamera',
                    onPressed: _starting ? null : () => _service.switchCamera(),
                  ),
                  const SizedBox(width: 20),
                ],
                _CallButton(
                  icon: Icons.call_end,
                  label: 'Kapat',
                  danger: true,
                  onPressed: () => _finish(note: 'Arama sona erdi.'),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.icon, required this.label, this.onPressed, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: danger ? AppColors.error : Colors.white24,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
