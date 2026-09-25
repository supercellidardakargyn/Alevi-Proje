import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'api_client.dart';

/// Sesli/goruntulu arama: WebRTC medya + REST sinyallesme (`/v1/calls`).
/// NAT gecisi icin herkese acik STUN kullanilir; simetrik NAT arkasinda
/// baglanti kurulamayabilir (o durumda TURN gerekir, sunucu tarafinda yok).
class CallService {
  CallService({required ApiClientPort apiClient}) : _apiClient = apiClient;

  final ApiClientPort _apiClient;
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  Timer? _poller;
  final List<RTCIceCandidate> _pendingIce = [];
  final Set<String> _appliedIce = {};
  bool _disposed = false;

  static const _stun = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
  ];

  void Function(MediaStream stream)? onRemoteStream;
  void Function(String state)? onState;

  /// Onizleme icin yerel akis (izin sonrasi dolar).
  MediaStream? get localStreamForPreview => _localStream;

  Future<Map<String, dynamic>> startCall(String conversationId, bool video) async {
    final result = await _apiClient.post('/v1/calls', body: {
      'conversationId': conversationId,
      'kind': video ? 'VIDEO' : 'VOICE',
    },);
    final data = result['data'];
    if (data is! Map) throw const ApiException(502, 'Arama başlatılamadı');
    await _setupPeer(video: video);
    final offer = await _peer!.createOffer();
    await _peer!.setLocalDescription(offer);
    await _apiClient.patch("/v1/calls/${data['id']}/signal", body: {
      'offer': offer.toMap(),
    },);
    _startPolling(data['id'].toString(), isCaller: true);
    return data.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> joinCall(Map<String, dynamic> call) async {
    final video = (call['kind']?.toString() ?? 'VOICE') == 'VIDEO';
    final result = await _apiClient.post("/v1/calls/${call['id']}/accept");
    final data = result['data'];
    if (data is! Map) throw const ApiException(502, 'Arama yanıtlanamadı');
    await _setupPeer(video: video);
    final offer = (data['offer'] as Map?)?.cast<String, dynamic>();
    if (offer != null) {
      await _peer!.setRemoteDescription(RTCSessionDescription(offer['sdp']?.toString(), offer['type']?.toString()));
    }
    final answer = await _peer!.createAnswer();
    await _peer!.setLocalDescription(answer);
    await _apiClient.patch("/v1/calls/${data['id']}/signal", body: {
      'answer': answer.toMap(),
    },);
    _startPolling(data['id'].toString(), isCaller: false);
    return data.cast<String, dynamic>();
  }

  Future<void> _setupPeer({required bool video}) async {
    _peer = await createPeerConnection({
      'iceServers': [
        {'urls': _stun},
      ],
    });
    _peer!.onIceCandidate = (candidate) {
      _pendingIce.add(candidate);
      _flushIce();
    };
    _peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) onRemoteStream?.call(event.streams.first);
    };
    _peer!.onConnectionState = (state) => onState?.call(state.name);
    final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': video});
    _localStream = stream;
    for (final track in stream.getTracks()) {
      await _peer!.addTrack(track, stream);
    }
  }

  Timer? _flushTimer;

  void _flushIce() {
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 500), () => _sendIce());
  }

  String? _callId;

  void _startPolling(String callId, {required bool isCaller}) {
    _callId = callId;
    _sendIce();
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_disposed) return;
      try {
        final result = await _apiClient.get('/v1/calls/$callId');
        final data = result['data'];
        if (data is! Map) return;
        final status = data['status']?.toString() ?? '';
        if (status == 'DECLINED' || status == 'ENDED' || status == 'MISSED') {
          onState?.call('ended:$status');
          return;
        }
        if (isCaller) {
          final answer = (data['answer'] as Map?)?.cast<String, dynamic>();
          if (answer != null) {
            final desc = await _peer?.getRemoteDescription();
            if (desc == null) {
              await _peer?.setRemoteDescription(RTCSessionDescription(answer['sdp']?.toString(), answer['type']?.toString()));
            }
          }
        }
        final ice = (data['iceCandidates'] as List? ?? const []).cast<Map<String, dynamic>>();
        for (final candidate in ice) {
          final key = '${candidate['candidate']}';
          if (_appliedIce.contains(key)) continue;
          _appliedIce.add(key);
          try {
            await _peer?.addCandidate(RTCIceCandidate(
              candidate['candidate']?.toString(),
              candidate['sdpMid']?.toString(),
              (candidate['sdpMLineIndex'] as num?)?.toInt(),
            ),);
          } catch (_) {}
        }
      } catch (_) {}
    });
  }

  Future<void> _sendIce() async {
    final callId = _callId;
    if (_disposed || callId == null || _pendingIce.isEmpty) return;
    final batch = _pendingIce.map((c) => c.toMap().cast<String, Object?>()).toList();
    try {
      await _apiClient.patch('/v1/calls/$callId/signal', body: {'ice': batch});
    } catch (_) {}
  }

  Future<void> setMuted(bool muted) async {
    for (final track in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> switchCamera() async {
    final videoTracks = _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (videoTracks.isNotEmpty) {
      try {
        await Helper.switchCamera(videoTracks.first);
      } catch (_) {}
    }
  }

  Future<void> endCall() async {
    final callId = _callId;
    _poller?.cancel();
    _flushTimer?.cancel();
    if (callId != null) {
      try {
        await _apiClient.post('/v1/calls/$callId/end');
      } catch (_) {}
    }
    await dispose();
  }

  Future<void> dispose() async {
    _disposed = true;
    _poller?.cancel();
    _flushTimer?.cancel();
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _peer?.close();
    } catch (_) {}
    _peer = null;
    _localStream = null;
  }
}
