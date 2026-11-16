import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/chat_media_cache.dart';
import 'package:jober_india/jober_indiaScreens.dart/Message/chat_media_compressor.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';


// ============================================================
// MESSAGE TYPE
// ============================================================

enum MessageType {
  text,
  image,
  video,
  audio,
  location,
  liveLocation,
}


// ============================================================
// MESSAGE TYPE -> STRING
// ============================================================

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.text:
      return 'text';

    case MessageType.image:
      return 'image';

    case MessageType.video:
      return 'video';

    case MessageType.audio:
      return 'audio';

    case MessageType.location:
      return 'location';

    case MessageType.liveLocation:
      return 'liveLocation';
  }
}

// ============================================================
// STRING -> MESSAGE TYPE
// ============================================================

MessageType stringToMessageType(String value) {
  switch (value) {
    case 'image':
      return MessageType.image;

    case 'video':
      return MessageType.video;

    case 'audio':
      return MessageType.audio;

    case 'location':
      return MessageType.location;

    case 'liveLocation':
      return MessageType.liveLocation;

    default:
      return MessageType.text;
  }
}


// ============================================================
// CHAT MESSAGE MODEL
// ============================================================

class ChatMessage {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? mediaUrl;
  final double? latitude;
  final double? longitude;
  final DateTime time;
  final bool isMe;
  final MessageType type;
  final String status;
  final bool liveLocationActive;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.mediaUrl,
    this.latitude,
    this.longitude,
    required this.time,
    required this.isMe,
    required this.type,
    required this.status,
    required this.liveLocationActive,
  });
}

// ============================================================
// SCREEN MESSAGE
// ============================================================

class ScreenMessage extends StatefulWidget {
  final Map<String, dynamic> chatUser;

  // Taxi-specific options. Normal chats do not need these.
  final String? taxiRideId;
  final bool isTaxiPassenger;

  const ScreenMessage({
    super.key,
    required this.chatUser,
    this.taxiRideId,
    this.isTaxiPassenger = false,
  });

  @override
  State<ScreenMessage> createState() => _ScreenMessageState();
}


class _ScreenMessageState extends State<ScreenMessage> {

  // ----------------------------------------------------------
  // FIREBASE
  // ----------------------------------------------------------

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ----------------------------------------------------------
  // CONTROLLERS
  // ----------------------------------------------------------

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final ImagePicker _imagePicker =
      ImagePicker();

  final AudioRecorder _audioRecorder =
      AudioRecorder();


  // ----------------------------------------------------------
  // STREAMS / STATE
  // ----------------------------------------------------------

  StreamSubscription<Position>? _liveLocationSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _recipientPresenceSubscription;

  String? _currentUserId;

  String? _chatUserId;

  String _conversationId = '';

  String _chatName = 'User';

  String _chatStatus = 'Offline';

  bool _showAttachments = false;

  bool _isRecording = false;

  bool _isSending = false;

  bool _isLiveLocationSharing = false;

  bool _isRecipientOnline = false;

  String? _liveLocationMessageId;

  String? _recordingPath;

  // ----------------------------------------------------------
// TAXI RIDE STATE — used only when taxiRideId is supplied
// ----------------------------------------------------------

StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    _taxiRideSubscription;

Map<String, dynamic> _taxiRideData = {};

bool get _isTaxiChat =>
    widget.taxiRideId != null &&
    widget.taxiRideId!.trim().isNotEmpty;

bool get _canPassengerControlRide =>
    _isTaxiChat && widget.isTaxiPassenger;

bool get _passengerConfirmedRide =>
    _taxiRideData['passengerConfirmed'] == true;

  @override
  void initState() {
    super.initState();

    _initializeChat();
  }

