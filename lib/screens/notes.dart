import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:take_note/providers/NoteNotifier.dart';
import 'package:take_note/screens/add_note.dart';
import 'package:take_note/models/note.dart';
import 'package:take_note/screens/subscription_screen.dart';

class Notes extends StatelessWidget {
  const Notes({super.key});
  
  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteNotifier>().notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
         actions: [
    IconButton(
      icon: const Icon(Icons.subscriptions_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        );
      },
    ),
  ],
      ),
       body: SafeArea(
        child: notes.isEmpty
            ?  Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.spa_outlined, size: 48, color: Colors.brown.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      "Your notes will appear here",
                      style: TextStyle(color: Colors.brown.withOpacity(0.5), fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final Note note = notes[index];
                   return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.brown.withOpacity(0.4),
                        onPressed: () {
                          context.read<NoteNotifier>().deleteNote(note.id!);
                        },
                      ),
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
              builder: (context) => AddNote(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}