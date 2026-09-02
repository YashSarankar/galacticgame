import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';
import '../../models/game_state.dart';

/// Settings & Commander Lifetime Career Dossier Modal
class SettingsModal extends ConsumerStatefulWidget {
  const SettingsModal({super.key});

  @override
  ConsumerState<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends ConsumerState<SettingsModal> {
  final SoundService _soundService = SoundService();
  late bool _soundMuted;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    _soundMuted = _soundService.isMuted;
    _hapticsEnabled = _soundService.isHapticsEnabled;
  }

  void _toggleSound(bool value) {
    setState(() {
      _soundMuted = !value;
    });
    _soundService.setMuted(!value);
    if (value) {
      _soundService.playPurchaseSound();
    }
  }

  void _toggleHaptics(bool value) {
    setState(() {
      _hapticsEnabled = value;
    });
    _soundService.setHapticsEnabled(value);
    if (value) {
      _soundService.playMergeHaptic();
    }
  }

  void _showResetConfirmation(BuildContext context) {
    final notifier = ref.read(gameStateProvider.notifier);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF0055), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF0055)),
            SizedBox(width: 8),
            Text(
              'RESET FLEET DATA?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently reset all ships, coins, Dark Matter, and progress. This action cannot be undone!',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService.clearAll();
              notifier.loadFromState(GameState.initial());
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0055),
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM RESET',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);

    return Dialog(

      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00F0FF).withAlpha((0.5 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withAlpha((0.15 * 255).round()),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Row(
                children: [
                  const Icon(Icons.settings_rounded,
                      color: Color(0xFF00F0FF), size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'SETTINGS & DOSSIER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon:
                        const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Section 1: Audio & Haptics Toggles
              _buildSectionHeader('AUDIO & CONTROLS'),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: GameTheme.backgroundVoid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF00F0FF),
                      title: const Text(
                        'Sound Effects (SFX)',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _soundMuted ? 'Muted' : 'Enabled',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10.5),
                      ),
                      secondary: Icon(
                        _soundMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: _soundMuted
                            ? Colors.white38
                            : const Color(0xFF00F0FF),
                      ),
                      value: !_soundMuted,
                      onChanged: _toggleSound,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      activeThumbColor: const Color(0xFF00FF88),
                      title: const Text(
                        'Haptic Vibration Feedback',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _hapticsEnabled ? 'Active' : 'Disabled',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10.5),
                      ),
                      secondary: Icon(
                        _hapticsEnabled
                            ? Icons.vibration_rounded
                            : Icons.smartphone_rounded,
                        color: _hapticsEnabled
                            ? const Color(0xFF00FF88)
                            : Colors.white38,
                      ),
                      value: _hapticsEnabled,
                      onChanged: _toggleHaptics,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: Lifetime Career Statistics Dossier
              _buildSectionHeader('COMMANDER CAREER DOSSIER'),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GameTheme.backgroundVoid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFFD700)
                          .withAlpha((0.25 * 255).round())),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Lifetime Coins Earned',
                        '${NumberFormatter.formatCredits(gameState.lifetimeCredits)} Coins'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Total Spacecraft Merges',
                        '${gameState.totalMergesCount} merges'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Highest Ship Tier Unlocked',
                        'Tier ${gameState.highestTierUnlocked}'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Alien Dreadnoughts Defeated',
                        '${gameState.career.totalBossesDefeated} Bosses'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Lucky Wheel Spins',
                        '${gameState.career.totalWheelSpins} Spins'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Expeditions Completed',
                        '${gameState.career.totalExpeditionsCompleted} Sorties'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Galactic Prestige Resets',
                        '${gameState.career.prestigeCount} Resets'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Data Management & Reset
              _buildSectionHeader('DATA MANAGEMENT'),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () => _showResetConfirmation(context),
                icon: const Icon(Icons.delete_forever_rounded,

                    color: Color(0xFFFF0055), size: 16),
                label: const Text(
                  'RESET ALL GAME PROGRESS',
                  style: TextStyle(
                    color: Color(0xFFFF0055),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF0055), width: 1.2),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Footer App Info
              const Center(
                child: Text(
                  'Galactic Merge v1.0.0 • Flame 1.21.0 & Flutter Engine',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00F0FF),
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
