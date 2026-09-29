import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'study_note.dart';

class StudyNoteStore extends ChangeNotifier {
  StudyNoteStore._();

  static final StudyNoteStore instance = StudyNoteStore._();

  List<StudyNote> notes = const [];
  bool isLoading = false;
  bool isLoaded = false;
  Object? error;
  String? _ownerId;
  Future<void>? _loadFuture;
  int _loadGeneration = 0;

  Future<void> loadForUser(String userId, {bool force = false}) {
    if (!force && isLoaded && _ownerId == userId) return Future<void>.value();
    if (!force && isLoading && _ownerId == userId && _loadFuture != null) {
      return _loadFuture!;
    }

    final generation = ++_loadGeneration;
    _ownerId = userId;
    isLoading = true;
    isLoaded = false;
    error = null;
    notes = const [];
    notifyListeners();
    _loadFuture = _load(userId, generation);
    return _loadFuture!;
  }

  Future<void> _load(String userId, int generation) async {
    try {
      final rows = await Supabase.instance.client
          .from('study_notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      if (!_isCurrentUser(userId, generation)) return;

      notes = List.unmodifiable(
        rows.map((row) => StudyNote.fromJson(Map<String, dynamic>.from(row))),
      );
      isLoading = false;
      isLoaded = true;
      error = null;
    } catch (exception) {
      if (generation == _loadGeneration) {
        isLoading = false;
        isLoaded = false;
        error = exception;
      }
    }
    if (generation == _loadGeneration) notifyListeners();
  }

  Future<void> create(StudyNoteDraft draft) async {
    final userId = _requireOwner();
    final generation = _loadGeneration;
    final row = await Supabase.instance.client
        .from('study_notes')
        .insert({
          'user_id': userId,
          'title': draft.title.trim(),
          'subject': _cleanSubject(draft.subject),
          'content': draft.content.trim(),
        })
        .select()
        .single();
      if (!_isCurrentUser(userId, generation)) return;
    notes = List.unmodifiable([
      StudyNote.fromJson(Map<String, dynamic>.from(row)),
      ...notes,
    ]);
    notifyListeners();
  }

  Future<void> update(String noteId, StudyNoteDraft draft) async {
    final userId = _requireOwner();
    final generation = _loadGeneration;
    final row = await Supabase.instance.client
        .from('study_notes')
        .update({
          'title': draft.title.trim(),
          'subject': _cleanSubject(draft.subject),
          'content': draft.content.trim(),
        })
        .eq('id', noteId)
        .eq('user_id', userId)
        .select()
        .single();
      if (!_isCurrentUser(userId, generation)) return;
    final updated = StudyNote.fromJson(Map<String, dynamic>.from(row));
    notes = List.unmodifiable(
      notes.map((note) => note.id == noteId ? updated : note),
    );
    notifyListeners();
  }

  Future<void> delete(String noteId) async {
    final userId = _requireOwner();
    final generation = _loadGeneration;
    await Supabase.instance.client
        .from('study_notes')
        .delete()
        .eq('id', noteId)
        .eq('user_id', userId)
        .select('id')
        .single();
      if (!_isCurrentUser(userId, generation)) return;
    notes = List.unmodifiable(notes.where((note) => note.id != noteId));
    notifyListeners();
  }

  void clearForSignedOut() {
    _loadGeneration++;
    _ownerId = null;
    _loadFuture = null;
    notes = const [];
    isLoading = false;
    isLoaded = false;
    error = null;
    notifyListeners();
  }

  String _requireOwner() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId != _ownerId || !isLoaded) {
      throw StateError('Notes are not loaded for the active user.');
    }
    return userId;
  }

  bool _isCurrentUser(String userId, int generation) =>
      generation == _loadGeneration &&
      _ownerId == userId &&
      Supabase.instance.client.auth.currentUser?.id == userId;

  static String? _cleanSubject(String? subject) {
    final value = subject?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