  void _listenToTaxiRide() {
  final rideId = widget.taxiRideId;

  if (rideId == null || rideId.trim().isEmpty) {
    return;
  }

  _taxiRideSubscription?.cancel();

  _taxiRideSubscription = _firestore
      .collection('rideRequests')
      .doc(rideId)
      .snapshots()
      .listen(
    (snapshot) {
      if (!mounted) return;

      setState(() {
        _taxiRideData = snapshot.data() ?? {};
      });
    },
    onError: (error) {
      debugPrint('Taxi ride listener error: $error');
    },
  );
}

Future<void> _confirmTaxiRide() async {
  final rideId = widget.taxiRideId;

  if (!_canPassengerControlRide ||
      rideId == null ||
      rideId.trim().isEmpty) {
    return;
  }

  if (_passengerConfirmedRide) {
    _showMessage('You have already confirmed this ride.');
    return;
  }

  try {
    final rideRef = _firestore
        .collection('rideRequests')
        .doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);

      if (!snapshot.exists) {
        throw Exception('Taxi ride request was not found.');
      }

      final data = snapshot.data() ?? {};

      if (data['status'] == 'cancelled') {
        throw Exception('This ride has been cancelled.');
      }

      if (data['passengerConfirmed'] == true) {
        return;
      }

      transaction.update(rideRef, {
        'passengerConfirmed': true,
        'pickupLocationShared': true,
        'status': 'confirmed',
        'passengerConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _sendMessage(
      type: MessageType.text,
      text: 'Passenger confirmed the ride.',
    );

    if (mounted) {
      _showMessage('Ride confirmed.');
    }
  } catch (e) {
    debugPrint('Taxi ride confirmation error: $e');

    if (mounted) {
      _showMessage('Unable to confirm this ride.');
    }
  }
}

Future<void> _cancelTaxiRide() async {
  final rideId = widget.taxiRideId;

  if (!_canPassengerControlRide ||
      rideId == null ||
      rideId.trim().isEmpty) {
    return;
  }

  final shouldCancel = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this ride?'),
      content: const Text(
        'Are you sure you want to cancel this taxi ride?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep ride'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(
            'Cancel ride',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (shouldCancel != true) return;

  try {
    final rideRef = _firestore
        .collection('rideRequests')
        .doc(rideId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);

      if (!snapshot.exists) {
        throw Exception('Taxi ride request was not found.');
      }

      final data = snapshot.data() ?? {};

      if (data['status'] == 'completed') {
        throw Exception('This ride is already completed.');
      }

      if (data['status'] == 'cancelled') {
        return;
      }

      transaction.update(rideRef, {
        'status': 'cancelled',
        'cancelledBy': _currentUserId,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _sendMessage(
      type: MessageType.text,
      text: 'Passenger cancelled the ride.',
    );

    if (mounted) {
      _showMessage('Ride cancelled.');
    }
  } catch (e) {
    debugPrint('Taxi ride cancellation error: $e');

    if (mounted) {
      _showMessage('Unable to cancel this ride.');
    }
  }
}

Widget _buildTaxiRidePanel() {
  final status =
      (_taxiRideData['status'] ?? 'accepted')
          .toString()
          .replaceAll('_', ' ');

  final cancelled = status.toLowerCase() == 'cancelled';
  final completed = status.toLowerCase() == 'completed';

  String heading;

  if (cancelled) {
    heading = 'Ride cancelled';
  } else if (completed) {
    heading = 'Ride completed';
  } else if (_passengerConfirmedRide) {
    heading = 'Ride confirmed';
  } else {
    heading = 'Discuss your fare with the driver';
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_taxi,
              color: Color(0xFF16803C),
              size: 25,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_canPassengerControlRide &&
            !_passengerConfirmedRide &&
            !cancelled &&
            !completed) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelTaxiRide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Cancel Ride'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmTaxiRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16803C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm This Ride'),
                ),
              ),
            ],
          ),
        ],

        if (_canPassengerControlRide &&
            _passengerConfirmedRide) ...[
          const SizedBox(height: 8),
          const Text(
            'You confirmed the ride. Your pickup location can now be shared.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF16803C),
            ),
          ),
        ],
      ],
    ),
  );
}

Future<void> _initializeChat() async {
  final currentUser = _auth.currentUser;

  if (currentUser == null) {
    return;
  }

  _currentUserId = currentUser.uid;

  final recipientUid =
      _extractRecipientUid(widget.chatUser);

  if (recipientUid == null ||
      recipientUid.isEmpty) {
    return;
  }

  _chatUserId = recipientUid;

  _chatName =
      _extractRecipientName(widget.chatUser);

  _conversationId = _makeConversationId(
    _currentUserId!,
    _chatUserId!,
  );

  await _createConversation();

  _listenToRecipientPresence();

  await _markMessagesDelivered();

  await _markMessagesSeen();

  if (_isTaxiChat) {
    _listenToTaxiRide();
  }

  if (mounted) {
    setState(() {});
  }
}


  // ============================================================
  // RECIPIENT UID
  // ============================================================

  String? _extractRecipientUid(
    Map<String, dynamic> user,
  ) {
    final values = [
      user['uid'],
      user['userId'],
      user['id'],
    ];

    for (final value in values) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }


  // ============================================================
  // RECIPIENT NAME
  // ============================================================

  String _extractRecipientName(
    Map<String, dynamic> user,
  ) {
    final values = [
      user['name'],
      user['username'],
      user['workerName'],
      user['doctorName'],
      user['shopName'],
      user['clinicName'],
      user['garageName'],
      user['companyName'],
    ];

    for (final value in values) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return 'User';
  }


  // ============================================================
  // CONVERSATION ID
  // ============================================================

  String _makeConversationId(
    String first,
    String second,
  ) {
    final ids = [
      first,
      second,
    ]..sort();

    return '${ids[0]}_${ids[1]}';
  }


  // ============================================================
  // FIRESTORE REFERENCES
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get _conversationRef {
    return _firestore
        .collection('conversations')
        .doc(_conversationId);
  }


  CollectionReference<Map<String, dynamic>>
      get _messagesRef {
    return _conversationRef
        .collection('messages');
  }


  // ============================================================
  // CREATE / UPDATE CONVERSATION
  // ============================================================

