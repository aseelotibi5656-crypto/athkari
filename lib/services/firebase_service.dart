import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../data/models/day_progress_model.dart';

/// طبقة Firebase — **اختيارية بالكامل**.
///
/// التطبيق يعمل ١٠٠٪ بدونها: كل شيء محفوظ محليًا. هذه الطبقة تضيف فقط
/// مزامنة التقدّم بين أجهزة المستخدم إذا اختار تسجيل الدخول.
///
/// إذا لم تُضَف ملفات إعداد Firebase (`google-services.json` /
/// `GoogleService-Info.plist`) فإن `initialize()` تفشل بهدوء ويصبح
/// [isAvailable] = false، وتختفي خيارات تسجيل الدخول من الواجهة بدل أن
/// ينهار التطبيق.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  bool _available = false;
  bool _initialized = false;

  /// هل Firebase مُهيّأ فعلًا على هذا الجهاز؟
  bool get isAvailable => _available;

  FirebaseAuth? get _auth => _available ? FirebaseAuth.instance : null;

  /// المستخدم الحالي (null إذا لم يسجّل دخوله أو Firebase غير مُهيّأ).
  User? get currentUser => _auth?.currentUser;

  bool get isSignedIn => currentUser != null;

  /// بثّ تغيّر حالة تسجيل الدخول (فارغ إذا Firebase غير متاح).
  Stream<User?> authStateChanges() =>
      _available ? FirebaseAuth.instance.authStateChanges() : Stream<User?>.value(null);

  /// تهيئة Firebase بأمان.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (error) {
      // لا توجد إعدادات Firebase → نكمل بوضع محلي بالكامل.
      _available = false;
      debugPrint('Firebase غير مُهيّأ — التطبيق سيعمل محليًا فقط. ($error)');
    }
  }

  // ==================== تسجيل الدخول ====================

  /// هل تسجيل الدخول بحساب Apple متاح على هذا الجهاز؟
  bool get isAppleSignInAvailable {
    if (kIsWeb || !_available) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// تسجيل الدخول بحساب Google.
  Future<User?> signInWithGoogle() async {
    if (!_available) return null;

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>['email'],
    );
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) return null; // ألغى المستخدم العملية

    final GoogleSignInAuthentication auth = await account.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final UserCredential result =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return result.user;
  }

  /// تسجيل الدخول بحساب Apple.
  Future<User?> signInWithApple() async {
    if (!isAppleSignInAvailable) return null;

    final String rawNonce = _generateNonce();
    final String hashedNonce =
        sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    final UserCredential result =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return result.user;
  }

  Future<void> signOut() async {
    if (!_available) return;
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // لا يهم إن لم يكن المستخدم داخلًا عبر Google.
    }
    await FirebaseAuth.instance.signOut();
  }

  /// توليد nonce عشوائي مطلوب لتسجيل الدخول الآمن بحساب Apple.
  String _generateNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // ==================== مزامنة التقدّم ====================

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final User? user = currentUser;
    if (!_available || user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  /// رفع سجلّ الأيام إلى السحابة (دمج، لا استبدال).
  Future<void> uploadDays(List<DayProgress> days, {int bestStreak = 0}) async {
    final DocumentReference<Map<String, dynamic>>? doc = _userDoc;
    if (doc == null) return;

    // نستخدم set(merge: true) بخريطة متداخلة بدل update بمسارات منقوطة،
    // لأن مفاتيح التواريخ ("2026-09-03") ليست مسارات حقول صالحة في Firestore.
    final Map<String, dynamic> payload = <String, dynamic>{
      'days': <String, dynamic>{
        for (final DayProgress d in days)
          d.dateKey: <String, dynamic>{
            'counts': d.counts,
            'morningCompleted': d.morningCompleted,
            'eveningCompleted': d.eveningCompleted,
            'updatedAt': d.updatedAt?.toIso8601String(),
          },
      },
      'bestStreak': bestStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await doc.set(payload, SetOptions(merge: true));
  }

  /// تنزيل سجلّ الأيام من السحابة.
  Future<List<DayProgress>> downloadDays() async {
    final DocumentReference<Map<String, dynamic>>? doc = _userDoc;
    if (doc == null) return <DayProgress>[];

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
    final Map<String, dynamic>? data = snapshot.data();
    final dynamic rawDays = data?['days'];
    if (rawDays is! Map) return <DayProgress>[];

    final List<DayProgress> days = <DayProgress>[];
    rawDays.forEach((dynamic key, dynamic value) {
      if (value is Map) {
        days.add(DayProgress.fromJson(<dynamic, dynamic>{
          ...value,
          'dateKey': '$key',
        }));
      }
    });
    return days;
  }

  // ==================== الإشعارات السحابية (اختيارية) ====================

  /// طلب إذن إشعارات FCM. لا يُستخدم في MVP سوى للتهيئة المستقبلية،
  /// وكل التذكيرات اليومية تعمل محليًا بدون إنترنت.
  Future<String?> initMessaging() async {
    if (!_available) return null;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      return await messaging.getToken();
    } catch (error) {
      debugPrint('تعذّر تهيئة FCM: $error');
      return null;
    }
  }
}
