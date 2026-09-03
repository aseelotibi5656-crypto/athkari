import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/day_progress_model.dart';
import '../data/repositories/progress_repository.dart';
import '../services/firebase_service.dart';
import 'adhkar_provider.dart';
import 'repository_providers.dart';
import 'streak_provider.dart';

/// حالة المزامنة الاختيارية مع السحابة.
class SyncState {
  const SyncState({
    this.isBusy = false,
    this.lastSyncedAt,
    this.error,
  });

  final bool isBusy;
  final DateTime? lastSyncedAt;
  final String? error;

  SyncState copyWith({
    bool? isBusy,
    DateTime? lastSyncedAt,
    String? error,
    bool clearError = false,
  }) {
    return SyncState(
      isBusy: isBusy ?? this.isBusy,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// بثّ حالة تسجيل الدخول. يعطي null دائمًا إذا لم يُهيّأ Firebase.
final StreamProvider<User?> authStateProvider = StreamProvider<User?>(
  (Ref ref) => FirebaseService.instance.authStateChanges(),
);

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._repository, this._ref)
      : super(SyncState(lastSyncedAt: _repository.lastSyncedAt));

  final ProgressRepository _repository;
  final Ref _ref;

  /// مزامنة ثنائية الاتجاه: ننزّل ثم ندمج ثم نرفع النسخة الموحّدة.
  ///
  /// لا يعتمد عليها أي شيء في التطبيق — لو فشلت (لا إنترنت مثلًا) يبقى
  /// كل شيء يعمل محليًا كما هو.
  Future<void> syncNow() async {
    if (!FirebaseService.instance.isSignedIn || state.isBusy) return;

    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final List<DayProgress> remote =
          await FirebaseService.instance.downloadDays();
      if (remote.isNotEmpty) {
        await _repository.mergeRemoteDays(remote);
      }

      await FirebaseService.instance.uploadDays(
        _repository.allDays(),
        bestStreak: _repository.bestStreak,
      );

      final DateTime now = DateTime.now();
      await _repository.saveLastSyncedAt(now);

      // نعيد بناء الحالة بعد الدمج حتى تظهر البيانات القادمة من جهاز آخر.
      _ref.read(dayProgressProvider.notifier).syncWithToday();
      await _ref.read(streakProvider.notifier).recalculate();

      state = state.copyWith(isBusy: false, lastSyncedAt: now);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        error: 'تعذّرت المزامنة، سنحاول لاحقًا',
      );
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final User? user = await FirebaseService.instance.signInWithGoogle();
      if (user == null) return null; // ألغى المستخدم
      await syncNow();
      return null;
    } catch (_) {
      return 'تعذّر تسجيل الدخول بحساب Google';
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final User? user = await FirebaseService.instance.signInWithApple();
      if (user == null) return null;
      await syncNow();
      return null;
    } catch (_) {
      return 'تعذّر تسجيل الدخول بحساب Apple';
    }
  }

  Future<void> signOut() => FirebaseService.instance.signOut();
}

final StateNotifierProvider<SyncNotifier, SyncState> syncProvider =
    StateNotifierProvider<SyncNotifier, SyncState>(
  (Ref ref) => SyncNotifier(ref.watch(progressRepositoryProvider), ref),
);
