import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/call/call_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/call_enums.dart';
import '../../services/permission_service.dart';
import '../../widgets/call_action_button.dart';
import '../../widgets/user_avatar.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();

    return PopScope(
      canPop: false, // calls are dismissed via Accept/Decline, not the back button
      child: Scaffold(
        backgroundColor: const Color(0xFF14161C),
        body: BlocBuilder<CallBloc, CallState>(
          builder: (context, state) {
            final isVideo = state.type == CallType.video;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
                      style: const TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.3),
                    ),
                    const Spacer(),
                    UserAvatar(
                      initials: _initials(state.peerName ?? '?'),
                      colorHex: state.peerAvatarColorHex ?? '#4F63F6',
                      radius: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.peerName ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isVideo ? 'wants to video call' : 'is calling...',
                      style: const TextStyle(color: Colors.white60, fontSize: 15),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallActionButton(
                          icon: Icons.call_end,
                          label: 'Decline',
                          backgroundColor: AppTheme.accentRed,
                          size: 68,
                          onPressed: () {
                            final me = (context.read<AuthBloc>().state as Authenticated).user;
                            context.read<CallBloc>().add(DeclineIncomingCall(me));
                          },
                        ),
                        CallActionButton(
                          icon: Icons.call,
                          label: 'Accept',
                          backgroundColor: AppTheme.accentGreen,
                          size: 68,
                          onPressed: () async {
                            final outcome = await permissionService.requestForCall(isVideo);
                            if (!context.mounted) return;
                            final me = (context.read<AuthBloc>().state as Authenticated).user;
                            if (outcome != PermissionOutcome.granted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('${isVideo ? 'Camera and microphone' : 'Microphone'} permission is required to answer.'),
                              ));
                              context.read<CallBloc>().add(DeclineIncomingCall(me));
                              return;
                            }
                            context.read<CallBloc>().add(AcceptIncomingCall(me));
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
