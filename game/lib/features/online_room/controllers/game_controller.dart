import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameController extends GetxController {
  // Reactive game state
  final fen = ''.obs; // server FEN
  final status = 'ongoing'.obs; // 'ongoing' | 'ended'
  final winner = RxnString(); // 'w' | 'b' | null
  final lastTurnAt = Rxn<DateTime>();
  final sideToMoveIsWhite = true.obs;
  final whiteTimeMs = 0.obs;
  final blackTimeMs = 0.obs;
  final moveCount = 0.obs;
  final bothSeated = false.obs;
  final clocksActive = false.obs;

  // UI flags previously widget-local
  final createdMissingGame = false.obs;
  final joinAttempted = false.obs;
  final committingTimeout = false.obs;
  final endedDialogShown = false.obs;
  final historyUploaded = false.obs;
  // Auto-join error reporting and retries
  final joinError = ''.obs;
  final joinRetries = 0.obs;

  // Derived reactive labels
  final whiteLabel = ''.obs;
  final blackLabel = ''.obs;

  Timer? _uiTick;
  // Presence heartbeat configuration
  DocumentReference<Map<String, dynamic>>? _presenceGameRef;
  String? _presencePlayerId;
  DateTime? _lastHeartbeatAt;

  void startUiTick() {
    _uiTick?.cancel();
    _uiTick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Trigger recomputation of labels only
      _recomputeLabels();
      _maybeHeartbeat();
    });
  }

  void stopUiTick() {
    _uiTick?.cancel();
    _uiTick = null;
  }

  void ensureUiTickStarted() {
    if (_uiTick == null) {
      startUiTick();
    }
  }

  void configurePresence(
    DocumentReference<Map<String, dynamic>> gameRef,
    String playerId,
  ) {
    _presenceGameRef = gameRef;
    _presencePlayerId = playerId;
  }

  void updateFromSnapshot({
    required String newFen,
    required String newStatus,
    String? newWinner,
    required int newWhiteTimeMs,
    required int newBlackTimeMs,
    DateTime? newLastTurnAt,
    int? newMoveCount,
    bool? newBothSeated,
  }) {
    fen.value = newFen;
    status.value = newStatus;
    winner.value = newWinner;
    whiteTimeMs.value = newWhiteTimeMs;
    blackTimeMs.value = newBlackTimeMs;
    lastTurnAt.value = newLastTurnAt;
    sideToMoveIsWhite.value = newFen.split(' ')[1] == 'w';
    if (newMoveCount != null) moveCount.value = newMoveCount;
    if (newBothSeated != null) bothSeated.value = newBothSeated;
    // Clocks become active only when both seated and at least one move made (white moved)
    clocksActive.value = bothSeated.value && moveCount.value > 0;
    _recomputeLabels();
  }

  void resetJoinState() {
    joinAttempted.value = false;
    joinError.value = '';
  }

  String _formatMs(int ms) {
    if (ms < 0) ms = 0;
    final totalSeconds = (ms / 1000).floor();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _recomputeLabels() {
    final now = DateTime.now();
    final ongoing = status.value == 'ongoing';
    final sideWhite = sideToMoveIsWhite.value;
    final ltAt = lastTurnAt.value ?? now;
    final elapsedMs = (ongoing && clocksActive.value)
        ? now.difference(ltAt).inMilliseconds
        : 0;
    final whiteRemain =
        whiteTimeMs.value - (ongoing && sideWhite ? elapsedMs : 0);
    final blackRemain =
        blackTimeMs.value - (ongoing && !sideWhite ? elapsedMs : 0);
    whiteLabel.value = _formatMs(whiteRemain);
    blackLabel.value = _formatMs(blackRemain);
  }

  void _maybeHeartbeat() async {
    try {
      final ref = _presenceGameRef;
      final pid = _presencePlayerId;
      if (ref == null || pid == null) return;
      final now = DateTime.now();
      final last = _lastHeartbeatAt;
      if (last != null && now.difference(last).inSeconds < 10) return;
      _lastHeartbeatAt = now;
      await ref.update({
        'lastSeen.$pid': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // ignore heartbeat failures
    }
  }

  @override
  void onClose() {
    stopUiTick();
    super.onClose();
  }
}
