import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/call/call_bloc.dart';
import '../core/utils/call_enums.dart';
import '../screens/call/audio_call_screen.dart';
import '../screens/call/video_call_screen.dart';
import '../screens/call/incoming_call_screen.dart';
import 'app_keys.dart';

/// Wraps the whole app (below MaterialApp) so an incoming call can pop up a
/// full-screen UI no matter which tab/screen the user is currently on —
/// mirroring how a real dialer/VoIP app behaves.
class CallFlowListener extends StatefulWidget {
  final Widget child;
  const CallFlowListener({super.key, required this.child});

  @override
  State<CallFlowListener> createState() => _CallFlowListenerState();
}

class _CallFlowListenerState extends State<CallFlowListener> {
  bool _pushedIncoming = false;
  bool _pushedActiveCall = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listenWhen: (previous, current) => previous.phase != current.phase,
      listener: _handlePhaseChange,
      child: widget.child,
    );
  }

  void _handlePhaseChange(BuildContext context, CallState state) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (state.phase) {
      case CallLifecycle.ringing:
        _pushedIncoming = true;
        nav.push(MaterialPageRoute(
          settings: const RouteSettings(name: '/incoming_call'),
          builder: (_) => const IncomingCallScreen(),
        ));
        break;

      case CallLifecycle.calling:
        _pushedActiveCall = true;
        nav.push(MaterialPageRoute(
          settings: const RouteSettings(name: '/active_call'),
          builder: (_) => state.type == CallType.video ? const VideoCallScreen() : const AudioCallScreen(),
        ));
        break;

      case CallLifecycle.connecting:
        if (_pushedIncoming && !_pushedActiveCall) {
          _pushedIncoming = false;
          _pushedActiveCall = true;
          nav.pushReplacement(MaterialPageRoute(
            settings: const RouteSettings(name: '/active_call'),
            builder: (_) => state.type == CallType.video ? const VideoCallScreen() : const AudioCallScreen(),
          ));
        }
        break;

      case CallLifecycle.connected:
        break; // same screen re-renders from the updated CallBloc state

      case CallLifecycle.ended:
      case CallLifecycle.rejected:
      case CallLifecycle.missed:
      case CallLifecycle.busy:
      case CallLifecycle.failed:
      case CallLifecycle.disconnected:
        if (_pushedIncoming || _pushedActiveCall) {
          _pushedIncoming = false;
          _pushedActiveCall = false;
          nav.popUntil((route) => route.isFirst);
        }
        _showEndedMessage(state);
        context.read<CallBloc>().add(const ResetCall());
        break;

      case CallLifecycle.idle:
        break;
    }
  }

  void _showEndedMessage(CallState state) {
    final peer = state.peerName ?? 'The call';
    String message;
    switch (state.phase) {
      case CallLifecycle.rejected:
        message = '$peer declined the call.';
        break;
      case CallLifecycle.missed:
        message = 'Missed call${state.peerName != null ? ' from $peer' : ''}.';
        break;
      case CallLifecycle.busy:
        message = '$peer is busy on another call.';
        break;
      case CallLifecycle.failed:
        message = state.errorMessage ?? 'The call failed to connect.';
        break;
      case CallLifecycle.disconnected:
        message = state.errorMessage ?? 'Call disconnected.';
        break;
      case CallLifecycle.ended:
        message = 'Call ended.';
        break;
      default:
        return;
    }
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }
}
