import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      print('🔐 Signing in: $email');
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('✅ Auth sign in success! UID: ${cred.user!.uid}');

      final uid = cred.user!.uid;
      DocumentSnapshot doc;

      try {
        doc = await _db
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 8), onTimeout: () {
          print('⚠️ Server timeout, falling back to cache');
          return _db.collection('users').doc(uid).get();
        });
      } catch (_) {
        doc = await _db.collection('users').doc(uid).get();
      }

      print('📄 User doc exists: ${doc.exists}');
      print('📄 User data: ${doc.data()}');
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      print('📝 Creating auth account for $email...');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print('✅ Auth created! UID: ${cred.user!.uid}');

      print('💾 Writing to Firestore...');
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'name': name.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore user document created!');
    } catch (e) {
      print('❌ Register error: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final uid = currentUid;
      if (uid == null) {
        print('⚠️ No current user');
        return null;
      }
      print('🔍 Fetching role for UID: $uid');

      DocumentSnapshot doc;
      try {
        doc = await _db
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 8), onTimeout: () {
          print('⚠️ Server timeout, falling back to cache');
          return _db.collection('users').doc(uid).get();
        });
      } catch (_) {
        doc = await _db.collection('users').doc(uid).get();
      }

      final role = doc.data() != null
          ? (doc.data() as Map<String, dynamic>)['role'] as String?
          : null;
      print('👤 User role: $role');
      return role;
    } catch (e) {
      print('❌ Get role error: $e');
      return null;
    }
  }

  Future<void> signOut() => _auth.signOut();
}