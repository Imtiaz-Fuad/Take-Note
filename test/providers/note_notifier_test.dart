import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:take_note/providers/NoteNotifier.dart';
import 'package:take_note/models/note.dart';
import 'package:take_note/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class FakeNote extends Fake implements Note {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNote());
  });

  group('NoteNotifier Tests', () {
    late NoteNotifier noteNotifier;
    late MockFirestoreService mockFirestoreService;

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      when(() => mockFirestoreService.getNotesStream())
          .thenAnswer((_) => const Stream<List<Note>>.empty());
      noteNotifier = NoteNotifier(firestoreService: mockFirestoreService);
    });

    test('initial notes list should be empty', () {
      expect(noteNotifier.notes, isEmpty);
    });

    test('addNote should call firestore service add method', () async {
      when(() => mockFirestoreService.add(any())).thenAnswer((_) async {});

      await noteNotifier.addNote('Test Note', 'Test Content');

      verify(() => mockFirestoreService.add(any())).called(1);
    });

    test('updateNote should call firestore service update method', () async {
      final note = Note(id: '1', title: 'Updated', content: 'Updated Content');
      when(() => mockFirestoreService.update(any())).thenAnswer((_) async {});

      await noteNotifier.updateNote(note);

      verify(() => mockFirestoreService.update(any())).called(1);
    });

    test('deleteNote should call firestore service delete method', () async {
      when(() => mockFirestoreService.delete(any())).thenAnswer((_) async {});

      await noteNotifier.deleteNote('1');

      verify(() => mockFirestoreService.delete(any())).called(1);
    });

    test('notifyListeners fires when notes stream emits', () async {
      final controller = StreamController<List<Note>>();
      when(() => mockFirestoreService.getNotesStream())
          .thenAnswer((_) => controller.stream);
      final notifier = NoteNotifier(firestoreService: mockFirestoreService);

      var notified = false;
      notifier.addListener(() => notified = true);

      controller.add([Note(id: '1', title: 'a', content: 'b')]);
      await Future.delayed(Duration.zero);

      expect(notified, isTrue);
      expect(notifier.notes.length, 1);

      await controller.close();
    });
  });
}