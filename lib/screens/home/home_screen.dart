import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/contacts/contacts_bloc.dart';
import '../../blocs/history/history_bloc.dart';
import '../../core/utils/call_enums.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_tile.dart';
import '../contacts/contacts_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../blocs/call/call_bloc.dart';
import '../../services/permission_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _DashboardTab(),
      ContactsScreen(showAppBar: false),
      HistoryScreen(showAppBar: false),
      ProfileScreen(showAppBar: false),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(_index))),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.call_outlined), activeIcon: Icon(Icons.call), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _titleFor(int i) => const ['ConnectCall', 'Contacts', 'Calls', 'Profile'][i];
}

/// Home tab: profile summary + search shortcut + online contacts + recent calls.
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    final me = (context.read<AuthBloc>().state as Authenticated).user;
    context.read<ContactsBloc>().add(LoadContacts(me.id));
    context.read<HistoryBloc>().add(LoadHistory(me.id));
  }

  Future<void> _startCall(UserModel peer, CallType type) async {
    final outcome = await _permissionService.requestForCall(type == CallType.video);
    if (!mounted) return;
    if (outcome != PermissionOutcome.granted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${type == CallType.video ? 'Camera and microphone' : 'Microphone'} permission is required.'),
      ));
      return;
    }
    final me = (context.read<AuthBloc>().state as Authenticated).user;
    context.read<CallBloc>().add(PlaceCall(me: me, peer: peer, type: type));
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as Authenticated).user;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ContactsBloc>().add(LoadContacts(user.id));
        context.read<HistoryBloc>().add(LoadHistory(user.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              UserAvatar(initials: user.initials, colorHex: user.avatarColorHex, radius: 26, showOnlineDot: true, isOnline: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, ${user.name.split(' ').first} 👋', style: Theme.of(context).textTheme.titleMedium),
                    Text('Ready to connect', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Contacts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              if (state is ContactsLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is ContactsEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No other users yet. Invite a friend to register!', style: TextStyle(color: Colors.grey)),
                );
              }
              if (state is! ContactsLoaded) return const SizedBox.shrink();
              final preview = state.allContacts.take(4).toList();
              return Column(
                children: preview
                    .map((u) => UserTile(
                          user: u,
                          onAudioCall: () => _startCall(u, CallType.audio),
                          onVideoCall: () => _startCall(u, CallType.video),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Recent calls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is HistoryEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No calls yet.', style: TextStyle(color: Colors.grey)),
                );
              }
              final calls = (state as HistoryLoaded).calls.take(3).toList();
              return Column(
                children: calls
                    .map((c) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(initials: _initials(c.peerName), colorHex: c.peerAvatarColorHex, radius: 20),
                          title: Text(c.peerName),
                          subtitle: Text(c.type == CallType.video ? 'Video call' : 'Audio call'),
                          trailing: Icon(
                            c.direction == CallDirection.incoming ? Icons.call_received : Icons.call_made,
                            size: 18,
                            color: c.status == CallStatus.completed ? Colors.green : Colors.redAccent,
                          ),
                        ))
                    .toList(),
              );
            },
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
}
