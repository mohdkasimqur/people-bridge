import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screen_message.dart';

class ScreenChat extends StatefulWidget {
  const ScreenChat({super.key});

  @override
  State<ScreenChat> createState() => _ScreenChatState();
}

class _ScreenChatState extends State<ScreenChat> {
  static const Color green = Color(0xFF16803C);
  static const Color darkGreen = Color(0xFF12652F);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController =
      TextEditingController();

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _chats = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  String _searchText = '';

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();

    _loadChats();

    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.position.extentAfter < 300) {
        _loadMoreChats();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _chatQuery() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: _uid)
        .orderBy('updatedAt', descending: true);
  }

  Future<void> _loadChats({bool refresh = false}) async {
    if (_uid.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (refresh) {
      _chats.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    if (!_hasMore) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final snapshot = await _chatQuery().limit(30).get();

      if (!mounted) return;

      _chats
        ..clear()
        ..addAll(snapshot.docs);

      _lastDocument =
          snapshot.docs.isEmpty ? null : snapshot.docs.last;

      _hasMore = snapshot.docs.length == 30;
    } on FirebaseException catch (e) {
      debugPrint('Chat list error: ${e.code} ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'failed-precondition'
                  ? 'A Firestore index is required for the chat list.'
                  : 'Could not load chats. Please try again.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Chat list error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMoreChats() async {
    if (_loadingMore ||
        !_hasMore ||
        _lastDocument == null ||
        _uid.isEmpty) {
      return;
    }

    setState(() => _loadingMore = true);

    try {
      final snapshot = await _chatQuery()
          .startAfterDocument(_lastDocument!)
          .limit(30)
          .get();

      if (!mounted) return;

      final existingIds = _chats.map((doc) => doc.id).toSet();

      for (final doc in snapshot.docs) {
        if (existingIds.add(doc.id)) {
          _chats.add(doc);
        }
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length == 30;
    } catch (e) {
      debugPrint('Load more chats error: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  String _otherUid(Map<String, dynamic> data) {
  final participants = (data['participants'] as List?)
          ?.map((e) => e.toString())
          .toSet()
          .toList() ??
      [];

  // Normal conversation: return the other person's UID.
  for (final id in participants) {
    if (id != _uid) {
      return id;
    }
  }

  // Self-chat: the current user is the only participant.
  if (participants.contains(_uid)) {
    return _uid;
  }

  return '';
}

  Map<String, dynamic> _participantDetails(
    Map<String, dynamic> data,
    String otherUid,
  ) {
    final details = data['participantDetails'];

    if (details is Map && details[otherUid] is Map) {
      return Map<String, dynamic>.from(details[otherUid] as Map);
    }

    return {};
  }

  String _contactName(
  Map<String, dynamic> data,
  String otherUid,
) {
  final details = _participantDetails(data, otherUid);

  final detailName =
      (details['name'] ?? '').toString().trim();

  final names = data['participantNames'];
  String storedName = '';

  if (names is Map) {
    storedName = (names[otherUid] ?? '').toString().trim();
  }

  // Clearly identify a conversation with yourself.
  if (otherUid == _uid) {
    if (detailName.isNotEmpty &&
        detailName.toLowerCase() != 'me' &&
        detailName.toLowerCase() != 'you') {
      return detailName;
    }

    if (storedName.isNotEmpty &&
        storedName.toLowerCase() != 'me' &&
        storedName.toLowerCase() != 'you') {
      return storedName;
    }

    return 'You';
  }

  if (detailName.isNotEmpty) {
    return detailName;
  }

  if (storedName.isNotEmpty &&
      storedName.toLowerCase() != 'me') {
    return storedName;
  }

  return 'Contact';
}

  String _preview(Map<String, dynamic> data) {
    final type =
        (data['lastMessageType'] ?? 'text').toString();

    final message =
        (data['lastMessage'] ?? '').toString().trim();

    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎤 Voice message';
      case 'location':
        return '📍 Location';
      case 'liveLocation':
        return '📍 Live location';
      default:
        return message.isEmpty
            ? 'Start a conversation'
            : message;
    }
  }

  String _formatTime(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is int) {
      date = DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (date == null) return '';

    final local = date.toLocal();
    final now = DateTime.now();

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    if (now.difference(local).inDays < 7) {
      const weekdays = [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
      ];

      return weekdays[local.weekday - 1];
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      get _filteredChats {
    final search = _searchText.trim().toLowerCase();

    if (search.isEmpty) return _chats;

    return _chats.where((doc) {
      final data = doc.data();
      final uid = _otherUid(data);
      final name = _contactName(data, uid).toLowerCase();
      final preview = _preview(data).toLowerCase();
      final details = _participantDetails(data, uid);

      final category =
          (details['category'] ?? '').toString().toLowerCase();

      return name.contains(search) ||
          preview.contains(search) ||
          category.contains(search);
    }).toList();
  }

  Future<void> _openChat(
    Map<String, dynamic> data,
  ) async {
    final otherUid = _otherUid(data);

    if (otherUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This conversation has no valid recipient.'),
        ),
      );
      return;
    }

    final details = _participantDetails(data, otherUid);
    final name = _contactName(data, otherUid);

    final chatUser = <String, dynamic>{
      ...details,
      'uid': otherUid,
      'userId': otherUid,
      'id': otherUid,
      'name': name,
    };

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScreenMessage(chatUser: chatUser),
      ),
    );

    if (mounted) {
      _loadChats(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: green,
          foregroundColor: Colors.white,
          title: const Text('Chats'),
        ),
        body: const Center(
          child: Text('Please log in to view your chats.'),
        ),
      );
    }

    final chats = _filteredChats;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _loadChats(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchText = value);
              },
              decoration: InputDecoration(
                hintText: 'Search people or categories',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF4F6F4),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: green,
              onRefresh: () => _loadChats(refresh: true),
              child: _loading && _chats.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: green),
                    )
                  : chats.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 140),
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 58,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 14),
                            Center(
                              child: Text(
                                'No conversations yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 25,
                              ),
                              child: Text(
                                'Start a conversation with a person '
                                'from any category.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          itemCount:
                              chats.length + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const Divider(
                            height: 1,
                            indent: 76,
                            color: Color(0xFFEDEDED),
                          ),
                          itemBuilder: (context, index) {
                            if (index >= chats.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: green,
                                  ),
                                ),
                              );
                            }

                            final doc = chats[index];
                            final data = doc.data();
                            final otherUid = _otherUid(data);
                            final name =
                                _contactName(data, otherUid);
                            final preview = _preview(data);
                            final time =
                                _formatTime(data['updatedAt']);

                            final details =
                                _participantDetails(data, otherUid);

                            final category =
                                (details['category'] ?? '')
                                    .toString()
                                    .trim();

                            final isSelfChat = otherUid == _uid;

final subtitle = isSelfChat || category.isEmpty
    ? preview
    : '$category · $preview';

                            final photoUrl =
                                (details['photoUrl'] ?? '')
                                    .toString()
                                    .trim();

                            return ListTile(
                              onTap: () => _openChat(data),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    const Color(0xFFE0F2E7),
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: darkGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 5),
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                time,
                                style: const TextStyle(
                                  color: Color(0xFF777777),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}