Future<void> _createConversation() async {
  final uid = _currentUserId;
  final otherUid = _chatUserId;

  if (uid == null ||
      uid.isEmpty ||
      otherUid == null ||
      otherUid.isEmpty) {
    return;
  }

  // Unique participants: self-chat contains only one UID.
  final participantIds = <String>{uid, otherUid}.toList()
    ..sort();

  _conversationId = '${participantIds[0]}_${participantIds.length == 1 ? participantIds[0] : participantIds[1]}';

  final conversationRef = FirebaseFirestore.instance
      .collection('conversations')
      .doc(_conversationId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(conversationRef);

    if (!snapshot.exists) {
      transaction.set(conversationRef, {
        'participants': participantIds,
        'participantNames': {
          uid: uid == otherUid ? _chatName : 'Me',
          otherUid: _chatName,
        },
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastSenderId': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Ensure existing conversations have the correct participant list.
      transaction.update(conversationRef, {
        'participants': participantIds,
      });
    }
  });
}


  // ============================================================
  // PRESENCE
  // ============================================================

  void _listenToRecipientPresence() {
    if (_chatUserId == null) return;

    _recipientPresenceSubscription =
        _firestore
            .collection('users')
            .doc(_chatUserId)
            .snapshots()
            .listen(
      (snapshot) {
        if (!mounted) return;

        final data = snapshot.data();

        final online =
            data?['isOnline'] == true;

        setState(() {
          _isRecipientOnline = online;
          _chatStatus =
              online ? 'Online' : 'Offline';
        });
      },
      onError: (error) {
        debugPrint(
          'Presence listener error: $error',
        );
      },
    );
  }


  // ============================================================
  // MARK MESSAGES DELIVERED
  // ============================================================

  Future<void> _markMessagesDelivered() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _messagesRef
          .where(
            'receiverId',
            isEqualTo: _currentUserId,
          )
          .where(
            'status',
            isEqualTo: 'sent',
          )
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'status': 'delivered',
            'deliveredAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Mark delivered error: $e',
      );
    }
  }


  // ============================================================
  // MARK MESSAGES SEEN
  // ============================================================

  Future<void> _markMessagesSeen() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _messagesRef
          .where(
            'receiverId',
            isEqualTo: _currentUserId,
          )
          .where(
            'status',
            whereIn: [
              'sent',
              'delivered',
            ],
          )
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'status': 'seen',
            'seenAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Mark seen error: $e',
      );
    }
  }


  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage({
    required MessageType type,
    String? text,
    String? mediaUrl,
    double? latitude,
    double? longitude,
    bool liveLocationActive = false,
  }) async {
    if (_currentUserId == null ||
        _chatUserId == null) {
      throw Exception(
        'Chat users are not initialized.',
      );
    }

    final messageRef =
        _messagesRef.doc();

    final messageData = {
      'messageId': messageRef.id,
      'senderId': _currentUserId,
      'receiverId': _chatUserId,
      'type': messageTypeToString(type),
      'text': text,
      'mediaUrl': mediaUrl,
      'latitude': latitude,
      'longitude': longitude,
      'liveLocationActive':
          liveLocationActive,
      'timestamp':
          FieldValue.serverTimestamp(),
      'status': 'sent',
    };

    await messageRef.set(
      messageData,
    );

    String lastMessage = '';

    switch (type) {
      case MessageType.text:
        lastMessage =
            text?.trim().isNotEmpty == true
                ? text!.trim()
                : 'Message';
        break;

      case MessageType.image:
        lastMessage = '📷 Photo';
        break;

      case MessageType.video:
        lastMessage = '🎥 Video';
        break;

      case MessageType.audio:
        lastMessage = '🎙️ Voice message';
        break;

      case MessageType.location:
        lastMessage = '📍 Location';
        break;

      case MessageType.liveLocation:
        lastMessage =
            '📍 Live location';
        break;
    }

    await _conversationRef.set(
      {
        'participants': <String>{
  _currentUserId!,
  _chatUserId!,
}.toList(),
        'lastMessage': lastMessage,
        'lastMessageType':
            messageTypeToString(type),
        'lastSenderId': _currentUserId,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }


  // ============================================================
  // SEND TEXT
  // ============================================================

  Future<void> _sendTextMessage() async {
    if (_isSending) return;

    final text =
        _messageController.text.trim();

    if (text.isEmpty) return;

    _messageController.clear();

    setState(() {
      _isSending = true;
      _showAttachments = false;
    });

    try {
      await _sendMessage(
        type: MessageType.text,
        text: text,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint(
        'Text send error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to send message.',
        );
      }
    } finally {
      if (!mounted) {

      setState(() {
        _isSending = false;
      });}
    }
  }


  // ============================================================
  // UPLOAD MEDIA
  // ============================================================


  Future<void> _uploadAndSendFile(
  File selectedFile,
  MessageType type,
) async {
  if (_isSending) return;

  setState(() {
    _isSending = true;
  });

  try {
    // 1. Compress image or video before uploading
    final fileToUpload = type == MessageType.image
        ? await ChatMediaCompressor.compressImage(selectedFile)
        : type == MessageType.video
            ? await ChatMediaCompressor.compressVideo(selectedFile)
            : selectedFile;

    // 2. Get the file extension
    final fileName = fileToUpload.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    // 3. Upload the compressed file to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_media')
        .child(_conversationId)
        .child('${DateTime.now().millisecondsSinceEpoch}.$extension');

    final metadata = SettableMetadata(
      contentType: type == MessageType.image
          ? 'image/$extension'
          : type == MessageType.video
              ? 'video/$extension'
              : 'application/octet-stream',
    );

    await storageRef.putFile(fileToUpload, metadata);

    // 4. Get Firebase download URL
    final downloadUrl = await storageRef.getDownloadURL();

    // 5. Send the message through your existing Firestore function
    await _sendMessage(
      type: type,
      mediaUrl: downloadUrl,
    );

  } catch (e) {
    debugPrint('Media upload error: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload media: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }
}


  // ============================================================
  // CAMERA PHOTO
  // ============================================================

  Future<void> _takePhoto() async {
    if (_isSending) return;

    try {
      final XFile? picked =
          await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (picked == null) return;

      await _uploadAndSendFile(
        File(picked.path),
        MessageType.image,
      );
    } catch (e) {
      debugPrint(
        'Camera error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to take photo.',
        );
      }
    }
  }


  // ============================================================
  // GALLERY PHOTO
  // ============================================================

  Future<void> _pickImage() async {
    if (_isSending) return;

    try {
      final XFile? picked =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      await _uploadAndSendFile(
        File(picked.path),
        MessageType.image,
      );
    } catch (e) {
      debugPrint(
        'Gallery image error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to select photo.',
        );
      }
    }
  }


  // ============================================================
  // GALLERY VIDEO
  // ============================================================

  Future<void> _pickVideo() async {
    if (_isSending) return;

    try {
      final XFile? picked =
          await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      await _uploadAndSendFile(
        File(picked.path),
        MessageType.video,
      );
    } catch (e) {
      debugPrint(
        'Gallery video error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to select video.',
        );
      }
    }
  }


  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }


  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage(
        'Please turn on location services.',
      );
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is required.',
      );
      return false;
    }

    return true;
  }


  // ============================================================
  // SEND CURRENT LOCATION
  // ============================================================

  Future<void> _sendCurrentLocation() async {
    if (_isSending) return;

    final allowed =
        await _checkLocationPermission();

    if (!allowed) return;

    setState(() {
      _isSending = true;
      _showAttachments = false;
    });

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _sendMessage(
        type: MessageType.location,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _scrollToBottom();

      if (mounted) {
        _showMessage(
          'Location sent',
        );
      }
    } catch (e) {
      debugPrint(
        'Location error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to send location.',
        );
      }
    } finally {
      if (!mounted) {

      setState(() {
        _isSending = false;
      });}
    }
  }


  // ============================================================
  // START LIVE LOCATION
  // ============================================================

  Future<void> _startLiveLocation() async {
    if (_isLiveLocationSharing) return;

    final allowed =
        await _checkLocationPermission();

    if (!allowed) return;

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final messageRef =
          _messagesRef.doc();

      _liveLocationMessageId =
          messageRef.id;

      await messageRef.set(
        {
          'messageId':
              messageRef.id,
          'senderId':
              _currentUserId,
          'receiverId':
              _chatUserId,
          'type':
              messageTypeToString(
            MessageType.liveLocation,
          ),
          'latitude':
              position.latitude,
          'longitude':
              position.longitude,
          'liveLocationActive':
              true,
          'timestamp':
              FieldValue.serverTimestamp(),
          'status':
              'sent',
        },
      );

      await _conversationRef.set(
        {
          'participants': <String>{
  _currentUserId!,
  _chatUserId!,
}.toList(),
          'lastMessage':
              '📍 Live location',
          'lastMessageType':
              'liveLocation',
          'lastSenderId':
              _currentUserId,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _liveLocationSubscription =
          Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (position) {
          _updateLiveLocation(
            position,
          );
        },
        onError: (error) {
          debugPrint(
            'Live location stream error: $error',
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _isLiveLocationSharing = true;
        _showAttachments = false;
      });

      _showMessage(
        'Live location started',
      );
    } catch (e) {
      debugPrint(
        'Start live location error: $e',
      );

      _showMessage(
        'Unable to start live location.',
      );
    }
  }


  // ============================================================
  // UPDATE LIVE LOCATION
  // ============================================================

  Future<void> _updateLiveLocation(
    Position position,
  ) async {
    final messageId =
        _liveLocationMessageId;

    if (messageId == null) return;

    try {
      await _messagesRef
          .doc(messageId)
          .update(
        {
          'latitude':
              position.latitude,
          'longitude':
              position.longitude,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      debugPrint(
        'Update live location error: $e',
      );
    }
  }


  // ============================================================
  // STOP LIVE LOCATION
  // ============================================================

  Future<void> _stopLiveLocation() async {
    final messageId =
        _liveLocationMessageId;

    await _liveLocationSubscription
        ?.cancel();

    _liveLocationSubscription = null;

    if (messageId != null) {
      try {
        await _messagesRef
            .doc(messageId)
            .update(
          {
            'liveLocationActive':
                false,
            'endedAt':
                FieldValue.serverTimestamp(),
          },
        );
      } catch (e) {
        debugPrint(
          'Stop live location error: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      _isLiveLocationSharing = false;
      _liveLocationMessageId = null;
    });

    _showMessage(
      'Live location stopped',
    );
  }


  // ============================================================
  // START VOICE RECORDING
  // ============================================================

  Future<void> _startRecording() async {
    if (_isRecording ||
        _isSending) {
      return;
    }

    try {
      final hasPermission =
          await _audioRecorder
              .hasPermission();

      if (!hasPermission) {
        _showMessage(
          'Microphone permission is required.',
        );
        return;
      }

      final directory =
          await getTemporaryDirectory();

      final path =
          '${directory.path}/voice_'
          '${DateTime.now().millisecondsSinceEpoch}'
          '.m4a';

      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(
        config,
        path: path,
      );

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
    } catch (e) {
      debugPrint(
        'Start recording error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to start voice recording.',
        );
      }
    }
  }


  // ============================================================
  // STOP VOICE RECORDING
  // ============================================================

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path =
          await _audioRecorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      final finalPath =
          path ?? _recordingPath;

      _recordingPath = null;

      if (finalPath == null) {
        _showMessage(
          'Voice recording was not created.',
        );
        return;
      }

      final file =
          File(finalPath);

      if (!await file.exists()) {
        _showMessage(
          'Voice recording file not found.',
        );
        return;
      }

      await _uploadAudio(file);
    } catch (e) {
      debugPrint(
        'Stop recording error: $e',
      );

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingPath = null;
        });

        _showMessage(
          'Unable to send voice message.',
        );
      }
    }
  }


  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();

      final path = _recordingPath;

      _recordingPath = null;

      if (path != null) {
        final file = File(path);

        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint(
        'Cancel recording error: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _isRecording = false;
    });
  }


  // ============================================================
  // UPLOAD AUDIO
  // ============================================================

  Future<void> _uploadAudio(
    File file,
  ) async {
    if (_isSending) return;

    if (_currentUserId == null ||
        _chatUserId == null) {
      _showMessage(
        'Chat is not ready.',
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final fileName =
          'voice_'
          '${DateTime.now().millisecondsSinceEpoch}'
          '.m4a';

      final storagePath =
          'chat_media/'
          '$_conversationId/'
          'audio/'
          '$fileName';

      final storageRef =
          _storage.ref().child(storagePath);

      final metadata =
          SettableMetadata(
        contentType: 'audio/mp4',
        customMetadata: {
          'senderId':
              _currentUserId!,
          'receiverId':
              _chatUserId!,
          'conversationId':
              _conversationId,
        },
      );

      debugPrint(
        'Uploading voice message...',
      );

      await storageRef.putFile(
        file,
        metadata,
      );

      final downloadUrl =
          await storageRef.getDownloadURL();

      await _sendMessage(
        type: MessageType.audio,
        mediaUrl: downloadUrl,
      );

      if (await file.exists()) {
        await file.delete();
      }

      _scrollToBottom();

      if (mounted) {
        _showMessage(
          'Voice message sent',
        );
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Voice Firebase error: ${e.code}',
      );

      debugPrint(
        'Voice Firebase message: ${e.message}',
      );

      if (mounted) {
        _showMessage(
          'Voice upload failed: ${e.code}',
        );
      }
    } catch (e) {
      debugPrint(
        'Voice upload error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to send voice message.',
        );
      }
    } finally {
      if (!mounted) {

      setState(() {
        _isSending = false;
      });}
    }
  }


  // ============================================================
  // MESSAGE FROM FIRESTORE
  // ============================================================

  ChatMessage _messageFromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data() ?? {};

    final timestamp =
        data['timestamp'];

    DateTime messageTime;

    if (timestamp is Timestamp) {
      messageTime =
          timestamp.toDate();
    } else {
      messageTime =
          DateTime.now();
    }

    final senderId =
        (data['senderId'] ?? '')
            .toString();

    final receiverId =
        (data['receiverId'] ?? '')
            .toString();

    final type =
        stringToMessageType(
      (data['type'] ?? 'text')
          .toString(),
    );

    double? latitude;

    final latValue =
        data['latitude'];

    if (latValue is num) {
      latitude =
          latValue.toDouble();
    }

    double? longitude;

    final lngValue =
        data['longitude'];

    if (lngValue is num) {
      longitude =
          lngValue.toDouble();
    }

    return ChatMessage(
      messageId:
          (data['messageId'] ??
                  doc.id)
              .toString(),
      senderId: senderId,
      receiverId: receiverId,
      text: data['text']?.toString(),
      mediaUrl:
          data['mediaUrl']?.toString(),
      latitude: latitude,
      longitude: longitude,
      time: messageTime,
      isMe:
          senderId ==
          _currentUserId,
      type: type,
      status:
          (data['status'] ??
                  'sent')
              .toString(),
      liveLocationActive:
          data['liveLocationActive'] ==
              true,
    );
  }


  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(DateTime time) {
    final hour =
        time.hour % 12 == 0
            ? 12
            : time.hour % 12;

    final minute =
        time.minute
            .toString()
            .padLeft(2, '0');

    final period =
        time.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // OPEN MAP
  // ============================================================

  Future<void> _openLocation(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/'
      '?api=1&query=$latitude,$longitude',
    );

    try {
      final launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'Unable to open map.',
        );
      }
    } catch (e) {
      debugPrint(
        'Map error: $e',
      );
    }
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFEFE7DE),

      appBar:
          _buildChatHeader(),

      body: SafeArea(
  child: Column(
    children: [
      // Only taxi chats show the ride panel.
      if (_isTaxiChat)
        _buildTaxiRidePanel(),

      Expanded(
        child: _buildMessageList(),
      ),

      if (_showAttachments)
        _buildAttachmentPanel(),

      _buildMessageInput(),
    ],
  ),
),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  PreferredSizeWidget _buildChatHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      automaticallyImplyLeading: true,
      titleSpacing: 0,

      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Colors.grey.shade200,
            child: const Icon(
              Icons.person,
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  _chatName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                Text(
                  _isRecipientOnline
                      ? 'Online'
                      : _chatStatus,
                  style: TextStyle(
                    color:
                        _isRecipientOnline
                            ? Colors.green
                            : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
  PopupMenuButton<String>(
    icon: const Icon(
      Icons.more_vert,
      color: Colors.red,
    ),
    onSelected: _handleMenuAction,
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'search',
        child: Row(
          children: [
            Icon(Icons.search),
            SizedBox(width: 12),
            Text('Search'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'clear',
        child: Row(
          children: [
            Icon(Icons.delete_outline),
            SizedBox(width: 12),
            Text('Clear chat'),
          ],
        ),
      ),
    ],
  ),
],
    );
  }

  Future<void> _handleMenuAction(
    String value,
  ) async {
    switch (value) {
      case 'search':
        _showMessage(
          'Chat search can be added here.',
        );
        break;

      case 'clear':
        await _clearChat();
        break;
    }
  }


  // ============================================================
  // CLEAR CHAT
  // ============================================================

  Future<void> _clearChat() async {
    try {
      final snapshot =
          await _messagesRef.get();

      if (snapshot.docs.isEmpty) {
        _showMessage(
          'Chat is already empty.',
        );
        return;
      }

      final batch =
          _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(
          doc.reference,
        );
      }

      await batch.commit();

      if (mounted) {
        _showMessage(
          'Chat cleared.',
        );
      }
    } catch (e) {
      debugPrint(
        'Clear chat error: $e',
      );

      _showMessage(
        'Unable to clear chat.',
      );
    }
  }


  // ============================================================
  // MESSAGE LIST
  // ============================================================

  Widget _buildMessageList() {
    if (_conversationId.isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesRef
          .orderBy(
            'timestamp',
            descending: false,
          )
          .snapshots(),

      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Text(
                'Unable to load messages.\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return Center(
            child: Text(
              'Start a conversation with $_chatName',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          );
        }

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            _scrollToBottom();
          },
        );

        return ListView.builder(
          controller:
              _scrollController,
          padding:
              const EdgeInsets.fromLTRB(
            10,
            12,
            10,
            12,
          ),
          itemCount:
              documents.length,
          itemBuilder:
              (context, index) {
            final message =
                _messageFromDocument(
              documents[index],
            );

            return _buildMessageBubble(
              message,
            );
          },
        );
      },
    );
  }


  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(
    ChatMessage message,
  ) {
    final bubbleColor =
        message.isMe
            ? const Color(0xFFD9FDD3)
            : Colors.white;

    return Align(
      alignment:
          message.isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                  .size
                  .width *
                  0.80,
        ),

        margin:
            const EdgeInsets.only(
          bottom: 6,
        ),

        padding:
            const EdgeInsets.all(7),

        decoration:
            BoxDecoration(
          color: bubbleColor,
          borderRadius:
              BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                    alpha: 0.04,
                  ),
              blurRadius: 2,
              offset:
                  const Offset(0, 1),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            _buildMessageContent(
              message,
            ),

            const SizedBox(height: 3),

            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  _formatTime(
                    message.time,
                  ),
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),

                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  _buildMessageStatus(
                    message.status,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // MESSAGE CONTENT
  // ============================================================

  Widget _buildMessageContent(
    ChatMessage message,
  ) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(
          message,
        );

      case MessageType.image:
        return _buildImageMessage(
          message,
        );

      case MessageType.video:
        return _buildVideoMessage(
          message,
        );

      case MessageType.audio:
        return _buildAudioMessage(
          message,
        );

      case MessageType.location:
        return _buildLocationMessage(
          message,
          false,
        );

      case MessageType.liveLocation:
        return _buildLocationMessage(
          message,
          true,
        );
    }
  }


  // ============================================================
  // TEXT
  // ============================================================

  Widget _buildTextMessage(
    ChatMessage message,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message.text ?? '',
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }


  // ============================================================
  // IMAGE
  // ============================================================

