import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/component_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Components ──────────────────────────────────────────────────────
  Stream<QuerySnapshot> getComponents({String? type}) {
    Query q = _db.collection('components');
    if (type != null) q = q.where('type', isEqualTo: type);
    return q.snapshots();
  }

  Stream<QuerySnapshot> getComponentsInStock({required String type}) {
    return _db
        .collection('components')
        .where('type', isEqualTo: type)
        .where('inStock', isEqualTo: true)
        .snapshots();
  }

  Future<void> addComponent(Map<String, dynamic> data) =>
      _db.collection('components').add(data);

  Future<void> updateComponent(String id, Map<String, dynamic> data) =>
      _db.collection('components').doc(id).update(data);

  Future<void> deleteComponent(String id) =>
      _db.collection('components').doc(id).delete();

  // ── Orders ──────────────────────────────────────────────────────────
  Future<void> placeOrder(
  Map<String, ComponentModel?> build,
  double total, {
  String description = '',
  double discount = 0,
}) async {
    final items = build.entries
        .where((e) => e.value != null)
        .map((e) => {
              'componentId': e.value!.id,
              'type': e.key,
              'name': e.value!.name,
              'price': e.value!.price,
              'emoji': e.value!.emoji,
            })
        .toList();

    await _db.collection('orders').add({
      'userId': _uid,
      'items': items,
      'total': total,
      'discount': discount,
      'status': 'pending',
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMyOrders() => _db
      .collection('orders')
      .where('userId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<QuerySnapshot> getAllOrders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> updateOrderStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({'status': status});

  // ── Discounts ────────────────────────────────────────────────────────
  Stream<QuerySnapshot> getDiscounts() =>
      _db.collection('discounts').snapshots();

  Future<void> addDiscount(Map<String, dynamic> data) =>
      _db.collection('discounts').add(data);

  Future<void> updateDiscount(String id, Map<String, dynamic> data) =>
      _db.collection('discounts').doc(id).update(data);

  Future<void> deleteDiscount(String id) =>
      _db.collection('discounts').doc(id).delete();

  Future<DocumentSnapshot?> validateDiscount(String code) async {
    final snap = await _db
        .collection('discounts')
        .where('code', isEqualTo: code.toUpperCase())
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  // ── Chat ─────────────────────────────────────────────────────────────

  /// Customer sends a message
  Future<void> sendMessage(String text, {String? chatUserId}) async {
    final id = chatUserId ?? _uid;

    await _db.collection('chats').doc(id).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'customerId': id,
    }, SetOptions(merge: true));

    await _db.collection('chats').doc(id).collection('messages').add({
      'senderId': _uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Admin replies to a customer
  Future<void> adminReply(String customerId, String text) async {
    await _db.collection('chats').doc(customerId).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db
        .collection('chats')
        .doc(customerId)
        .collection('messages')
        .add({
      'senderId': _uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Stream<QuerySnapshot> getMessages({String? chatUserId}) {
    final id = chatUserId ?? _uid;
    return _db
        .collection('chats')
        .doc(id)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Stream<QuerySnapshot> getAllChats() => _db
      .collection('chats')
      .orderBy('lastMessageTime', descending: true)
      .snapshots();
}