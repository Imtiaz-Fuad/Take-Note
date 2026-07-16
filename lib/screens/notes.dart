import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:take_note/providers/NoteNotifier.dart';
import 'package:take_note/screens/add_note.dart';
import 'package:take_note/models/note.dart';

class Notes extends StatelessWidget {
  const Notes({super.key});
  
  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteNotifier>().notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
       body: SafeArea(
        child: notes.isEmpty
            ? const Center(
                child: Text("Your notes will appear here"),
              )
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final Note note = notes[index];
                  return ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                      note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNote(note: note),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        context.read<NoteNotifier>().deleteNote(note.id!);
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNote(note: Note(title: '', content: '')),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}