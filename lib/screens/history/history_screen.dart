import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/history/history_bloc.dart';
import '../../core/utils/call_enums.dart';
import '../../models/call_model.dart';
import '../../widgets/user_avatar.dart';

class HistoryScreen extends StatefulWidget {
  final bool showAppBar;
  const HistoryScreen({super.key, this.showAppBar = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    final me = (context.read<AuthBloc>().state as Authenticated).user;
    context.read<HistoryBloc>().add(LoadHistory(me.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Calls')) : null,
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No calls yet.\nStart one from Contacts!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          final calls = (state as HistoryLoaded).calls;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: calls.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _HistoryTile(call: calls[i]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CallModel call;
  const _HistoryTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final missed = call.status == CallStatus.missed || call.status == CallStatus.rejected || call.status == CallStatus.failed;
    final directionIcon = call.direction == CallDirection.incoming ? Icons.call_received : Icons.call_made;
    final color = missed ? Colors.redAccent : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          UserAvatar(initials: _initials(call.peerName), colorHex: call.peerAvatarColorHex, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(call.peerName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(directionIcon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${call.type == CallType.video ? 'Video' : 'Audio'} · ${_statusLabel(call)}',
                      style: TextStyle(color: missed ? Colors.redAccent : Colors.grey, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatWhen(call.startedAt), style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              const SizedBox(height: 4),
              Icon(
                call.type == CallType.video ? Icons.videocam_outlined : Icons.call_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String _statusLabel(CallModel call) {
    switch (call.status) {
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.rejected:
        return call.direction == CallDirection.outgoing ? 'Declined' : 'Rejected';
      case CallStatus.failed:
        return 'Failed';
      case CallStatus.completed:
      case null:
        final d = call.duration;
        final m = d.inMinutes.toString().padLeft(2, '0');
        final s = (d.inSeconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
    }
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    final time = DateFormat.jm().format(dt);
    if (isToday) return 'Today, $time';
    if (isYesterday) return 'Yesterday, $time';
    return DateFormat('MMM d').format(dt);
  }
}
