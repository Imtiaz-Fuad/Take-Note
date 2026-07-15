class Note {
  final String? id;
  final String title;
  final String content;

  Note({this.id, required this.title, required this.content});

  Map<String, dynamic> toMap() {
    return {'title': title, 'content': content};
  }

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id : id,
      title: map['title'] as String,
      content: map['content'] as String,
    );
  }
}
