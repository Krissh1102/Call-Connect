import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/call/call_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/call_enums.dart';
import '../../widgets/call_action_button.dart';
import '../../widgets/user_avatar.dart';

class AudioCallScreen extends StatelessWidget {
  const AudioCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF14161C),
        body: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    UserAvatar(
                      initials: _initials(state.peerName ?? '?'),
                      colorHex: state.peerAvatarColorHex ?? '#4F63F6',
                      radius: 70,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      state.peerName ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusLabel(state),
                      style: const TextStyle(color: Colors.white60, fontSize: 16),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallActionButton(
                          icon: state.micEnabled ? Icons.mic : Icons.mic_off,
                          label: state.micEnabled ? 'Mute' : 'Unmute',
                          backgroundColor: state.micEnabled ? Colors.white24 : Colors.white,
                          iconColor: state.micEnabled ? Colors.white : Colors.black87,
                          onPressed: () => context.read<CallBloc>().add(const ToggleMicrophone()),
                        ),
                        CallActionButton(
                          icon: state.speakerEnabled ? Icons.volume_up : Icons.volume_off,
                          label: 'Speaker',
                          backgroundColor: state.speakerEnabled ? Colors.white : Colors.white24,
                          iconColor: state.speakerEnabled ? Colors.black87 : Colors.white,
                          onPressed: () => context.read<CallBloc>().add(const ToggleSpeaker()),
                        ),
                        CallActionButton(
                          icon: Icons.call_end,
                          label: 'End',
                          backgroundColor: AppTheme.accentRed,
                          onPressed: () {
                            final me = (context.read<AuthBloc>().state as Authenticated).user;
                            context.read<CallBloc>().add(EndCall(me.id));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusLabel(CallState state) {
    switch (state.phase) {
      case CallLifecycle.calling:
        return 'Calling...';
      case CallLifecycle.connecting:
        return 'Connecting...';
      case CallLifecycle.connected:
        return _formatDuration(state.duration);
      default:
        return '';
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
