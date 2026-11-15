import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenCall extends StatefulWidget {
  final String callId;
  final String otherUserId;
  final String otherUserName;
  final bool isCaller;

  const ScreenCall({
    super.key,
    required this.callId,
    required this.otherUserId,
    required this.otherUserName,
    required this.isCaller,
  });

  @override
  State<ScreenCall> createState() => _ScreenCallState();
}

class _ScreenCallState extends State<ScreenCall> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _callSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _remoteCandidatesSubscription;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isEnding = false;

  bool _connected = false;

  Timer? _durationTimer;
  int _seconds = 0;

  DocumentReference<Map<String, dynamic>> get _callRef =>
      _firestore.collection('calls').doc(widget.callId);

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _createPeerConnection();
      await _getMicrophone();

      if (widget.isCaller) {
        await _startOutgoingCall();
      } else {
        await _answerIncomingCall();
      }

      _listenToCall();
    } catch (e) {
      debugPrint('CALL INITIALIZATION ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to start voice call: $e'),
          ),
        );
      }

      await _endCall(updateFirestore: false);
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
          ],
        },
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate.candidate == null) {
        return;
      }

      final collectionName =
          widget.isCaller ? 'callerCandidates' : 'calleeCandidates';

      await _callRef.collection(collectionName).add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });
    };

    _peerConnection!.onConnectionState =
        (RTCPeerConnectionState state) async {
      debugPrint('WebRTC connection state: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (!_connected) {
          _connected = true;
          _startDurationTimer();

          if (mounted) {
            setState(() {});
          }
        }
      }

      if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (!_isEnding) {
          await _endCall();
        }
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      debugPrint(
        'Remote audio track received: ${event.track.kind}',
      );
    };
  }

  Future<void> _getMicrophone() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(
      mediaConstraints,
    );

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(
        track,
        _localStream!,
      );
    }

    await Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  Future<void> _startOutgoingCall() async {
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await _peerConnection!.setLocalDescription(offer);

    await _callRef.set({
      'callerId': _auth.currentUser!.uid,
      'calleeId': widget.otherUserId,
      'type': 'voice',
      'status': 'ringing',
      'callerName': _getCurrentUserName(),
      'calleeName': widget.otherUserName,
      'offer': {
        'sdp': offer.sdp,
        'type': offer.type,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _listenForRemoteCandidates('calleeCandidates');
  }

  Future<void> _answerIncomingCall() async {
    final snapshot = await _callRef.get();

    if (!snapshot.exists) {
      throw Exception('Call no longer exists.');
    }

    final data = snapshot.data();

    if (data == null || data['offer'] == null) {
      throw Exception('Call offer is missing.');
    }

    final offer = Map<String, dynamic>.from(
      data['offer'] as Map,
    );

    final remoteDescription = RTCSessionDescription(
      offer['sdp']?.toString(),
      offer['type']?.toString(),
    );

    await _peerConnection!.setRemoteDescription(
      remoteDescription,
    );

    _listenForRemoteCandidates('callerCandidates');

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await _peerConnection!.setLocalDescription(answer);

    await _callRef.update({
      'answer': {
        'sdp': answer.sdp,
        'type': answer.type,
      },
      'status': 'accepted',
      'answeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _listenToCall() {
    _callSubscription = _callRef.snapshots().listen(
      (snapshot) async {
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data();

        if (data == null) {
          return;
        }

        final status = data['status']?.toString();

        if (widget.isCaller &&
            status == 'accepted' &&
            data['answer'] != null) {
          final currentRemote =
              await _peerConnection?.getRemoteDescription();

          if (currentRemote == null) {
            final answer = Map<String, dynamic>.from(
              data['answer'] as Map,
            );

            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(
                answer['sdp']?.toString(),
                answer['type']?.toString(),
              ),
            );
          }
        }

        if (status == 'rejected' ||
            status == 'ended' ||
            status == 'missed') {
          if (!_isEnding) {
            await _finishLocalCall();
          }
        }

        if (status == 'accepted' && mounted) {
          if (!_connected) {
            setState(() {});
          }
        }
      },
      onError: (error) {
        debugPrint('Call listener error: $error');
      },
    );
  }

  void _listenForRemoteCandidates(
    String collectionName,
  ) {
    _remoteCandidatesSubscription?.cancel();

    _remoteCandidatesSubscription =
        _callRef.collection(collectionName).snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) {
            continue;
          }

          final data = change.doc.data();

          if (data == null) {
            continue;
          }

          try {
            final candidate = RTCIceCandidate(
              data['candidate']?.toString(),
              data['sdpMid']?.toString(),
              data['sdpMLineIndex'] is int
                  ? data['sdpMLineIndex'] as int
                  : int.tryParse(
                      data['sdpMLineIndex']?.toString() ?? '',
                    ),
            );

            await _peerConnection?.addCandidate(candidate);
          } catch (e) {
            debugPrint(
              'ADD REMOTE ICE CANDIDATE ERROR: $e',
            );
          }
        }
      },
    );
  }

  String _getCurrentUserName() {
    final user = _auth.currentUser;

    if (user == null) {
      return 'User';
    }

    return user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'User';
  }

  void _startDurationTimer() {
    if (_durationTimer != null) {
      return;
    }

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _seconds++;
        });
      },
    );
  }

  String _formatDuration() {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  // ============================================================
  // MUTE / UNMUTE MICROPHONE
  // ============================================================

  Future<void> _toggleMute() async {
    if (_localStream == null) {
      return;
    }

    final audioTracks = _localStream!.getAudioTracks();

    if (audioTracks.isEmpty) {
      return;
    }

    final newMutedState = !_isMuted;

    for (final track in audioTracks) {
      track.enabled = !newMutedState;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isMuted = newMutedState;
    });
  }

  // ============================================================
  // SPEAKER / EARPIECE
  // ============================================================

  Future<void> _toggleSpeaker() async {
    final newSpeakerState = !_isSpeakerOn;

    try {
      await Helper.setSpeakerphoneOn(newSpeakerState);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSpeakerOn = newSpeakerState;
      });
    } catch (e) {
      debugPrint('SPEAKER ERROR: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to change speaker: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // END CALL
  // ============================================================

  Future<void> _endCall({
    bool updateFirestore = true,
  }) async {
    if (_isEnding) {
      return;
    }

    _isEnding = true;

    try {
      if (updateFirestore) {
        try {
          await _callRef.update({
            'status': 'ended',
            'endedBy': _auth.currentUser?.uid,
            'endedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint(
            'UPDATE END CALL FIRESTORE ERROR: $e',
          );
        }
      }
    } finally {
      await _cleanupCall();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // ============================================================
  // FINISH CALL WITHOUT WRITING AGAIN
  // ============================================================

  Future<void> _finishLocalCall() async {
    if (_isEnding) {
      return;
    }

    _isEnding = true;

    await _cleanupCall();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // CLEANUP WEBRTC
  // ============================================================

  Future<void> _cleanupCall() async {
    _durationTimer?.cancel();
    _durationTimer = null;

    await _callSubscription?.cancel();
    _callSubscription = null;

    await _remoteCandidatesSubscription?.cancel();
    _remoteCandidatesSubscription = null;

    try {
      final tracks = _localStream?.getTracks() ?? [];

      for (final track in tracks) {
        try {
          await track.stop();
        } catch (e) {
          debugPrint(
            'TRACK STOP ERROR: $e',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'LOCAL STREAM CLEANUP ERROR: $e',
      );
    }

    try {
      await _localStream?.dispose();
    } catch (e) {
      debugPrint(
        'LOCAL STREAM DISPOSE ERROR: $e',
      );
    }

    _localStream = null;

    try {
      await _peerConnection?.close();
    } catch (e) {
      debugPrint(
        'PEER CONNECTION CLOSE ERROR: $e',
      );
    }

    _peerConnection = null;
  }

  // ============================================================
  // BACK BUTTON
  // ============================================================

  Future<bool> _handleBackPressed() async {
    if (_isEnding) {
      return false;
    }

    await _endCall();

    return false;
  }

  // ============================================================
  // CALL STATUS TEXT
  // ============================================================

  String _callStatusText() {
    if (_connected) {
      return _formatDuration();
    }

    if (widget.isCaller) {
      return 'Calling...';
    }

    return 'Connecting...';
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    return Container(
      width: 105,
      height: 105,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: const Icon(
        Icons.person,
        size: 58,
        color: Colors.grey,
      ),
    );
  }

  // ============================================================
  // CALL CONTROL BUTTON
  // ============================================================

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? label,
    bool active = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: active
              ? Colors.white
              : Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 62,
              height: 62,
              child: Icon(
                icon,
                size: 28,
                color: active
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) async {
        if (didPop) {
          return;
        }

        await _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF202C33),
        body: SafeArea(
          child: Column(
            children: [
              // ------------------------------------------------
              // TOP BAR
              // ------------------------------------------------

              SizedBox(
                height: 70,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await _endCall();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 4),

                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white24,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUserName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _callStatusText(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // MAIN CALL AREA
              // ------------------------------------------------

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    _buildAvatar(),

                    const SizedBox(height: 24),

                    Text(
                      widget.otherUserName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _callStatusText(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 70),

                    // ------------------------------------------------
                    // CALL CONTROLS
                    // ------------------------------------------------

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted
                              ? Icons.mic_off
                              : Icons.mic,
                          label: _isMuted
                              ? 'Unmute'
                              : 'Mute',
                          active: _isMuted,
                          onPressed: _toggleMute,
                        ),

                        _buildControlButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.hearing,
                          label: _isSpeakerOn
                              ? 'Speaker'
                              : 'Earpiece',
                          active: _isSpeakerOn,
                          onPressed: _toggleSpeaker,
                        ),
                      ],
                    ),

                    const SizedBox(height: 55),

                    // ------------------------------------------------
                    // END CALL BUTTON
                    // ------------------------------------------------

                    Material(
                      color: Colors.red,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder:
                            const CircleBorder(),
                        onTap: () async {
                          await _endCall();
                        },
                        child: const SizedBox(
                          width: 70,
                          height: 70,
                          child: Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _durationTimer?.cancel();

    _callSubscription?.cancel();
    _remoteCandidatesSubscription?.cancel();

    _localStream?.getTracks().forEach(
      (track) {
        track.stop();
      },
    );

    _localStream?.dispose();
    _peerConnection?.close();

    super.dispose();
  }
}