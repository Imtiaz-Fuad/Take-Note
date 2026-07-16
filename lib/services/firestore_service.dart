import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:take_note/models/note.dart';

class FirestoreService {
  final CollectionReference<Map<String, dynamic>> notesCollection = FirebaseFirestore.instance.collection('notes');
  Stream<List<Note>>getNotesStream(){
    return notesCollection
      .snapshots()
        .map((snapshot) =>
         snapshot.docs.map((doc) => 
         Note.fromMap(doc.id, doc.data())).toList());
  }

  Future<void>add(Note note) async {
    await notesCollection.add(note.toMap());
  }
  Future<void>update(Note note) async {
    await notesCollection.doc(note.id!).update(note.toMap());
  }
  Future<void>delete(String id) async {
    await notesCollection.doc(id).delete();
  }
}