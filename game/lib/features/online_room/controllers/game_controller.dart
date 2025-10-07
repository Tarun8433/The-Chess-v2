import 'dart:async';
import 'package:get/get.dart';

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

  // Derived reactive labels
  final whiteLabel = ''.obs;
  final blackLabel = ''.obs;

  Timer? _uiTick;

  void startUiTick() {
    _uiTick?.cancel();
    _uiTick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Trigger recomputation of labels only
      _recomputeLabels();
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
    final whiteRemain = whiteTimeMs.value - (ongoing && sideWhite ? elapsedMs : 0);
    final blackRemain = blackTimeMs.value - (ongoing && !sideWhite ? elapsedMs : 0);
    whiteLabel.value = _formatMs(whiteRemain);
    blackLabel.value = _formatMs(blackRemain);
  }

  @override
  void onClose() {
    stopUiTick();
    super.onClose();
  }
}