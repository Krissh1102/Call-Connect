import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/call_model.dart';
import '../../services/local_storage_service.dart';

// ---------------- Events ----------------
abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {
  final String userId;
  const LoadHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}

class HistoryEntryAdded extends HistoryEvent {
  final String userId;
  final CallModel call;
  const HistoryEntryAdded(this.userId, this.call);
  @override
  List<Object?> get props => [userId, call];
}

// ---------------- States ----------------
abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<CallModel> calls;
  const HistoryLoaded(this.calls);
  @override
  List<Object?> get props => [calls];
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

// ---------------- Bloc ----------------
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._storage) : super(const HistoryLoading()) {
    on<LoadHistory>(_onLoad);
    on<HistoryEntryAdded>(_onEntryAdded);
  }

  final LocalStorageService _storage;

  Future<void> _onLoad(LoadHistory event, Emitter<HistoryState> emit) async {
    emit(const HistoryLoading());
    final calls = await _storage.getHistory(event.userId);
    emit(calls.isEmpty ? const HistoryEmpty() : HistoryLoaded(calls));
  }

  Future<void> _onEntryAdded(HistoryEntryAdded event, Emitter<HistoryState> emit) async {
    await _storage.addHistoryEntry(event.userId, event.call);
    final calls = await _storage.getHistory(event.userId);
    emit(HistoryLoaded(calls));
  }
}
