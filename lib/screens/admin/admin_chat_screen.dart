import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';

// ── Design tokens ─────────────────────────────────────────────
const _primary = Color(0xFF1A6BFF);
const _primaryDark = Color(0xFF0D47A1);
const _surface = Color(0xFFF5F7FF);
const _purple = Color(0xFF9C27B0);

// ════════════════════════════════════════════════════════════════
// Chat List Screen
// ════════════════════════════════════════════════════════════════
class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [

          // ── Gradient Header ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryDark, _primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.chat_bubble_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text('Messages',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer Support',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                              )),
                          const SizedBox(height: 4),
                          Text('Customer chats',
                              style: GoogleFonts.syne(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chat List ──────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.getAllChats(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primary));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 34, color: _purple),
                        ),
                        const SizedBox(height: 16),
                        Text('No Chats Yet',
                            style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            )),
                        const SizedBox(height: 6),
                        Text('Customer messages will appear here.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[500],
                            )),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: docs.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${docs.length} CONVERSATION${docs.length == 1 ? '' : 'S'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    }

                    final doc = docs[i - 1];
                    final data = doc.data() as Map<String, dynamic>;
                    final chatId = doc.id;
                    final lastMessage =
                        data['lastMessage'] ?? 'No messages yet';
                    final customerName = (data['customerName'] ?? '').toString().trim();
                    final displayName = customerName.isNotEmpty
                        ? customerName
                        : 'Customer ${chatId.substring(0, 8)}...';
                    final initials = customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : chatId.substring(0, 2).toUpperCase();

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => _AdminChatDetail(
                                customerId: chatId,
                                customerName: displayName)),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(initials,
                                      style: GoogleFonts.syne(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _purple,
                                      )),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Chevron
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.grey[300], size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Chat Detail Screen
// ════════════════════════════════════════════════════════════════
class _AdminChatDetail extends StatefulWidget {
  final String customerId;
  final String customerName;
  const _AdminChatDetail({required this.customerId, required this.customerName});

  @override
  State<_AdminChatDetail> createState() => _AdminChatDetailState();
}

class _AdminChatDetailState extends State<_AdminChatDetail> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _adminUid = FirebaseAuth.instance.currentUser!.uid;
  bool _sending = false;

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _ctrl.clear();

    await FirestoreService().adminReply(widget.customerId, text);

    setState(() => _sending = false);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.customerName.isNotEmpty
        ? widget.customerName[0].toUpperCase()
        : widget.customerId.substring(0, 2).toUpperCase();

    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [

          // ── Gradient Header ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryDark, _primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 18),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Customer avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: GoogleFonts.syne(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.customerName,
                              style: GoogleFonts.syne(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                          Text('Active conversation',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white60,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Messages ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService()
                  .getMessages(chatUserId: widget.customerId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _primary));
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('No messages yet',
                            style: GoogleFonts.inter(
                                color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final msg = ChatMessage.fromFirestore(docs[i]);
                    final isAdmin = msg.senderId == _adminUid;

                    // Show date separator when the day changes
                    bool showSeparator = false;
                    if (msg.timestamp != null) {
                      if (i == 0) {
                        showSeparator = true;
                      } else {
                        final prev =
                            ChatMessage.fromFirestore(docs[i - 1]);
                        if (prev.timestamp != null) {
                          final prevDate = DateTime(prev.timestamp!.year,
                              prev.timestamp!.month, prev.timestamp!.day);
                          final currDate = DateTime(msg.timestamp!.year,
                              msg.timestamp!.month, msg.timestamp!.day);
                          showSeparator = currDate.isAfter(prevDate);
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (showSeparator && msg.timestamp != null)
                          _DateSeparator(date: msg.timestamp!),
                        _MessageBubble(msg: msg, isAdmin: isAdmin),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input Bar ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          style: GoogleFonts.inter(fontSize: 14),
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Reply to customer...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Send button
                    GestureDetector(
                      onTap: _sending ? null : _send,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryDark, _primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _sending
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Date Separator
// ════════════════════════════════════════════════════════════════
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    // Same year → "Apr 9", different year → "Apr 9, 2025"
    if (d.year == now.year) return DateFormat('MMM d').format(date);
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _label(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Message Bubble
// ════════════════════════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isAdmin;

  const _MessageBubble({required this.msg, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isAdmin
                    ? const LinearGradient(
                        colors: [_primaryDark, _primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isAdmin ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAdmin ? 16 : 4),
                  bottomRight: Radius.circular(isAdmin ? 4 : 16),
                ),
                border: isAdmin
                    ? null
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isAdmin ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

            // Timestamp
            if (msg.timestamp != null) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  DateFormat('h:mm a').format(msg.timestamp!),  // date shown by separator above
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}