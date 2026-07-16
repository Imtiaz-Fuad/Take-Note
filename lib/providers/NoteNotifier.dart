import 'package:flutter/material.dart';
import 'package:take_note/services/firestore_service.dart';
import 'package:take_note/models/note.dart';

class NoteNotifier extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Note> notes = [];
  NoteNotifier() {
    _firestoreService.getNotesStream().listen((updatedNotes) {
      notes = updatedNotes;
      notifyListeners();
    },
     onError: (error) {
      debugPrint('Firestore stream error: $error');
      // could also set an error flag and notifyListeners() to show a message in the UI
    },
    );
  }

  Future<void> addNote(String title, String content) async{
    await _firestoreService.add(Note(title: title, content: content));
  }

  Future<void> updateNote(Note note) async {
    await _firestoreService.update(note);
  }

  Future<void> deleteNote(String id) async {
    await _firestoreService.delete(id);
  }
}