Widget _buildImageMessage(ChatMessage message) {
  final url = message.mediaUrl;

  if (url == null || url.isEmpty) {
    return const Text('Photo unavailable');
  }

  return FutureBuilder<File>(
    future: ChatMediaCache.getOrDownload(
      messageId: message.messageId,
      url: url,
      extension: 'jpg',
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          width: 240,
          height: 260,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (snapshot.hasError || !snapshot.hasData) {
        return const SizedBox(
          width: 240,
          height: 180,
          child: Center(
            child: Icon(Icons.broken_image, size: 50),
          ),
        );
      }

      final file = snapshot.data!;

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(
                imageUrl: url,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 240,
            height: 260,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return const Icon(Icons.broken_image);
            },
          ),
        ),
      );
    },
  );
}


  // ============================================================
  // VIDEO
  // ============================================================

  Widget _buildVideoMessage(
    ChatMessage message,
  ) {
    final url =
        message.mediaUrl;

    if (url == null ||
        url.isEmpty) {
      return const Text(
        'Video unavailable',
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VideoPlayerScreen(
              videoUrl: url,
              messageId: message.messageId,
            ),
          ),
        );
      },

      child: Container(
        width: 240,
        height: 180,
        decoration:
            BoxDecoration(
          color: Colors.black,
          borderRadius:
              BorderRadius.circular(8),
        ),

        child: const Center(
          child: CircleAvatar(
            radius: 30,
            backgroundColor:
                Colors.white,
            child: Icon(
              Icons.play_arrow,
              color: Colors.black,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }


  // ============================================================
  // AUDIO
  // ============================================================

  Widget _buildAudioMessage(
    ChatMessage message,
  ) {
    final url =
        message.mediaUrl;

    if (url == null ||
        url.isEmpty) {
      return const Text(
        'Voice message unavailable',
      );
    }

    return AudioMessageBubble(
      audioUrl: url,
      messageId: message.messageId,
      isMe: message.isMe,
    );
  }


  // ============================================================
  // LOCATION
  // ============================================================

  Widget _buildLocationMessage(
    ChatMessage message,
    bool isLive,
  ) {
    final latitude =
        message.latitude;

    final longitude =
        message.longitude;

    if (latitude == null ||
        longitude == null) {
      return const Text(
        'Location unavailable',
      );
    }

    return GestureDetector(
      onTap: () {
        _openLocation(
          latitude,
          longitude,
        );
      },

      child: Container(
        width: 230,
        padding:
            const EdgeInsets.all(10),

        decoration:
            BoxDecoration(
          color:
              Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(10),
        ),

        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  isLive
                      ? Colors.red
                      : Colors.green,

              child: Icon(
                isLive
                    ? Icons.my_location
                    : Icons.location_on,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    isLive
                        ? 'Live location'
                        : 'Location',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    isLive &&
                            message
                                .liveLocationActive
                        ? 'Live now'
                        : 'Tap to view map',
                    style:
                        TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // MESSAGE STATUS
  // ============================================================

  Widget _buildMessageStatus(
    String status,
  ) {
    if (status == 'seen') {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.blue,
      );
    }

    if (status == 'delivered') {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.grey,
      );
    }

    return const Icon(
      Icons.done,
      size: 15,
      color: Colors.grey,
    );
  }


  // ============================================================
  // ATTACHMENT PANEL
  // ============================================================

  Widget _buildAttachmentPanel() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),

      color: Colors.white,

      child: Wrap(
        spacing: 20,
        runSpacing: 12,

        children: [
          _attachmentButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _takePhoto,
          ),

          _attachmentButton(
            icon: Icons.photo,
            label: 'Gallery',
            onTap: _pickImage,
          ),

          _attachmentButton(
            icon: Icons.video_library,
            label: 'Video',
            onTap: _pickVideo,
          ),

          _attachmentButton(
            icon: Icons.location_on,
            label: 'Location',
            onTap:
                _sendCurrentLocation,
          ),

          _attachmentButton(
            icon: Icons.my_location,
            label: 'Live',
           onTap: () async {
  if (_isLiveLocationSharing) {
    await _stopLiveLocation();
  } else {
    await _startLiveLocation();
  }
},
          ),
        ],
      ),
    );
  }


  Widget _attachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap:
          _isSending
              ? null
              : onTap,

      child: SizedBox(
        width: 65,

        child: Column(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor:
                  Colors.red.shade50,

              child: Icon(
                icon,
                color: Colors.red,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              label,
              style:
                  const TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // MESSAGE INPUT
  // ============================================================

  Widget _buildMessageInput() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        8,
        6,
        8,
        6,
      ),

      color: Colors.white,

      child: _isRecording
          ? _buildRecordingInput()
          : _buildNormalInput(),
    );
  }


  // ============================================================
  // RECORDING INPUT
  // ============================================================

  Widget _buildRecordingInput() {
    return Row(
      children: [
        IconButton(
          tooltip:
              'Delete recording',
          onPressed:
              _cancelRecording,
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
        ),

        const Expanded(
          child: Text(
            'Recording voice message…',
            style: TextStyle(
              color: Colors.red,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Send voice',
          onPressed:
              _isSending
                  ? null
                  : _stopRecording,
          icon: const Icon(
            Icons.send,
            color: Colors.red,
          ),
        ),
      ],
    );
  }


  // ============================================================
  // NORMAL INPUT
  // ============================================================

  Widget _buildNormalInput() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        IconButton(
          tooltip:
              'Attachments',

          onPressed: () {
            setState(() {
              _showAttachments =
                  !_showAttachments;
            });
          },

          icon: Icon(
            _showAttachments
                ? Icons.close
                : Icons.add,
            color: Colors.red,
          ),
        ),

        Expanded(
          child: Container(
            constraints:
                const BoxConstraints(
              maxHeight: 120,
            ),

            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(24),
            ),

            child: TextField(
              controller:
                  _messageController,

              maxLines: 5,
              minLines: 1,

              textCapitalization:
                  TextCapitalization.sentences,

              decoration:
                  const InputDecoration(
                hintText:
                    'Message',
                border:
                    InputBorder.none,
              ),
            ),
          ),
        ),

        ValueListenableBuilder<
            TextEditingValue>(
          valueListenable:
              _messageController,

          builder:
              (
            context,
            value,
            child,
          ) {
            final hasText =
                value.text
                    .trim()
                    .isNotEmpty;

            return IconButton(
              tooltip:
                  hasText
                      ? 'Send'
                      : 'Voice message',

              onPressed:
                  _isSending
                      ? null
                      : hasText
                          ? _sendTextMessage
                          : _startRecording,

              icon: Icon(
                hasText
                    ? Icons.send
                    : Icons.mic,
                color:
                    Colors.red,
              ),
            );
          },
        ),
      ],
    );
  }


  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _liveLocationSubscription
        ?.cancel();

    _recipientPresenceSubscription
        ?.cancel();

    _audioRecorder.dispose();

    _messageController.dispose();

    _scrollController.dispose();

    _taxiRideSubscription?.cancel();

    super.dispose();
  }
}


