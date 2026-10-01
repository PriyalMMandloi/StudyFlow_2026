// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studyflow_flutter/main.dart';
import 'package:studyflow_flutter/study_note.dart';
import 'package:studyflow_flutter/study_plan.dart';

void _noop(int _) {}

void main() {
  test('completing and undoing a task reverses study totals', () async {
    final data = StudyFlowData.instance;
    final startingMinutes = data.completedMinutes;
    final startingTasks = data.completedTasks;
    final weekday = DateTime.now().weekday - 1;
    final startingWeekdayMinutes = data.weeklyMinutes[weekday];
    final hadActivityToday = data.hasActivityOn(DateTime.now());

    await data.recordTask(completed: true, minutes: 30);

    expect(data.completedMinutes, startingMinutes + 30);
    expect(data.completedTasks, startingTasks + 1);
    expect(data.weeklyMinutes[weekday], startingWeekdayMinutes + 30);
    expect(data.hasActivityOn(DateTime.now()), isTrue);

    await data.recordTask(completed: false, minutes: 30);

    expect(data.completedMinutes, startingMinutes);
    expect(data.completedTasks, startingTasks);
    expect(data.weeklyMinutes[weekday], startingWeekdayMinutes);
    expect(data.hasActivityOn(DateTime.now()), hadActivityToday);
  });

  testWidgets('progress ring shows the supplied study progress', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProgressRing(value: 0.5, label: 'Today')),
    );

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  test(
    'email, password, and username validation helpers reject invalid values',
    () {
      expect(validateEmail('user@example.com'), isNull);
      expect(validateEmail('bad-email'), isNotNull);
      expect(validatePassword('StrongPass1!'), isNull);
      expect(validatePassword('short'), isNotNull);
      expect(validatePassword('password'), isNotNull);
      expect(validateUsername('studyflow_user'), isNull);
      expect(validateUsername('  '), isNotNull);
      expect(validateUsername('ab'), isNotNull);
    },
  );

  test('chapter and topic models restore database completion fields', () {
    final chapter = StudyChapter.fromJson({
      'id': 'chapter-1',
      'user_id': 'user-1',
      'title': 'Algebra',
      'subject': 'Math',
      'description': 'Linear equations',
      'estimated_minutes': 45,
      'sort_order': 0,
      'is_completed': true,
      'completed_at': '2026-09-27T10:00:00Z',
    });
    final task = StudyChapterTask.fromJson({
      'id': 'task-1',
      'chapter_id': 'chapter-1',
      'title': 'Review examples',
      'estimated_minutes': 10,
      'sort_order': 0,
      'is_completed': true,
    });

    expect(chapter.isCompleted, isTrue);
    expect(chapter.estimatedMinutes, 45);
    expect(task.isCompleted, isTrue);
    expect(task.estimatedMinutes, 10);
  });

  test('study note model restores owner, optional subject, and content', () {
    final note = StudyNote.fromJson({
      'id': 'note-1',
      'user_id': 'user-1',
      'title': 'Functions',
      'subject': null,
      'content': 'Review function declarations.',
      'created_at': '2026-09-27T10:00:00Z',
      'updated_at': '2026-09-27T10:00:00Z',
    });

    expect(note.userId, 'user-1');
    expect(note.title, 'Functions');
    expect(note.subject, isNull);
    expect(note.content, 'Review function declarations.');
  });

  test('study note search matches title, subject, and content', () {
    final notes = [
      StudyNote(
        id: 'note-1',
        userId: 'user-1',
        title: 'Functions',
        subject: 'Programming',
        content: 'Review declarations.',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      StudyNote(
        id: 'note-2',
        userId: 'user-1',
        title: 'Biology',
        subject: null,
        content: 'Cell structure',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ];

    expect(filterStudyNotes(notes, 'programming').single.id, 'note-1');
    expect(filterStudyNotes(notes, 'CELL').single.id, 'note-2');
    expect(filterStudyNotes(notes, 'missing'), isEmpty);
  });

  testWidgets('notes empty state offers create note action', (
    WidgetTester tester,
  ) async {
    var createTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudyNotesEmptyState(onCreate: () => createTapped = true),
        ),
      ),
    );

    expect(find.text('No notes yet'), findsOneWidget);
    expect(
      find.text('Create your first note to keep your learning organized.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create Note'));
    expect(createTapped, isTrue);
  });

  testWidgets('new study plan presents the first-chapter empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: StudyPlanEmptyState(onCreate: () {})),
    );

    expect(find.text("Let's create your study plan."), findsOneWidget);
    expect(find.text('Create Your First Chapter'), findsOneWidget);
  });

  testWidgets('dashboard renders a greeting without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StudyFlowTheme.lightTheme,
        home: const Scaffold(body: DashboardScreen()),
      ),
    );

    expect(find.textContaining(', StudyFlow'), findsOneWidget);
    final cardFinder = find.byKey(const ValueKey('home-motivation-card'));
    await tester.scrollUntilVisible(cardFinder, 300);
    final quoteFinder = find.byKey(const ValueKey('home-motivation-quote'));
    final firstQuote = tester.widget<Text>(quoteFinder).data;

    await tester.tap(cardFinder);
    await tester.pump();

    expect(tester.widget<Text>(quoteFinder).data, isNot(firstQuote));
    expect(tester.takeException(), isNull);
  });

  testWidgets('motivation screen starts with a quote and offers a new one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: const MotivationScreen()));

    final quoteFinder = find.textContaining('“');
    final firstQuote = tester.widget<Text>(quoteFinder).data;
    expect(firstQuote, isNotNull);

    await tester.tap(find.text('New Quote'));
    await tester.pump();

    expect(tester.widget<Text>(quoteFinder).data, isNot(firstQuote));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'main navigation exposes home, chapters, tasks, and profile destinations',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const StudyFlowNavBar(
            selectedIndex: 0,
            onDestinationSelected: _noop,
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Chapters'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Plan'), findsNothing);
      expect(find.text('Notes'), findsNothing);
      expect(find.text('More'), findsNothing);
    },
  );

  testWidgets('chapter editor remains stable while typing with keyboard open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StudyFlowTheme.lightTheme,
        home: const Scaffold(body: PlannerScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Create chapter'));
    await tester.pumpAndSettle();

    expect(find.text('Chapter title'), findsOneWidget);
    final descriptionFinder = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Description (optional)',
    );
    final initialDescriptionSize = tester.getSize(descriptionFinder);
    await tester.enterText(
      descriptionFinder,
      List.filled(12, 'A detailed line of chapter information').join('\n'),
    );
    final fullDescription = tester
        .widget<TextField>(descriptionFinder)
        .controller!
        .text;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    expect(
      tester.getSize(descriptionFinder).width,
      initialDescriptionSize.width,
    );
    expect(tester.widget<TextField>(descriptionFinder).maxLength, isNull);
    expect(
      fullDescription,
      List.filled(12, 'A detailed line of chapter information').join('\n'),
    );
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
  });
}
