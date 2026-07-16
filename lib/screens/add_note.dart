import 'package:flutter/material.dart';
import 'package:take_note/models/note.dart';
import 'package:provider/provider.dart';
import 'package:take_note/providers/NoteNotifier.dart';

class AddNote extends StatefulWidget {
  final Note? note;
  const AddNote({super.key, required this.note});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
  
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) return; 

    final notifier = context.read<NoteNotifier>();

    if (widget.note == null) {
      await notifier.addNote(title, content);
    } else {

      final updatedNote = Note(
        id: widget.note!.id,
        title: title,
        content: content,
      );
      await notifier.updateNote(updatedNote);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'New Note')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Write your note...',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveNote,
                child: Text(isEditing ? 'Update Note' : 'Save Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