// ============================================================
// FULL SCREEN IMAGE
// ============================================================

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,

            errorBuilder:
                (
              context,
              error,
              stackTrace,
            ) {
              return const Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 70,
              );
            },
          ),
        ),
      ),
    );
  }
}


// ============================================================
// VIDEO PLAYER
// ============================================================

class VideoPlayerScreen
    extends StatefulWidget {
  final String videoUrl;
  final String messageId;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.messageId
  });

  @override
  State<VideoPlayerScreen>
      createState() =>
          _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;

  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }


  Future<void> _initializeVideo() async {
  try {
    final file = await ChatMediaCache.getOrDownload(
      messageId: widget.messageId,
      url: widget.videoUrl,
      extension: 'mp4',
    );

    if (!mounted) return;

    final controller = VideoPlayerController.file(file);

    _controller = controller;

    await controller.initialize();

    if (!mounted) return;

    setState(() {
      _initialized = true;
    });

    await controller.play();
  } catch (e) {
    debugPrint('Video initialization error: $e');

    if (!mounted) return;

    setState(() {
      _hasError = true;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _hasError
            ? const Text(
                'Unable to load video. Please try again.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              )
            : !_initialized || controller == null
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : AspectRatio(
                    aspectRatio:
                        controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(controller),
                        IconButton(
                          iconSize: 64,
                          color: Colors.white,
                          onPressed: () async {
                            if (controller.value.isPlaying) {
                              await controller.pause();
                            } else {
                              await controller.play();
                            }

                            if (mounted) setState(() {});
                          },
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}


// ============================================================
// AUDIO MESSAGE BUBBLE
// ============================================================

class AudioMessageBubble
    extends StatefulWidget {

  final String audioUrl;
 final String messageId;
  final bool isMe;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.messageId,
    required this.isMe,
  });

  @override
  State<AudioMessageBubble>
      createState() =>
          _AudioMessageBubbleState();
}


class _AudioMessageBubbleState
    extends State<AudioMessageBubble> {
  final AudioPlayer _player = AudioPlayer();

  bool _loading = false;
  bool _playing = false;
  String? _loadedUrl;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // StreamSubscription<Duration>?
  //     _positionSubscription;
  // StreamSubscription<Duration>?
  //     _durationSubscription;
  StreamSubscription<Duration?>?
    _positionSubscription;

StreamSubscription<Duration?>?
    _durationSubscription;
  StreamSubscription<PlayerState>?
      _playerStateSubscription;

  @override
  void initState() {
    super.initState();

    _positionSubscription =
        _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _durationSubscription =
        _player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      setState(() => _duration = duration);
    });

    _playerStateSubscription =
        _player.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _playing = state.playing;

        if (state.processingState ==
            ProcessingState.completed) {
          _playing = false;
          _position = Duration.zero;
        }
      });
    });
  }

  @override
  void didUpdateWidget(
    covariant AudioMessageBubble oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.audioUrl != widget.audioUrl) {
      _loadedUrl = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    }
  }

  Future<void> _togglePlay() async {
  if (_loading) return;

  try {
    if (_playing) {
      await _player.pause();
      return;
    }

    setState(() => _loading = true);

    // Download audio and save it locally.
    // If already downloaded, use the cached file.
    if (_loadedUrl != widget.audioUrl) {
      final file = await ChatMediaCache.getOrDownload(
        messageId: widget.messageId,
        url: widget.audioUrl,
        extension: 'm4a',
      );

      // Play audio from local storage.
      await _player.setFilePath(file.path);

      _loadedUrl = widget.audioUrl;
    }

    // Replay from beginning after completion.
    if (_player.processingState ==
        ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }

    await _player.play();

  } catch (e) {
    debugPrint('Audio playback error: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to play voice message. '
            'Please check your internet connection.',
          ),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes
        .toString()
        .padLeft(2, '0');

    final seconds = (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds;
    final positionMs = _position.inMilliseconds
        .clamp(0, maxMs > 0 ? maxMs : 1);

    return SizedBox(
      width: 240,
      child: Row(
        children: [
          IconButton(
            onPressed: _loading ? null : _togglePlay,
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.red,
                  ),
          ),
          Expanded(
            child: Column(
              children: [
                Slider(
                  value: positionMs.toDouble(),
                  max: maxMs > 0 ? maxMs.toDouble() : 1,
                  onChanged: maxMs <= 0
                      ? null
                      : (value) {
                          _player.seek(
                            Duration(
                              milliseconds: value.round(),
                            ),
                          );
                        },
                  activeColor: Colors.red,
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}
