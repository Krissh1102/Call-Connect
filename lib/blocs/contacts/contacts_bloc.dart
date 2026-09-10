import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

// ---------------- Events ----------------
abstract class ContactsEvent extends Equatable {
  const ContactsEvent();
  @override
  List<Object?> get props => [];
}

class LoadContacts extends ContactsEvent {
  final String currentUserId;
  const LoadContacts(this.currentUserId);
  @override
  List<Object?> get props => [currentUserId];
}

class SearchQueryChanged extends ContactsEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

// ---------------- States ----------------
abstract class ContactsState extends Equatable {
  const ContactsState();
  @override
  List<Object?> get props => [];
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  final List<UserModel> allContacts;
  final List<UserModel> visibleContacts;
  final String query;
  const ContactsLoaded({required this.allContacts, required this.visibleContacts, this.query = ''});
  @override
  List<Object?> get props => [allContacts, visibleContacts, query];
}

class ContactsEmpty extends ContactsState {
  const ContactsEmpty();
}

class ContactsError extends ContactsState {
  final String message;
  const ContactsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ---------------- Bloc ----------------
class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc(this._userService) : super(const ContactsLoading()) {
    on<LoadContacts>(_onLoad);
    on<SearchQueryChanged>(_onSearch);
  }

  final UserService _userService;
  String _currentUserId = '';

  Future<void> _onLoad(LoadContacts event, Emitter<ContactsState> emit) async {
    _currentUserId = event.currentUserId;
    emit(const ContactsLoading());
    try {
      final contacts = await _userService.getContacts(excludingUserId: _currentUserId);
      emit(contacts.isEmpty
          ? const ContactsEmpty()
          : ContactsLoaded(allContacts: contacts, visibleContacts: contacts));
    } catch (_) {
      emit(const ContactsError('Could not load contacts. Check your connection and try again.'));
    }
  }

  Future<void> _onSearch(SearchQueryChanged event, Emitter<ContactsState> emit) async {
    final current = state;
    if (current is! ContactsLoaded) return;
    final q = event.query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? current.allContacts
        : current.allContacts
            .where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
            .toList();
    emit(ContactsLoaded(allContacts: current.allContacts, visibleContacts: filtered, query: event.query));
  }
}
