import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/call/call_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/call_enums.dart';
import '../../widgets/call_action_button.dart';
import '../../widgets/user_avatar.dart';

// NOTE: Video-track lookup here (`videoTrackPublications`, `remoteParticipants`,
// `.track`) targets the general shape of the livekit_client Flutter SDK. Package
// APIs shift between minor versions — after `flutter pub get`, check these
// getter/method names against the exact version pinned in pubspec.yaml (see
// README "Known limitations") and adjust if your version differs.
class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _RemoteVideoArea(state: state),
                Positioned(
                  top: 48,
                  left: 20,
                  right: 20,
                  child: _CallHeader(state: state),
                ),
                if (state.cameraEnabled)
                  Positioned(
                    top: 100,
                    right: 20,
                    child: _LocalPreview(state: state),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: _Controls(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CallHeader extends StatelessWidget {
  final CallState state;
  const _CallHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          state.peerName ?? 'Unknown',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, shadows: [
            Shadow(blurRadius: 8, color: Colors.black54),
          ]),
        ),
        const SizedBox(height: 4),
        Text(
          _statusLabel(state),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  String _statusLabel(CallState state) {
    switch (state.phase) {
      case CallLifecycle.calling:
        return 'Calling...';
      case CallLifecycle.connecting:
        return 'Connecting...';
      case CallLifecycle.connected:
        final d = state.duration;
        final m = d.inMinutes.toString().padLeft(2, '0');
        final s = (d.inSeconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
      default:
        return '';
    }
  }
}

/// Renders the peer's video track full-screen, falling back to an avatar
/// card while the camera is off or the call hasn't connected yet.
class _RemoteVideoArea extends StatelessWidget {
  final CallState state;
  const _RemoteVideoArea({required this.state});

  @override
  Widget build(BuildContext context) {
    final room = state.room;
    if (room == null || state.phase != CallLifecycle.connected) {
      return _placeholder();
    }

    // Rebuild whenever the room or any remote participant notifies listeners
    // (e.g. a track gets published/subscribed) — see README "video rendering".
    return ListenableBuilder(
      listenable: Listenable.merge([room, ...room.remoteParticipants.values]),
      builder: (context, _) {
        final remoteParticipant = room.remoteParticipants.values.isNotEmpty ? room.remoteParticipants.values.first : null;
        final videoPub = remoteParticipant?.videoTrackPublications.where((p) => !p.muted).firstOrNull;
        final track = videoPub?.track;
        if (track == null) return _placeholder();
        return lk.VideoTrackRenderer(track as lk.VideoTrack);
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF14161C),
      alignment: Alignment.center,
      child: UserAvatar(
        initials: _initials(state.peerName ?? '?'),
        colorHex: state.peerAvatarColorHex ?? '#4F63F6',
        radius: 70,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Small local camera preview, top-right.
class _LocalPreview extends StatelessWidget {
  final CallState state;
  const _LocalPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    final room = state.room;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        height: 140,
        color: const Color(0xFF262A33),
        child: room == null
            ? const SizedBox.shrink()
            : ListenableBuilder(
                listenable: room.localParticipant ?? room,
                builder: (context, _) {
                  final pub = room.localParticipant?.videoTrackPublications.firstOrNull;
                  final track = pub?.track;
                  if (track == null) return const Icon(Icons.videocam_off, color: Colors.white38);
                  return lk.VideoTrackRenderer(track as lk.VideoTrack, mirrorMode: lk.VideoViewMirrorMode.mirror);
                },
              ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final CallState state;
  const _Controls({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          icon: state.cameraEnabled ? Icons.videocam : Icons.videocam_off,
          label: 'Camera',
          backgroundColor: state.cameraEnabled ? Colors.white24 : Colors.white,
          iconColor: state.cameraEnabled ? Colors.white : Colors.black87,
          onPressed: () => context.read<CallBloc>().add(const ToggleCamera()),
        ),
        CallActionButton(
          icon: Icons.cameraswitch,
          label: 'Switch',
          onPressed: () => context.read<CallBloc>().add(const SwitchCamera()),
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
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
