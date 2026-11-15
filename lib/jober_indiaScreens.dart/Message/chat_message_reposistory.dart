import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessagesRepository {
  ChatMessagesRepository(this.conversationId);

  final String conversationId;

  static const int pageSize = 40;

  CollectionReference<Map<String, dynamic>> get _messages =>
      FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

  // Only the newest 40 messages update in real time.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchLatestMessages() {
    return _messages
        .orderBy('timestamp', descending: true)
        .limit(pageSize)
        .snapshots();
  }

  // Load older messages only when needed.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchOlderMessages({
    required DocumentSnapshot<Map<String, dynamic>> oldestLoadedMessage,
  }) {
    return _messages
        .orderBy('timestamp', descending: true)
        .startAfterDocument(oldestLoadedMessage)
        .limit(pageSize)
        .get();
  }
}