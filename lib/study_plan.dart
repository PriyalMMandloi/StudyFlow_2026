import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyChapterTask {
  const StudyChapterTask({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.estimatedMinutes,
    required this.sortOrder,
    required this.isCompleted,
  });

  final String id;
  final String chapterId;
  final String title;
  final int? estimatedMinutes;
  final int sortOrder;
  final bool isCompleted;

  factory StudyChapterTask.fromJson(Map<String, dynamic> json) =>
      StudyChapterTask(
        id: json['id'] as String,
        chapterId: json['chapter_id'] as String,
        title: json['title'] as String,
        estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt(),
        sortOrder: (json['sort_order'] as num).toInt(),
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toInsertJson({required String userId}) => {
    'user_id': userId,
    'chapter_id': chapterId,
    'title': title,
    'estimated_minutes': estimatedMinutes,
    'sort_order': sortOrder,
  };
}

class StudyChapterTaskDraft {
  const StudyChapterTaskDraft({
    required this.title,
    required this.estimatedMinutes,
  });

  final String title;
  final int? estimatedMinutes;
}

class StudyChapter {
  const StudyChapter({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.description,
    required this.estimatedMinutes,
    required this.sortOrder,
    required this.isCompleted,
    required this.completedAt,
    required this.tasks,
  });

  final String id;
  final String userId;
  final String title;
  final String subject;
  final String? description;
  final int estimatedMinutes;
  final int sortOrder;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<StudyChapterTask> tasks;

  factory StudyChapter.fromJson(
    Map<String, dynamic> json, {
    List<StudyChapterTask> tasks = const [],
  }) => StudyChapter(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    subject: json['subject'] as String,
    description: json['description'] as String?,
    estimatedMinutes: (json['estimated_minutes'] as num).toInt(),
    sortOrder: (json['sort_order'] as num).toInt(),
    isCompleted: json['is_completed'] as bool? ?? false,
    completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    tasks: List.unmodifiable(tasks),
  );

  StudyChapter copyWith({
    String? title,
    String? subject,
    String? description,
    bool clearDescription = false,
    int? estimatedMinutes,
    int? sortOrder,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<StudyChapterTask>? tasks,
  }) => StudyChapter(
    id: id,
    userId: userId,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    description: clearDescription ? null : description ?? this.description,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    sortOrder: sortOrder ?? this.sortOrder,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    tasks: tasks ?? this.tasks,
  );

  Map<String, dynamic> toInsertJson({required String ownerId}) => {
    'user_id': ownerId,
    'title': title,
    'subject': subject,
    'description': description,
    'estimated_minutes': estimatedMinutes,
    'sort_order': sortOrder,
  };
}

class StudyChapterDraft {
  const StudyChapterDraft({
    required this.title,
    required this.subject,
    required this.description,
    required this.estimatedMinutes,
  });

  final String title;
  final String subject;
  final String? description;
  final int estimatedMinutes;
}

class StudyPlanStore extends ChangeNotifier {
  StudyPlanStore._();

  static final StudyPlanStore instance = StudyPlanStore._();

  List<StudyChapter> chapters = const [];
  bool isLoading = false;
  bool isReady = false;
  Object? error;
  String? _ownerId;
  Future<void>? _loadFuture;
  int _loadGeneration = 0;

  Future<void> loadForUser(String userId, {bool force = false}) {
    if (!force && isReady && _ownerId == userId) return Future<void>.value();
    if (!force && isLoading && _ownerId == userId && _loadFuture != null) {
      return _loadFuture!;
    }

    final generation = ++_loadGeneration;
    _ownerId = userId;
    isLoading = true;
    isReady = false;
    error = null;
    chapters = const [];
    notifyListeners();
    _loadFuture = _load(userId, generation);
    return _loadFuture!;
  }

  Future<void> _load(String userId, int generation) async {
    try {
      final client = Supabase.instance.client;
      final chapterRows = await client
          .from('study_chapters')
          .select()
          .eq('user_id', userId)
          .order('sort_order', ascending: false)
          .order('created_at', ascending: false);

      if (!_isCurrentUser(userId, generation)) return;

      final rows = chapterRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final chapterIds = rows.map((row) => row['id'] as String).toList();
      final tasksByChapter = <String, List<StudyChapterTask>>{};

      if (chapterIds.isNotEmpty) {
        final taskRows = await client
            .from('study_chapter_tasks')
            .select()
            .eq('user_id', userId)
            .inFilter('chapter_id', chapterIds)
            .order('sort_order', ascending: false)
            .order('created_at', ascending: false);

        for (final row in taskRows) {
          final task = StudyChapterTask.fromJson(
            Map<String, dynamic>.from(row),
          );
          (tasksByChapter[task.chapterId] ??= []).add(task);
        }
      }

      if (!_isCurrentUser(userId, generation)) return;
      chapters = List.unmodifiable(
        rows.map((row) {
          final id = row['id'] as String;
          return StudyChapter.fromJson(
            row,
            tasks: tasksByChapter[id] ?? const [],
          );
        }),
      );
      isLoading = false;
      isReady = true;
      error = null;
      notifyListeners();
    } catch (exception) {
      if (generation == _loadGeneration) {
        isLoading = false;
        isReady = false;
        error = exception;
        notifyListeners();
      }
      rethrow;
    }
  }

  bool _isCurrentUser(String userId, int generation) =>
      generation == _loadGeneration &&
      _ownerId == userId &&
      Supabase.instance.client.auth.currentUser?.id == userId;

  String _requireOwner() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId != _ownerId) {
      throw StateError('No active study-plan owner is available.');
    }
    return userId;
  }

  Future<StudyChapter> createChapter(StudyChapterDraft draft) async {
    final userId = _requireOwner();
    final sortOrder = chapters.isEmpty
        ? 0
        : chapters
                  .map((chapter) => chapter.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final row = await Supabase.instance.client
        .from('study_chapters')
        .insert({
          'user_id': userId,
          'title': draft.title.trim(),
          'subject': draft.subject.trim(),
          'description': _cleanDescription(draft.description),
          'estimated_minutes': draft.estimatedMinutes,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    final chapter = StudyChapter.fromJson(Map<String, dynamic>.from(row));
    chapters = List.unmodifiable([chapter, ...chapters]);
    notifyListeners();
    return chapter;
  }

  Future<void> updateChapter(String chapterId, StudyChapterDraft draft) async {
    final userId = _requireOwner();
    final index = chapters.indexWhere((chapter) => chapter.id == chapterId);
    if (index < 0) throw StateError('Chapter not found.');
    final previous = chapters[index];
    final row = await Supabase.instance.client
        .from('study_chapters')
        .update({
          'title': draft.title.trim(),
          'subject': draft.subject.trim(),
          'description': _cleanDescription(draft.description),
          'estimated_minutes': draft.estimatedMinutes,
        })
        .eq('id', chapterId)
        .eq('user_id', userId)
        .select()
        .single();
    _replaceChapter(
      index,
      StudyChapter.fromJson(
        Map<String, dynamic>.from(row),
        tasks: previous.tasks,
      ),
    );
  }

  Future<void> deleteChapter(String chapterId) async {
    final userId = _requireOwner();
    await Supabase.instance.client
        .from('study_chapters')
        .delete()
        .eq('id', chapterId)
        .eq('user_id', userId)
        .select('id')
        .single();
    chapters = List.unmodifiable(
      chapters.where((chapter) => chapter.id != chapterId),
    );
    notifyListeners();
  }

  Future<void> setChapterCompleted(
    String chapterId, {
    required bool completed,
  }) async {
    final userId = _requireOwner();
    final index = chapters.indexWhere((chapter) => chapter.id == chapterId);
    if (index < 0) throw StateError('Chapter not found.');
    final previous = chapters[index];
    if (previous.isCompleted == completed) return;

    final completedAt = completed ? DateTime.now().toUtc() : null;
    _replaceChapter(
      index,
      previous.copyWith(
        isCompleted: completed,
        completedAt: completedAt,
        clearCompletedAt: !completed,
      ),
    );

    try {
      await Supabase.instance.client
          .from('study_chapters')
          .update({
            'is_completed': completed,
            'completed_at': completedAt?.toIso8601String(),
          })
          .eq('id', chapterId)
          .eq('user_id', userId)
          .select('id')
          .single();
    } catch (_) {
      _replaceChapter(index, previous);
      rethrow;
    }
  }

  Future<void> reorderChapters(List<String> orderedIds) async {
    final userId = _requireOwner();
    if (orderedIds.length != chapters.length ||
        orderedIds.toSet().length != chapters.length ||
        !orderedIds.toSet().containsAll(
          chapters.map((chapter) => chapter.id),
        )) {
      throw ArgumentError('The chapter order must include every chapter once.');
    }

    final previous = chapters;
    final byId = {for (final chapter in chapters) chapter.id: chapter};
    chapters = List.unmodifiable([
      for (var index = 0; index < orderedIds.length; index++)
        byId[orderedIds[index]]!.copyWith(
          sortOrder: orderedIds.length - index - 1,
        ),
    ]);
    notifyListeners();

    try {
      await Supabase.instance.client.rpc(
        'reorder_study_chapters',
        params: {'p_chapter_ids': orderedIds.reversed.toList()},
      );
    } catch (_) {
      if (Supabase.instance.client.auth.currentUser?.id == userId) {
        chapters = previous;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<StudyChapterTask> createTask(
    String chapterId,
    StudyChapterTaskDraft draft,
  ) async {
    final userId = _requireOwner();
    final index = chapters.indexWhere((chapter) => chapter.id == chapterId);
    if (index < 0) throw StateError('Chapter not found.');
    final chapter = chapters[index];
    final sortOrder = chapter.tasks.isEmpty
        ? 0
        : chapter.tasks
                  .map((task) => task.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final row = await Supabase.instance.client
        .from('study_chapter_tasks')
        .insert({
          'user_id': userId,
          'chapter_id': chapterId,
          'title': draft.title.trim(),
          'estimated_minutes': draft.estimatedMinutes,
          'sort_order': sortOrder,
        })
        .select()
        .single();
    final task = StudyChapterTask.fromJson(Map<String, dynamic>.from(row));
    _replaceChapter(index, chapter.copyWith(tasks: [task, ...chapter.tasks]));
    return task;
  }

  Future<void> updateTask(String taskId, StudyChapterTaskDraft draft) async {
    final userId = _requireOwner();
    final chapterIndex = chapters.indexWhere(
      (chapter) => chapter.tasks.any((task) => task.id == taskId),
    );
    if (chapterIndex < 0) throw StateError('Task not found.');
    final chapter = chapters[chapterIndex];
    await Supabase.instance.client
        .from('study_chapter_tasks')
        .update({
          'title': draft.title.trim(),
          'estimated_minutes': draft.estimatedMinutes,
        })
        .eq('id', taskId)
        .eq('user_id', userId)
        .select('id')
        .single();
    _replaceChapter(
      chapterIndex,
      chapter.copyWith(
        tasks: chapter.tasks
            .map(
              (task) => task.id == taskId
                  ? StudyChapterTask(
                      id: task.id,
                      chapterId: task.chapterId,
                      title: draft.title.trim(),
                      estimatedMinutes: draft.estimatedMinutes,
                      sortOrder: task.sortOrder,
                      isCompleted: task.isCompleted,
                    )
                  : task,
            )
            .toList(),
      ),
    );
  }

  Future<void> setTaskCompleted(
    String taskId, {
    required bool completed,
  }) async {
    final userId = _requireOwner();
    final chapterIndex = chapters.indexWhere(
      (chapter) => chapter.tasks.any((task) => task.id == taskId),
    );
    if (chapterIndex < 0) throw StateError('Task not found.');
    final chapter = chapters[chapterIndex];
    final taskIndex = chapter.tasks.indexWhere((task) => task.id == taskId);
    final previous = chapter.tasks[taskIndex];
    if (previous.isCompleted == completed) return;
    final updated = _copyTask(previous, isCompleted: completed);
    _replaceTask(chapterIndex, taskIndex, updated);

    try {
      await Supabase.instance.client
          .from('study_chapter_tasks')
          .update({
            'is_completed': completed,
            'completed_at': completed
                ? DateTime.now().toUtc().toIso8601String()
                : null,
          })
          .eq('id', taskId)
          .eq('user_id', userId)
          .select('id')
          .single();
    } catch (_) {
      _replaceTask(chapterIndex, taskIndex, previous);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    final userId = _requireOwner();
    final chapterIndex = chapters.indexWhere(
      (chapter) => chapter.tasks.any((task) => task.id == taskId),
    );
    if (chapterIndex < 0) return;
    final chapter = chapters[chapterIndex];
    await Supabase.instance.client
        .from('study_chapter_tasks')
        .delete()
        .eq('id', taskId)
        .eq('user_id', userId)
        .select('id')
        .single();
    _replaceChapter(
      chapterIndex,
      chapter.copyWith(
        tasks: chapter.tasks.where((task) => task.id != taskId).toList(),
      ),
    );
  }

  void _replaceChapter(int index, StudyChapter chapter) {
    final updated = [...chapters];
    updated[index] = chapter;
    chapters = List.unmodifiable(updated);
    notifyListeners();
  }

  void _replaceTask(int chapterIndex, int taskIndex, StudyChapterTask task) {
    final chapter = chapters[chapterIndex];
    final tasks = [...chapter.tasks];
    tasks[taskIndex] = task;
    _replaceChapter(chapterIndex, chapter.copyWith(tasks: tasks));
  }

  StudyChapterTask _copyTask(
    StudyChapterTask task, {
    required bool isCompleted,
  }) => StudyChapterTask(
    id: task.id,
    chapterId: task.chapterId,
    title: task.title,
    estimatedMinutes: task.estimatedMinutes,
    sortOrder: task.sortOrder,
    isCompleted: isCompleted,
  );

  void clearForSignedOut() {
    _loadGeneration++;
    _ownerId = null;
    _loadFuture = null;
    chapters = const [];
    isLoading = false;
    isReady = false;
    error = null;
    notifyListeners();
  }

  static String? _cleanDescription(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
