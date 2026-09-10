import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/call/call_bloc.dart';
import '../../blocs/contacts/contacts_bloc.dart';
import '../../core/utils/call_enums.dart';
import '../../models/user_model.dart';
import '../../services/permission_service.dart';
import '../../widgets/user_tile.dart';

class ContactsScreen extends StatefulWidget {
  final bool showAppBar;
  const ContactsScreen({super.key, this.showAppBar = true});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    final me = (context.read<AuthBloc>().state as Authenticated).user;
    context.read<ContactsBloc>().add(LoadContacts(me.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startCall(UserModel peer, CallType type) async {
    final outcome = await _permissionService.requestForCall(type == CallType.video);
    if (!mounted) return;
    if (outcome != PermissionOutcome.granted) {
      _showPermissionDenied(outcome, type);
      return;
    }
    final me = (context.read<AuthBloc>().state as Authenticated).user;
    context.read<CallBloc>().add(PlaceCall(me: me, peer: peer, type: type));
  }

  void _showPermissionDenied(PermissionOutcome outcome, CallType type) {
    final what = type == CallType.video ? 'camera and microphone' : 'microphone';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$what permission is required to start this call.'),
      action: outcome == PermissionOutcome.permanentlyDenied
          ? SnackBarAction(label: 'Settings', onPressed: () => _permissionService.openSettings())
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Contacts')) : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: (q) => context.read<ContactsBloc>().add(SearchQueryChanged(q)),
              decoration: const InputDecoration(
                hintText: 'Search people...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<ContactsBloc, ContactsState>(
                builder: (context, state) {
                  if (state is ContactsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ContactsError) {
                    return _MessageView(icon: Icons.wifi_off_rounded, message: state.message);
                  }
                  if (state is ContactsEmpty) {
                    return const _MessageView(
                      icon: Icons.people_outline,
                      message: 'No other users yet.\nAsk a friend to create an account in ConnectCall!',
                    );
                  }
                  final loaded = state as ContactsLoaded;
                  if (loaded.visibleContacts.isEmpty) {
                    return const _MessageView(icon: Icons.search_off, message: 'No matches found.');
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      final me = (context.read<AuthBloc>().state as Authenticated).user;
                      context.read<ContactsBloc>().add(LoadContacts(me.id));
                    },
                    child: ListView.separated(
                      itemCount: loaded.visibleContacts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final user = loaded.visibleContacts[i];
                        return UserTile(
                          user: user,
                          onAudioCall: () => _startCall(user, CallType.audio),
                          onVideoCall: () => _startCall(user, CallType.video),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  const _MessageView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
